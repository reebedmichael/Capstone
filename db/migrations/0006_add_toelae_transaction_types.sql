-- Migration: Add Allowance Transaction Types
-- Description: Adds transaction types for allowances using existing beursie_transaksie table
-- Note: Uses existing gebruiker_tipes.gebr_toelaag for group-based allowances

-- 1. Add transaction types for allowances
INSERT INTO transaksie_tipe (trans_tipe_id, trans_tipe_naam)
VALUES 
  ('a1e58a24-1a1d-4940-8855-df4c35ae5d5f', 'toelae_inbetaling'),
  ('a2e58a24-1a1d-4940-8855-df4c35ae5d5f', 'toelae_uitbetaling')
ON CONFLICT (trans_tipe_id) DO NOTHING;

-- 2. Create function to add allowance (admin only)
CREATE OR REPLACE FUNCTION add_toelae(
    p_gebr_id UUID,
    p_bedrag DECIMAL(10, 2),
    p_beskrywing TEXT DEFAULT 'Toelae bygevoeg deur admin'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_trans_tipe_id UUID := 'a1e58a24-1a1d-4940-8855-df4c35ae5d5f';
    v_current_user UUID;
    v_new_balance DECIMAL(10, 2);
    v_trans_id UUID;
BEGIN
    -- Get current user
    v_current_user := auth.uid();
    
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM gebruikers 
        WHERE gebr_id = v_current_user 
        AND admin_tipe_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Only admins can add allowances';
    END IF;
    
    -- Update user balance
    UPDATE gebruikers
    SET beursie_balans = COALESCE(beursie_balans, 0) + p_bedrag
    WHERE gebr_id = p_gebr_id
    RETURNING beursie_balans INTO v_new_balance;
    
    -- Insert transaction record
    INSERT INTO beursie_transaksie (
        gebr_id, 
        trans_bedrag, 
        trans_tipe_id, 
        trans_beskrywing
    )
    VALUES (
        p_gebr_id, 
        p_bedrag, 
        v_trans_tipe_id, 
        p_beskrywing
    )
    RETURNING trans_id INTO v_trans_id;
    
    RETURN json_build_object(
        'success', true,
        'new_balance', v_new_balance,
        'transaction_id', v_trans_id
    );
END;
$$;

-- 3. Create function to deduct allowance
CREATE OR REPLACE FUNCTION deduct_toelae(
    p_gebr_id UUID,
    p_bedrag DECIMAL(10, 2),
    p_beskrywing TEXT DEFAULT 'Toelae gebruik vir bestelling'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_trans_tipe_id UUID := 'a2e58a24-1a1d-4940-8855-df4c35ae5d5f';
    v_current_balance DECIMAL(10, 2);
    v_new_balance DECIMAL(10, 2);
    v_trans_id UUID;
BEGIN
    -- Get current balance
    SELECT COALESCE(beursie_balans, 0) INTO v_current_balance
    FROM gebruikers
    WHERE gebr_id = p_gebr_id;
    
    -- Check if sufficient balance
    IF v_current_balance < p_bedrag THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', 
            v_current_balance, p_bedrag;
    END IF;
    
    -- Update user balance
    UPDATE gebruikers
    SET beursie_balans = beursie_balans - p_bedrag
    WHERE gebr_id = p_gebr_id
    RETURNING beursie_balans INTO v_new_balance;
    
    -- Insert transaction record
    INSERT INTO beursie_transaksie (
        gebr_id, 
        trans_bedrag, 
        trans_tipe_id, 
        trans_beskrywing
    )
    VALUES (
        p_gebr_id, 
        p_bedrag, 
        v_trans_tipe_id, 
        p_beskrywing
    )
    RETURNING trans_id INTO v_trans_id;
    
    RETURN json_build_object(
        'success', true,
        'new_balance', v_new_balance,
        'transaction_id', v_trans_id,
        'amount_deducted', p_bedrag
    );
END;
$$;

-- 4. Create function to distribute monthly allowances
CREATE OR REPLACE FUNCTION distribute_monthly_toelae()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_trans_tipe_id UUID := 'a1e58a24-1a1d-4940-8855-df4c35ae5d5f';
    v_count INTEGER := 0;
    v_total_amount DECIMAL(10, 2) := 0;
    v_user RECORD;
BEGIN
    -- Loop through all active users with a gebruiker_tipe that has gebr_toelaag
    FOR v_user IN 
        SELECT g.gebr_id, g.gebr_naam, g.gebr_van, gt.gebr_toelaag, gt.gebr_tipe_naam
        FROM gebruikers g
        JOIN gebruiker_tipes gt ON g.gebr_tipe_id = gt.gebr_tipe_id
        WHERE g.is_aktief = TRUE
        AND gt.gebr_toelaag IS NOT NULL
        AND gt.gebr_toelaag > 0
    LOOP
        -- Update user balance
        UPDATE gebruikers
        SET beursie_balans = COALESCE(beursie_balans, 0) + v_user.gebr_toelaag
        WHERE gebr_id = v_user.gebr_id;
        
        -- Insert transaction record
        INSERT INTO beursie_transaksie (
            gebr_id, 
            trans_bedrag, 
            trans_tipe_id, 
            trans_beskrywing
        )
        VALUES (
            v_user.gebr_id, 
            v_user.gebr_toelaag, 
            v_trans_tipe_id, 
            format('Maandelikse toelae: %s (R%s)', v_user.gebr_tipe_naam, v_user.gebr_toelaag)
        );
        
        v_count := v_count + 1;
        v_total_amount := v_total_amount + v_user.gebr_toelaag;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'users_credited', v_count,
        'total_amount', v_total_amount
    );
END;
$$;

-- 5. Grant execute permissions
GRANT EXECUTE ON FUNCTION add_toelae TO authenticated;
GRANT EXECUTE ON FUNCTION deduct_toelae TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_monthly_toelae TO authenticated;

-- 6. Comments
COMMENT ON FUNCTION add_toelae IS 'Admin function to add allowance to a user account';
COMMENT ON FUNCTION deduct_toelae IS 'Function to deduct allowance from user account';
COMMENT ON FUNCTION distribute_monthly_toelae IS 'Distribute monthly allowances based on gebruiker_tipes.gebr_toelaag';

