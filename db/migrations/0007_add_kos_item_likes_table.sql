-- Create table to track user likes for kos items through bestelling_kos_item
CREATE TABLE public.kos_item_likes (
  like_id uuid NOT NULL DEFAULT gen_random_uuid(),
  best_kos_id uuid NOT NULL,
  like_datum timestamp without time zone DEFAULT now(),
  CONSTRAINT kos_item_likes_pkey PRIMARY KEY (like_id),
  CONSTRAINT kos_item_likes_best_kos_id_fkey FOREIGN KEY (best_kos_id) REFERENCES public.bestelling_kos_item(best_kos_id),
  CONSTRAINT kos_item_likes_unique_best_kos UNIQUE (best_kos_id)
);

-- Create indexes for better performance
CREATE INDEX idx_kos_item_likes_best_kos_id ON public.kos_item_likes(best_kos_id);

-- Create RPC functions for updating likes count based on kos_item_likes table
CREATE OR REPLACE FUNCTION update_kos_item_likes_count(item_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.kos_item 
  SET kos_item_likes = (
    SELECT COUNT(*)
    FROM public.kos_item_likes kil
    JOIN public.bestelling_kos_item bki ON kil.best_kos_id = bki.best_kos_id
    WHERE bki.kos_item_id = item_id
  )
  WHERE kos_item_id = item_id;
END;
$$ LANGUAGE plpgsql;

