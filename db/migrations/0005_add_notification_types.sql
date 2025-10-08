-- =======================================
-- ADD NOTIFICATION TYPES
-- =======================================

-- Insert notification types if they don't exist
INSERT INTO public.KENNISGEWING_TIPES (KENNIS_TIPE_NAAM) 
VALUES 
  ('info'), 
  ('waarskuwing'), 
  ('sukses'), 
  ('fout'), 
  ('kritiek'),
  ('bestelling'),
  ('spyskaart'),
  ('toelaag'),
  ('algemeen')
ON CONFLICT (KENNIS_TIPE_NAAM) DO NOTHING;

-- =======================================
-- UPDATE RLS POLICIES FOR NOTIFICATIONS
-- =======================================

-- Allow users to read their own notifications
CREATE POLICY IF NOT EXISTS p_kennisgewings_select_self ON public.KENNISGEWINGS
  FOR SELECT USING (GEBR_ID = auth.uid());

-- Allow users to update their own notifications (mark as read)
CREATE POLICY IF NOT EXISTS p_kennisgewings_update_self ON public.KENNISGEWINGS
  FOR UPDATE USING (GEBR_ID = auth.uid());

-- Allow admins to insert notifications for any user
CREATE POLICY IF NOT EXISTS p_kennisgewings_insert_admin ON public.KENNISGEWINGS
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );

-- Allow admins to read all notifications
CREATE POLICY IF NOT EXISTS p_kennisgewings_select_admin ON public.KENNISGEWINGS
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );

-- Allow admins to delete notifications
CREATE POLICY IF NOT EXISTS p_kennisgewings_delete_admin ON public.KENNISGEWINGS
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );

-- =======================================
-- GLOBAL NOTIFICATIONS POLICIES
-- =======================================

-- Allow everyone to read global notifications
CREATE POLICY IF NOT EXISTS p_globale_kennisgewings_select ON public.GLOBALE_KENNISGEWINGS
  FOR SELECT USING (true);

-- Allow admins to insert global notifications
CREATE POLICY IF NOT EXISTS p_globale_kennisgewings_insert ON public.GLOBALE_KENNISGEWINGS
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );

-- Allow admins to update global notifications
CREATE POLICY IF NOT EXISTS p_globale_kennisgewings_update ON public.GLOBALE_KENNISGEWINGS
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );

-- Allow admins to delete global notifications
CREATE POLICY IF NOT EXISTS p_globale_kennisgewings_delete ON public.GLOBALE_KENNISGEWINGS
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.GEBRUIKERS 
      WHERE GEBR_ID = auth.uid() 
      AND ADMIN_TIPE_ID IS NOT NULL
    )
  );
