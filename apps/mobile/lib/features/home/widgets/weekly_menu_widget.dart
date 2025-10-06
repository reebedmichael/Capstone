import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../models/weekly_menu_item.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/constants/spacing.dart';
import '../../../core/services/timezone_service.dart';
import '../services/weekly_menu_service.dart';

class WeeklyMenuWidget extends StatefulWidget {
  const WeeklyMenuWidget({super.key});

  @override
  State<WeeklyMenuWidget> createState() => _WeeklyMenuWidgetState();
}

class _WeeklyMenuWidgetState extends State<WeeklyMenuWidget> {
  List<WeeklyMenuItem> weeklyItems = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWeeklyMenu();
    _checkExpiredItems();
  }

  Future<void> _loadWeeklyMenu() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final items = await WeeklyMenuService.getWeeklyMenuItems();
      setState(() {
        weeklyItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _checkExpiredItems() async {
    try {
      final removedItems = await WeeklyMenuService.checkAndRemoveExpiredCartItems();
      if (removedItems.isNotEmpty && mounted) {
        for (final item in removedItems) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed: $item — orders closed at 17:00 the day before.'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking expired items: $e');
    }
  }

  Future<void> _addToCart(WeeklyMenuItem item) async {
    if (!item.orderable) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add items to cart.'),
        ),
      );
      return;
    }

    try {
      // Add to cart using the existing repository
      final mandjieRepo = MandjieRepository(
        SupabaseDb(Supabase.instance.client),
      );

      await mandjieRepo.voegByMandjie(
        gebrId: user.id,
        kosItemId: item.id,
        aantal: 1,
        weekDagNaam: item.weekDagNaam,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added: ${item.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to cart: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading weekly menu',
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyMenu,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenHPad),
          child: Text(
            'Spyskaart of the Week',
            style: AppTypography.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.screenHPad),
            itemCount: weeklyItems.length,
            itemBuilder: (context, index) {
              final item = weeklyItems[index];
              return _buildDayCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(WeeklyMenuItem item) {
    final isPlaceholder = item.id.startsWith('placeholder');
    final cutoffTime = TimezoneService.getCutoffForMenuDate(item.date);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: item.orderable ? 2 : 0,
        color: item.orderable 
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant,
        child: InkWell(
          onTap: item.orderable && !isPlaceholder ? () => _addToCart(item) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day and date
                Row(
                  children: [
                    Text(
                      item.dayName,
                      style: AppTypography.labelMedium.copyWith(
                        color: item.orderable 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!item.orderable)
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimezoneService.formatDateForDisplay(item.date),
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Item name
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: item.orderable 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Price or status
                if (isPlaceholder)
                  Text(
                    'No menu',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (item.orderable)
                  Text(
                    'R${item.price.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not available',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Cutoff: ${TimezoneService.formatTimeForDisplay(cutoffTime)} (day before)',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 8),
                
                // Action button
                if (!isPlaceholder)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: item.orderable ? () => _addToCart(item) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.orderable 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        foregroundColor: item.orderable 
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        item.orderable ? 'Add to Cart' : 'Unavailable',
                        style: AppTypography.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
