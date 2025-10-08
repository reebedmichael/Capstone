# Like Button Fix Summary

## Problem
The like button on `bestelling_kos_items` in the orders page was incorrectly treating likes as feedback options and adding records to the `terugvoer` table instead of simply incrementing the `kos_item_likes` field in the `kos_item` table.

## Solution
1. **Created new database table**: `kos_item_likes` to track user likes through `bestelling_kos_item` relationship
2. **Added RPC function**: `update_kos_item_likes_count` to count likes through proper table relationships
3. **Updated TerugvoerRepository**: Added new methods that work with `bestelling_kos_item` context
4. **Updated ItemFeedbackWidget**: Modified to use the new methods with proper linking
5. **Removed old methods**: Cleaned up the old like methods that used the terugvoer system

## Files Modified

### Database
- `db/migrations/0007_add_kos_item_likes_table.sql` - New migration for kos_item_likes table and RPC functions

### Backend (spys_api_client)
- `packages/spys_api_client/lib/src/terugvoer_repository.dart` - Added new direct like methods and removed old ones

### Frontend (mobile app)
- `apps/mobile/lib/features/feedback/presentation/widgets/item_feedback_widget.dart` - Updated to use new like methods

## New Database Schema

### kos_item_likes table
```sql
CREATE TABLE public.kos_item_likes (
  like_id uuid NOT NULL DEFAULT gen_random_uuid(),
  best_kos_id uuid NOT NULL,
  like_datum timestamp without time zone DEFAULT now(),
  CONSTRAINT kos_item_likes_pkey PRIMARY KEY (like_id),
  CONSTRAINT kos_item_likes_best_kos_id_fkey FOREIGN KEY (best_kos_id) REFERENCES public.bestelling_kos_item(best_kos_id),
  CONSTRAINT kos_item_likes_unique_best_kos UNIQUE (best_kos_id)
);
```

### RPC Functions
- `update_kos_item_likes_count(item_id uuid)` - Counts likes through bestelling_kos_item relationship and updates kos_item_likes

## New API Methods

### TerugvoerRepository
- `hasUserLikedBestellingKosItem(String bestKosId)` - Check if user liked a bestelling_kos_item
- `likeBestellingKosItem(String bestKosId)` - Like a bestelling_kos_item
- `unlikeBestellingKosItem(String bestKosId)` - Unlike a bestelling_kos_item
- `getKosItemLikesDirect(String kosItemId)` - Get current like count

## How It Works Now

1. **Like Action**: When user clicks like button on a completed order item:
   - Creates a record in `kos_item_likes` table linked to `bestelling_kos_item`
   - Updates `kos_item_likes` count in `kos_item` table through proper relationship
   - No longer creates records in `bestelling_kos_item_terugvoer` table

2. **Unlike Action**: When user clicks unlike:
   - Removes record from `kos_item_likes` table
   - Updates `kos_item_likes` count in `kos_item` table through proper relationship

3. **Feedback System**: Remains separate and only handles actual feedback options, not likes

## Testing

1. Apply the database migration
2. Run the mobile app
3. Complete an order and go to the completed orders tab
4. Try liking/unliking items
5. Verify that:
   - `kos_item_likes` count increases/decreases in `kos_item` table
   - Records are created/removed in `kos_item_likes` table
   - No records are added to `bestelling_kos_item_terugvoer` for likes
   - Feedback system still works independently

## Benefits

- **Separation of Concerns**: Likes are now separate from feedback
- **Performance**: Direct table operations instead of complex joins
- **Data Integrity**: Atomic operations prevent race conditions
- **Clarity**: Clear distinction between likes and feedback

