-- =======================================
-- ADD TRANSACTION TYPES
-- =======================================

-- Insert transaction types if they don't exist
INSERT INTO public.TRANSAKSIE_TIPE (TRANS_TIPE_NAAM) 
VALUES ('inbetaling'), ('uitbetaling') 
ON CONFLICT (TRANS_TIPE_NAAM) DO NOTHING;

-- =======================================
-- UPDATE RLS POLICIES FOR BEURSIE_TRANSAKSIE
-- =======================================

-- Allow users to insert their own transactions (for top-ups)
CREATE POLICY IF NOT EXISTS p_trans_insert_self ON public.BEURSIE_TRANSAKSIE
  FOR INSERT WITH CHECK (GEBR_ID = auth.uid());

-- Allow users to update their own transactions (if needed)
CREATE POLICY IF NOT EXISTS p_trans_update_self ON public.BEURSIE_TRANSAKSIE
  FOR UPDATE USING (GEBR_ID = auth.uid());
