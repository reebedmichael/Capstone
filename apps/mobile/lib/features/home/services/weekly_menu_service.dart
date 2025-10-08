import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_menu_item.dart';
import '../../../core/services/timezone_service.dart';
import '../../../shared/state/cart_badge.dart';

class WeeklyMenuService {
  
  /// Get the current week's menu items (Monday to Sunday)
  static Future<List<WeeklyMenuItem>> getWeeklyMenuItems() async {
    try {
      final nowInSAST = TimezoneService.nowInSAST();
      final weekStart = _getCurrentWeekStart(nowInSAST);
      
      // Get the spyskaart for this week
      final spyskaartData = await Supabase.instance.client
          .from('spyskaart')
          .select('''
            spyskaart_id,
            spyskaart_datum,
            spyskaart_kos_item:spyskaart_kos_item(
              kos_item_id,
              kos_item_naam,
              kos_item_beskrywing,
              kos_item_koste,
              kos_item_prentjie,
              week_dag_naam,
              week_dag:week_dag_id(
                week_dag_naam
              )
            )
          ''')
          .gte('spyskaart_datum', weekStart.toIso8601String().split('T')[0])
          .lte('spyskaart_datum', weekStart.add(const Duration(days: 6)).toIso8601String().split('T')[0])
          .single();

      final List<dynamic> items = spyskaartData['spyskaart_kos_item'] ?? [];
      
      // Create a map of day names to items
      final Map<String, WeeklyMenuItem> dayItems = {};
      
      for (final item in items) {
        final dayName = item['week_dag_naam'] ?? 
                       item['week_dag']?['week_dag_naam'] ?? '';
        
        if (dayName.isNotEmpty) {
          final menuDate = _getDateForDayName(weekStart, dayName);
          final isOrderable = TimezoneService.isOrderableForMenuDate(menuDate, nowInSAST);
          
          dayItems[dayName.toLowerCase()] = WeeklyMenuItem(
            date: menuDate,
            id: item['kos_item_id'].toString(),
            name: item['kos_item_naam'] ?? 'Unknown Item',
            description: item['kos_item_beskrywing'],
            price: (item['kos_item_koste'] as num?)?.toDouble() ?? 0.0,
            imageUrl: item['kos_item_prentjie'],
            dayName: dayName,
            orderable: isOrderable,
            weekDagNaam: dayName,
          );
        }
      }

      // Create list for all 7 days (Monday to Sunday)
      final List<WeeklyMenuItem> weeklyItems = [];
      final dayNames = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrydag', 'saterdag', 'sondag'];
      
      for (int i = 0; i < 7; i++) {
        final dayName = dayNames[i];
        final menuDate = weekStart.add(Duration(days: i));
        
        if (dayItems.containsKey(dayName)) {
          weeklyItems.add(dayItems[dayName]!);
        } else {
          // Create placeholder for missing days
          weeklyItems.add(WeeklyMenuItem(
            date: menuDate,
            id: 'placeholder_$i',
            name: 'No menu available',
            price: 0.0,
            dayName: _getDayDisplayName(dayName),
            orderable: false,
          ));
        }
      }

      return weeklyItems;
    } catch (e) {
      debugPrint('Error fetching weekly menu: $e');
      return [];
    }
  }

  /// Check and remove expired items from cart
  static Future<List<String>> checkAndRemoveExpiredCartItems() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final nowInSAST = TimezoneService.nowInSAST();
      final removedItems = <String>[];

      // Get all cart items
      final cartData = await Supabase.instance.client
          .from('mandjie')
          .select('''
            mand_id,
            qty,
            week_dag_naam,
            kos_item:kos_item_id(
              kos_item_id,
              kos_item_naam
            )
          ''')
          .eq('gebr_id', user.id);

      final List<Map<String, dynamic>> cartItems = List<Map<String, dynamic>>.from(cartData);

      for (final cartItem in cartItems) {
        final weekDagNaam = cartItem['week_dag_naam']?.toString();
        if (weekDagNaam == null) continue;

        // Calculate the menu date for this item
        final weekStart = _getCurrentWeekStart(nowInSAST);
        final menuDate = _getDateForDayName(weekStart, weekDagNaam);
        
        // Check if this item is past cutoff
        if (!TimezoneService.isOrderableForMenuDate(menuDate, nowInSAST)) {
          // Remove from cart
          await Supabase.instance.client
              .from('mandjie')
              .delete()
              .eq('mand_id', cartItem['mand_id']);

          final itemName = cartItem['kos_item']?['kos_item_naam'] ?? 'Unknown Item';
          removedItems.add('$itemName for $weekDagNaam');
        }
      }

      // Update cart badge
      if (removedItems.isNotEmpty) {
        final remainingCartData = await Supabase.instance.client
            .from('mandjie')
            .select('qty')
            .eq('gebr_id', user.id);
        
        final totalCount = remainingCartData.fold<int>(0, (sum, item) => sum + (item['qty'] as int? ?? 0));
        CartBadgeState.count.value = totalCount;
      }

      return removedItems;
    } catch (e) {
      debugPrint('Error checking expired cart items: $e');
      return [];
    }
  }

  /// Get current week start (Monday) in SAST
  static DateTime _getCurrentWeekStart(DateTime nowInSAST) {
    final weekday = nowInSAST.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1, so subtract (weekday - 1) days
    return DateTime(nowInSAST.year, nowInSAST.month, nowInSAST.day - daysToSubtract);
  }

  /// Get date for a specific day name in the current week
  static DateTime _getDateForDayName(DateTime weekStart, String dayName) {
    final dayMap = {
      'maandag': 0, 'dinsdag': 1, 'woensdag': 2, 'donderdag': 3,
      'vrydag': 4, 'saterdag': 5, 'sondag': 6
    };
    
    final dayOffset = dayMap[dayName.toLowerCase()] ?? 0;
    return weekStart.add(Duration(days: dayOffset));
  }

  /// Get display name for day
  static String _getDayDisplayName(String dayName) {
    final dayMap = {
      'maandag': 'Mon', 'dinsdag': 'Tue', 'woensdag': 'Wed', 'donderdag': 'Thu',
      'vrydag': 'Fri', 'saterdag': 'Sat', 'sondag': 'Sun'
    };
    
    return dayMap[dayName.toLowerCase()] ?? dayName;
  }
}
