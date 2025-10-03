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

  /// Check if a user has liked a specific bestelling_kos_item
  Future<bool> hasUserLikedItem(String userId, String bestKosId) async {
    try {
      // Get the special like entry in terugvoer table (use limit(1) to handle multiple entries)
      final likeEntries = await _sb
          .from('terugvoer')
          .select('terug_id')
          .eq('terug_naam', '_LIKE_')
          .limit(1);

      if (likeEntries.isEmpty) {
        return false; // No like system set up yet
      }

      final likeEntry = likeEntries.first;

      // Check if this specific bestelling_kos_item has been liked by checking
      // if there's an entry in bestelling_kos_item_terugvoer with the like terug_id
      final likeRecords = await _sb
          .from('bestelling_kos_item_terugvoer')
          .select('best_terug_id')
          .eq('best_kos_id', bestKosId)
          .eq('terug_id', likeEntry['terug_id'])
          .limit(1);

      return likeRecords.isNotEmpty;
    } catch (e) {
      print('Error checking if user liked item: $e');
      return false;
    }
  }

  /// Like a kos_item (track user like through linking table)
  Future<bool> likeKosItem(String userId, String kosItemId, String bestKosId) async {
    try {
      // First check if this bestelling_kos_item is already liked
      final alreadyLiked = await hasUserLikedItem(userId, bestKosId);
      if (alreadyLiked) {
        return true; // Already liked, no action needed
      }

      // Get or create the special like entry in terugvoer table
      String likeEntryId;
      
      // First try to get existing like entry
      final existingLikeEntries = await _sb
          .from('terugvoer')
          .select('terug_id')
          .eq('terug_naam', '_LIKE_')
          .limit(1);

      if (existingLikeEntries.isNotEmpty) {
        likeEntryId = existingLikeEntries.first['terug_id'] as String;
      } else {
        // Create new like entry
        final newLikeEntry = await _sb.from('terugvoer').insert({
          'terug_naam': '_LIKE_',
          'terug_beskrywing': 'System generated like indicator',
        }).select('terug_id').single();
        likeEntryId = newLikeEntry['terug_id'] as String;
      }

      // Add like tracking entry to the linking table
      await _sb.from('bestelling_kos_item_terugvoer').insert({
        'best_kos_id': bestKosId,
        'terug_id': likeEntryId,
        'geskep_datum': DateTime.now().toIso8601String(),
      });

      // Update the kos_item_likes count by counting all likes for this kos_item
      // through the linking table
      await _updateKosItemLikesCount(kosItemId);

      return true;
    } catch (e) {
      print('Error liking kos item: $e');
      return false;
    }
  }

  /// Unlike a kos_item (remove user like tracking through linking table)
  Future<bool> unlikeKosItem(String userId, String kosItemId, String bestKosId) async {
    try {
      // Get the special like entry (use limit(1) to handle multiple entries)
      final likeEntries = await _sb
          .from('terugvoer')
          .select('terug_id')
          .eq('terug_naam', '_LIKE_')
          .limit(1);

      if (likeEntries.isEmpty) {
        return true; // No like entry exists, so nothing to unlike
      }

      final likeEntry = likeEntries.first;

      // Remove like tracking entry from the linking table
      await _sb
          .from('bestelling_kos_item_terugvoer')
          .delete()
          .eq('best_kos_id', bestKosId)
          .eq('terug_id', likeEntry['terug_id']);

      // Update the kos_item_likes count by counting all remaining likes for this kos_item
      // through the linking table
      await _updateKosItemLikesCount(kosItemId);

      return true;
    } catch (e) {
      print('Error unliking kos item: $e');
      return false;
    }
  }

  /// Get the current like count for a kos_item
  Future<int> getKosItemLikes(String kosItemId) async {
    try {
      final result = await _sb
          .from('kos_item')
          .select('kos_item_likes')
          .eq('kos_item_id', kosItemId)
          .single();

      // Handle integer from database
      return (result['kos_item_likes'] as int?) ?? 0;
    } catch (e) {
      print('Error getting kos item likes: $e');
      return 0;
    }
  }

  /// Update the kos_item_likes count by counting likes through the linking table
  Future<void> _updateKosItemLikesCount(String kosItemId) async {
    try {
      // Get the special like entry (use limit(1) to handle multiple entries)
      final likeEntries = await _sb
          .from('terugvoer')
          .select('terug_id')
          .eq('terug_naam', '_LIKE_')
          .limit(1);

      if (likeEntries.isEmpty) {
        // No like system, set count to 0
        await _sb
            .from('kos_item')
            .update({'kos_item_likes': 0})
            .eq('kos_item_id', kosItemId);
        return;
      }

      final likeEntry = likeEntries.first;

      // Count all likes for this kos_item through the linking table
      // We need to join: bestelling_kos_item_terugvoer -> bestelling_kos_item -> kos_item
      final bestKosIds = await _getBestellingKosItemIdsForKosItem(kosItemId);
      
      if (bestKosIds.isEmpty) {
        // No bestelling_kos_item records for this kos_item, set count to 0
        await _sb
            .from('kos_item')
            .update({'kos_item_likes': 0})
            .eq('kos_item_id', kosItemId);
        return;
      }

      final likeRecords = await _sb
          .from('bestelling_kos_item_terugvoer')
          .select('best_terug_id')
          .eq('terug_id', likeEntry['terug_id'])
          .inFilter('best_kos_id', bestKosIds);

      // Update the kos_item_likes field with the actual count
      await _sb
          .from('kos_item')
          .update({'kos_item_likes': likeRecords.length})
          .eq('kos_item_id', kosItemId);
    } catch (e) {
      print('Error updating kos item likes count: $e');
    }
  }

  /// Get all bestelling_kos_item IDs for a specific kos_item
  Future<List<String>> _getBestellingKosItemIdsForKosItem(String kosItemId) async {
    try {
      final result = await _sb
          .from('bestelling_kos_item')
          .select('best_kos_id')
          .eq('kos_item_id', kosItemId);

      return result.map((item) => item['best_kos_id'] as String).toList();
    } catch (e) {
      print('Error getting bestelling_kos_item IDs: $e');
      return [];
    }
  }
}
