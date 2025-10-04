import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class TerugvoerRepository {
  TerugvoerRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Fetch all available feedback options from the terugvoer table
  Future<List<Map<String, dynamic>>> getTerugvoerOptions() async {
    try {
      final rows = await _sb
          .from('terugvoer')
          .select('terug_id, terug_naam, terug_beskrywing')
          .order('terug_naam');
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('Error fetching terugvoer options: $e');
      return [];
    }
  }

  /// Increment kos_item.kos_item_likes for the kos_item linked to this bestelling_kos_item
  Future<bool> incrementKosItemLikesForBestelling(String bestKosId) async {
    try {
      // Find kos_item_id from the bestelling_kos_item row
      final bestKosItem = await _sb
          .from('bestelling_kos_item')
          .select('kos_item_id')
          .eq('best_kos_id', bestKosId)
          .maybeSingle();

      if (bestKosItem == null || bestKosItem['kos_item_id'] == null) {
        return false;
      }

      final String kosItemId = bestKosItem['kos_item_id'] as String;

      // Read current likes
      final currentRow = await _sb
          .from('kos_item')
          .select('kos_item_likes')
          .eq('kos_item_id', kosItemId)
          .single();

      final int currentLikes = (currentRow['kos_item_likes'] as int?) ?? 0;

      // Update to current + 1
      await _sb
          .from('kos_item')
          .update({'kos_item_likes': currentLikes + 1})
          .eq('kos_item_id', kosItemId);

      return true;
    } catch (e) {
      print('Error incrementing kos_item_likes: $e');
      return false;
    }
  }

  /// Get existing feedback for a specific bestelling_kos_item
  Future<List<Map<String, dynamic>>> getFeedbackForItem(String bestKosId) async {
    try {
      final rows = await _sb
          .from('bestelling_kos_item_terugvoer')
          .select('''
            best_terug_id,
            geskep_datum,
            terugvoer:terug_id(terug_id, terug_naam, terug_beskrywing)
          ''')
          .eq('best_kos_id', bestKosId)
          .order('geskep_datum', ascending: false);
      
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('Error fetching feedback for item: $e');
      return [];
    }
  }

  /// Save feedback for a bestelling_kos_item
  Future<bool> saveFeedbackForItem(String bestKosId, List<String> terugvoerIds) async {
    try {
      // First, delete existing feedback for this item
      await _sb
          .from('bestelling_kos_item_terugvoer')
          .delete()
          .eq('best_kos_id', bestKosId);

      // Then insert new feedback entries
      if (terugvoerIds.isNotEmpty) {
        final insertData = terugvoerIds.map((terugId) => {
          'best_kos_id': bestKosId,
          'terug_id': terugId,
          'geskep_datum': DateTime.now().toIso8601String(),
        }).toList();

        await _sb
            .from('bestelling_kos_item_terugvoer')
            .insert(insertData);
      }

      return true;
    } catch (e) {
      print('Error saving feedback for item: $e');
      return false;
    }
  }

  /// Update feedback for a bestelling_kos_item (replace existing)
  Future<bool> updateFeedbackForItem(String bestKosId, List<String> terugvoerIds) async {
    return await saveFeedbackForItem(bestKosId, terugvoerIds);
  }

  /// Delete all feedback for a bestelling_kos_item
  Future<bool> deleteFeedbackForItem(String bestKosId) async {
    try {
      await _sb
          .from('bestelling_kos_item_terugvoer')
          .delete()
          .eq('best_kos_id', bestKosId);
      
      return true;
    } catch (e) {
      print('Error deleting feedback for item: $e');
      return false;
    }
  }


  // ===== NEW LIKE METHODS - Direct kos_item table operations =====

  /// Check if a user has liked a specific bestelling_kos_item
  Future<bool> hasUserLikedBestellingKosItem(String bestKosId) async {
    try {
      // Check if there's a like record for this bestelling_kos_item
      final likeRecords = await _sb
          .from('kos_item_likes')
          .select('like_id')
          .eq('best_kos_id', bestKosId)
          .limit(1);

      return likeRecords.isNotEmpty;
    } catch (e) {
      // If the likes table hasn't been created yet, fail gracefully
      final String msg = e.toString();
      if (msg.contains('42P01') || msg.contains('does not exist')) {
        return false;
      }
      print('Error checking if user liked bestelling kos item: $e');
      return false;
    }
  }

  /// Like a bestelling_kos_item (increment kos_item_likes and create like record)
  Future<bool> likeBestellingKosItem(String bestKosId) async {
    try {
      // Check if already liked
      final alreadyLiked = await hasUserLikedBestellingKosItem(bestKosId);
      if (alreadyLiked) {
        return true; // Already liked, no action needed
      }

      // Get the kos_item_id from bestelling_kos_item
      final bestKosItem = await _sb
          .from('bestelling_kos_item')
          .select('kos_item_id')
          .eq('best_kos_id', bestKosId)
          .single();

      final kosItemId = bestKosItem['kos_item_id'] as String;

      // Create like record
      await _sb.from('kos_item_likes').insert({
        'best_kos_id': bestKosId,
        'like_datum': DateTime.now().toIso8601String(),
      });

      // Update the kos_item_likes count
      await _updateKosItemLikesCount(kosItemId);

      return true;
    } catch (e) {
      // If the likes table hasn't been created yet, fail gracefully
      final String msg = e.toString();
      if (msg.contains('42P01') || msg.contains('does not exist')) {
        return false;
      }
      print('Error liking bestelling kos item: $e');
      return false;
    }
  }

  /// Unlike a bestelling_kos_item (decrement kos_item_likes and remove like record)
  Future<bool> unlikeBestellingKosItem(String bestKosId) async {
    try {
      // Check if liked
      final isLiked = await hasUserLikedBestellingKosItem(bestKosId);
      if (!isLiked) {
        return true; // Not liked, no action needed
      }

      // Get the kos_item_id from bestelling_kos_item before deleting
      final bestKosItem = await _sb
          .from('bestelling_kos_item')
          .select('kos_item_id')
          .eq('best_kos_id', bestKosId)
          .single();

      final kosItemId = bestKosItem['kos_item_id'] as String;

      // Remove like record
      await _sb
          .from('kos_item_likes')
          .delete()
          .eq('best_kos_id', bestKosId);

      // Update the kos_item_likes count
      await _updateKosItemLikesCount(kosItemId);

      return true;
    } catch (e) {
      // If the likes table hasn't been created yet, fail gracefully
      final String msg = e.toString();
      if (msg.contains('42P01') || msg.contains('does not exist')) {
        return false;
      }
      print('Error unliking bestelling kos item: $e');
      return false;
    }
  }

  /// Get the current like count for a kos_item
  Future<int> getKosItemLikesDirect(String kosItemId) async {
    try {
      final result = await _sb
          .from('kos_item')
          .select('kos_item_likes')
          .eq('kos_item_id', kosItemId)
          .single();

      return (result['kos_item_likes'] as int?) ?? 0;
    } catch (e) {
      print('Error getting kos item likes directly: $e');
      return 0;
    }
  }

  /// Update kos_item_likes count based on actual likes in kos_item_likes table
  Future<void> _updateKosItemLikesCount(String kosItemId) async {
    try {
      await _sb.rpc('update_kos_item_likes_count', params: {
        'item_id': kosItemId,
      });
    } catch (e) {
      print('Error updating kos item likes count: $e');
      // Fallback: manually count likes
      final likeCount = await _countLikesForKosItem(kosItemId);
      await _sb
          .from('kos_item')
          .update({'kos_item_likes': likeCount})
          .eq('kos_item_id', kosItemId);
    }
  }

  /// Count likes for a specific kos_item through bestelling_kos_item
  Future<int> _countLikesForKosItem(String kosItemId) async {
    try {
      // Use a raw query to count likes through the join
      final result = await _sb
          .from('kos_item_likes')
          .select('''
            like_id,
            bestelling_kos_item!inner(kos_item_id)
          ''')
          .eq('bestelling_kos_item.kos_item_id', kosItemId);

      return result.length;
    } catch (e) {
      print('Error counting likes for kos item: $e');
      return 0;
    }
  }
}
