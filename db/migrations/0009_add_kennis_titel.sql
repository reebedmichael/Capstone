-- Add titel field to kennisgewings tables
ALTER TABLE public.kennisgewings 
ADD COLUMN IF NOT EXISTS kennis_titel text DEFAULT ''::text;

ALTER TABLE public.globale_kennisgewings 
ADD COLUMN IF NOT EXISTS glob_kennis_titel text DEFAULT ''::text;

-- Add comment
COMMENT ON COLUMN public.kennisgewings.kennis_titel IS 'Title/header for notification';
COMMENT ON COLUMN public.globale_kennisgewings.glob_kennis_titel IS 'Title/header for global notification';

