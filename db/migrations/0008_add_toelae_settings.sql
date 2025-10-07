-- Migration: Add System Settings for Allowance Distribution
-- Description: Adds system settings table to store configurable allowance distribution day

-- 1. Create system settings table
CREATE TABLE IF NOT EXISTS public.stelsel_instellings (
  instelling_id UUID NOT NULL DEFAULT gen_random_uuid(),
  instelling_sleutel TEXT NOT NULL UNIQUE,
  instelling_waarde TEXT NOT NULL,
  instelling_beskrywing TEXT DEFAULT ''::text,
  instelling_geskep_datum TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  instelling_wysig_datum TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  CONSTRAINT stelsel_instellings_pkey PRIMARY KEY (instelling_id)
);

-- 2. Insert default setting for allowance distribution day (1st of month)
INSERT INTO stelsel_instellings (instelling_sleutel, instelling_waarde, instelling_beskrywing)
VALUES (
  'toelae_verspreiding_dag',
  '1',
  'Dag van die maand waarop maandelikse toelae versprei word (1-28)'
)
ON CONFLICT (instelling_sleutel) DO NOTHING;

-- 3. Create function to get setting value
CREATE OR REPLACE FUNCTION get_instelling(p_sleutel TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_waarde TEXT;
BEGIN
    SELECT instelling_waarde INTO v_waarde
    FROM stelsel_instellings
    WHERE instelling_sleutel = p_sleutel;
    
    RETURN v_waarde;
END;
$$;

-- 4. Create function to update setting (admin only)
CREATE OR REPLACE FUNCTION update_instelling(
    p_sleutel TEXT,
    p_waarde TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_user UUID;
BEGIN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM gebruikers 
        WHERE gebr_id = v_current_user 
        AND admin_tipe_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Only admins can update system settings';
    END IF;
    
    -- Update setting
    UPDATE stelsel_instellings
    SET instelling_waarde = p_waarde,
        instelling_wysig_datum = now()
    WHERE instelling_sleutel = p_sleutel;
    
    -- If setting doesn't exist, insert it
    IF NOT FOUND THEN
        INSERT INTO stelsel_instellings (instelling_sleutel, instelling_waarde)
        VALUES (p_sleutel, p_waarde);
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'sleutel', p_sleutel,
        'waarde', p_waarde
    );
END;
$$;

-- 5. Create function to update cron schedule for allowance distribution
CREATE OR REPLACE FUNCTION update_toelae_cron_schedule(p_dag INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_user UUID;
    v_cron_schedule TEXT;
    v_job_exists BOOLEAN;
BEGIN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM gebruikers 
        WHERE gebr_id = v_current_user 
        AND admin_tipe_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Only admins can update cron schedules';
    END IF;
    
    -- Validate day (1-28 to avoid month-end issues)
    IF p_dag < 1 OR p_dag > 28 THEN
        RAISE EXCEPTION 'Day must be between 1 and 28';
    END IF;
    
    -- Build cron schedule: '0 0 <day> * *' (midnight on specified day of month)
    v_cron_schedule := format('0 0 %s * *', p_dag);
    
    -- Check if job exists
    SELECT EXISTS(
        SELECT 1 FROM cron.job 
        WHERE jobname = 'distribute-monthly-allowances'
    ) INTO v_job_exists;
    
    -- Unschedule existing job if it exists
    IF v_job_exists THEN
        PERFORM cron.unschedule('distribute-monthly-allowances');
    END IF;
    
    -- Schedule new job
    PERFORM cron.schedule(
        'distribute-monthly-allowances',
        v_cron_schedule,
        $$SELECT distribute_monthly_toelae()$$
    );
    
    -- Update setting in database
    UPDATE stelsel_instellings
    SET instelling_waarde = p_dag::TEXT,
        instelling_wysig_datum = now()
    WHERE instelling_sleutel = 'toelae_verspreiding_dag';
    
    RETURN json_build_object(
        'success', true,
        'dag', p_dag,
        'cron_schedule', v_cron_schedule,
        'message', format('Toelae sal nou versprei word op dag %s van elke maand', p_dag)
    );
END;
$$;

-- 6. Grant permissions
GRANT SELECT ON stelsel_instellings TO authenticated;
GRANT EXECUTE ON FUNCTION get_instelling TO authenticated;
GRANT EXECUTE ON FUNCTION update_instelling TO authenticated;
GRANT EXECUTE ON FUNCTION update_toelae_cron_schedule TO authenticated;

-- 7. Enable RLS
ALTER TABLE stelsel_instellings ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS policies
-- Everyone can read settings
CREATE POLICY "Allow read access to all authenticated users" 
ON stelsel_instellings FOR SELECT 
TO authenticated 
USING (true);

-- Only admins can update settings
CREATE POLICY "Allow update access to admins only" 
ON stelsel_instellings FOR UPDATE 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM gebruikers 
        WHERE gebr_id = auth.uid() 
        AND admin_tipe_id IS NOT NULL
    )
);

-- 9. Comments
COMMENT ON TABLE stelsel_instellings IS 'System-wide settings and configuration';
COMMENT ON FUNCTION get_instelling IS 'Get a system setting value by key';
COMMENT ON FUNCTION update_instelling IS 'Admin function to update a system setting';
COMMENT ON FUNCTION update_toelae_cron_schedule IS 'Admin function to update the monthly allowance distribution schedule';

