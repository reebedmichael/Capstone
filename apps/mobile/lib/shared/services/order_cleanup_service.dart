import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for automatically cleaning up unclaimed orders
class OrderCleanupService {
  final SupabaseClient _supabase;

  OrderCleanupService(this._supabase);

  /// Automatically cancel unclaimed orders that are past their delivery date
  /// This should be called periodically (e.g., daily at midnight)
  Future<Map<String, dynamic>> cancelUnclaimedOrders() async {
    try {
      print('🧹 Starting automatic cleanup of unclaimed orders...');
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Find all orders that are past their delivery date and not yet completed/cancelled
      // Only cancel items that are past their due date (not just past the date, but past midnight of the due date)
      final unclaimedOrders = await _supabase
          .from('bestelling_kos_item')
          .select('''
            best_kos_id,
            best_id,
            best_datum,
            kos_item:kos_item_id(kos_item_naam),
            best_kos_item_statusse(
              kos_item_statusse:kos_stat_id(kos_stat_naam)
            )
          ''')
          .lt('best_datum', todayDate.toIso8601String());
      
      if (unclaimedOrders.isEmpty) {
        print('✅ No unclaimed orders found');
        return {
          'success': true,
          'cancelledCount': 0,
          'message': 'Geen onopgehaalde bestellings gevind nie',
        };
      }
      
      print('🔍 Found ${unclaimedOrders.length} potentially unclaimed orders');
      
      // Get the "Gekanselleer" status ID
      final cancelStatusData = await _supabase
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Gekanselleer')
          .maybeSingle();
      
      if (cancelStatusData == null) {
        throw Exception('Kon nie "Gekanselleer" status vind nie');
      }
      
      final cancelStatusId = cancelStatusData['kos_stat_id'] as String;
      int cancelledCount = 0;
      List<String> cancelledItems = [];
      
      // Process each unclaimed order
      for (final order in unclaimedOrders) {
        final bestKosId = order['best_kos_id'] as String;
        final bestDatumStr = order['best_datum'] as String?;
        final kosItem = order['kos_item'] as Map<String, dynamic>?;
        final itemName = kosItem?['kos_item_naam'] as String? ?? 'Onbekende item';
        
        if (bestDatumStr == null) continue;
        
        try {
          final bestDatum = DateTime.parse(bestDatumStr);
          final orderDate = DateTime(bestDatum.year, bestDatum.month, bestDatum.day);
          
          // Skip if order is not past its delivery date
          // This means: Monday items are cancelled on Tuesday (after midnight Monday)
          // Tuesday items are cancelled on Wednesday (after midnight Tuesday), etc.
          if (!orderDate.isBefore(todayDate)) continue;
          
          // Check if order is already completed or cancelled
          final statuses = order['best_kos_item_statusse'] as List? ?? [];
          bool isAlreadyProcessed = false;
          
          for (final status in statuses) {
            final statusInfo = status['kos_item_statusse'] as Map<String, dynamic>?;
            final statusName = statusInfo?['kos_stat_naam'] as String?;
            if (statusName == 'Afgehandel' || statusName == 'Gekanselleer') {
              isAlreadyProcessed = true;
              break;
            }
          }
          
          if (isAlreadyProcessed) continue;
          
          // Cancel the order item
          await _supabase.from('best_kos_item_statusse').insert({
            'best_kos_id': bestKosId,
            'kos_stat_id': cancelStatusId,
            'best_kos_wysig_datum': DateTime.now().toIso8601String(),
          });
          
          cancelledCount++;
          cancelledItems.add(itemName);
          
          print('✅ Cancelled unclaimed order: $itemName (Order date: ${_formatDateForDisplay(orderDate)})');
          
        } catch (e) {
          print('❌ Error processing order $bestKosId: $e');
        }
      }
      
      print('✅ Cleanup completed. Cancelled $cancelledCount orders');
      
      return {
        'success': true,
        'cancelledCount': cancelledCount,
        'cancelledItems': cancelledItems,
        'message': cancelledCount > 0 
            ? '$cancelledCount onopgehaalde bestelling(s) is outomaties gekanselleer'
            : 'Geen onopgehaalde bestellings gevind nie',
      };
      
    } catch (e) {
      print('❌ Error during order cleanup: $e');
      return {
        'success': false,
        'message': 'Fout tydens outomatiese opruiming: $e',
      };
    }
  }
  
  /// Format date for display in Afrikaans
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Januarie', 'Februarie', 'Maart', 'April', 'Mei', 'Junie',
      'Julie', 'Augustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final weekdays = [
      'Sondag', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag', 'Saterdag'
    ];
    
    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    
    return '$weekday ${date.day} $month ${date.year}';
  }
}
