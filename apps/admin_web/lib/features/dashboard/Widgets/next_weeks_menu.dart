import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NextWeeksMenu extends StatefulWidget {
  final Function(String) onNavigateToMenu;

  const NextWeeksMenu({Key? key, required this.onNavigateToMenu})
    : super(key: key);

  @override
  State<NextWeeksMenu> createState() => _NextWeeksMenuState();
}

class _NextWeeksMenuState extends State<NextWeeksMenu> {
  late final AdminSpyskaartRepository _repo;
  List<Map<String, dynamic>>? _weeklyMenu;
  List<DateTime>? _nextWeekDates;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _repo = AdminSpyskaartRepository(SupabaseDb(supabaseClient));
    _loadNextWeeksMenu();
  }

  Future<void> _loadNextWeeksMenu() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Calculate next week's Monday (start of next week)
      final now = DateTime.now();
      // Calculate days until next Monday
      // Monday = 1, Tuesday = 2, ..., Sunday = 7
      // We want the Monday of next week, not this week
      int daysUntilNextMonday;
      if (now.weekday == 1) {
        // Today is Monday, so next Monday is 7 days away
        daysUntilNextMonday = 7;
      } else {
        // Calculate days until next Monday
        daysUntilNextMonday = (8 - now.weekday) % 7;
        if (daysUntilNextMonday == 0) {
          // Today is Sunday, next Monday is tomorrow
          daysUntilNextMonday = 1;
        }
      }
      final nextWeekStart = now.add(Duration(days: daysUntilNextMonday));

      // Get next week dates
      _nextWeekDates = List.generate(
        7,
        (index) => nextWeekStart.add(Duration(days: index)),
      );

      // Get or create spyskaart for next week
      final spyskaartData = await _repo.getOrCreateSpyskaartForDate(
        nextWeekStart,
      );

      // Debug: Print the raw spyskaart data
      print('Raw spyskaart data: $spyskaartData');
      print('Spyskaart data keys: ${spyskaartData.keys.toList()}');

      // Process the data into the expected format
      _weeklyMenu = _processSpyskaartData(spyskaartData);

      // Debug: Print processed menu
      print('Processed weekly menu: ${_weeklyMenu?.length} days');
      if (_weeklyMenu != null && _weeklyMenu!.isNotEmpty) {
        print('First day menu: ${_weeklyMenu!.first}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _processSpyskaartData(
    Map<String, dynamic> spyskaartData,
  ) {
    final List<Map<String, dynamic>> weeklyMenu = [];
    final List<Map<String, dynamic>> spyskaartItems =
        List<Map<String, dynamic>>.from(
          spyskaartData['spyskaart_kos_item'] ?? [],
        );

    // Debug: Print the raw data structure
    print('Spyskaart items count: ${spyskaartItems.length}');
    if (spyskaartItems.isNotEmpty) {
      print('First item structure: ${spyskaartItems.first}');
    }

    // Group items by day
    final Map<String, List<Map<String, dynamic>>> itemsByDay = {};
    for (final item in spyskaartItems) {
      final weekDag = item['week_dag'] as Map<String, dynamic>?;
      if (weekDag != null) {
        final dagNaam = weekDag['week_dag_naam'] as String?;
        if (dagNaam != null) {
          itemsByDay.putIfAbsent(dagNaam.toLowerCase(), () => []);
          itemsByDay[dagNaam.toLowerCase()]!.add(item);
        }
      }
    }

    // Debug: Print grouped items
    print('Items by day: ${itemsByDay.keys.toList()}');
    itemsByDay.forEach((day, items) {
      print('$day: ${items.length} items');
    });

    // Check if we have any items at all
    if (spyskaartItems.isEmpty) {
      print('No spyskaart items found in data');
    } else if (itemsByDay.isEmpty) {
      print('Items found but no day grouping - checking item structure');
      for (int i = 0; i < spyskaartItems.length && i < 3; i++) {
        print('Item $i: ${spyskaartItems[i]}');
      }
    }

    // Create menu for each day of the week
    const dayNames = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrydag',
      'Saterdag',
      'Sondag',
    ];
    // const dayNamesEn = [
    //   'Monday',
    //   'Tuesday',
    //   'Wednesday',
    //   'Thursday',
    //   'Friday',
    //   'Saturday',
    //   'Sunday',
    // ];

    for (int i = 0; i < 7; i++) {
      final dayName = dayNames[i];
      // final dayNameEn = dayNamesEn[i];
      final dayItems = itemsByDay[dayName.toLowerCase()] ?? [];

      // Extract food item names
      final List<String> itemNames = [];
      int readyItems = 0;

      for (final item in dayItems) {
        final kosItem = item['kos_item'] as Map<String, dynamic>?;
        if (kosItem != null) {
          final itemName = kosItem['kos_item_naam'] as String?;
          if (itemName != null) {
            itemNames.add(itemName);

            // Check if item is ready (has cutoff date set)
            final cutoffDate = item['spyskaart_kos_afsny_datum'];
            if (cutoffDate != null) {
              readyItems++;
            }
          }
        }
      }

      weeklyMenu.add({
        'day': dayName,
        'date': _nextWeekDates![i],
        'items': itemNames,
        'totalItems': itemNames.length,
        'readyItems': readyItems,
      });
    }

    return weeklyMenu;
  }

  String formatShortDate(DateTime d) {
    // e.g., Oct 21
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volgende week se spyskaart',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (_nextWeekDates != null)
                        Text(
                          '${formatShortDate(_nextWeekDates![0])} - ${formatShortDate(_nextWeekDates![6])}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (_nextWeekDates != null)
                        Text(
                          'Sperdatum: ${formatShortDate(_nextWeekDates![6])} ${_nextWeekDates![6].year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/week_spyskaart'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text('Meer'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content area
            if (_isLoading)
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Laai volgende week se spyskaart...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red.shade50,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Kon nie spyskaart laai nie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadNextWeeksMenu,
                        icon: Icon(Icons.refresh),
                        label: Text('Probeer weer'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_weeklyMenu == null || _weeklyMenu!.isEmpty)
              Container(
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Geen spyskaart vir volgende week nie',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Klik "Meer" om een te skep',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadNextWeeksMenu,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Herlaai'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  itemCount: _weeklyMenu!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final dayMenu = _weeklyMenu![i];
                    final total = dayMenu['totalItems'] as int;

                    final items = List<String>.from(dayMenu['items']);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dayMenu['day'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatShortDate(dayMenu['date']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$total',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            Text(
                              'Nog geen items vir hierdie dag nie!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8.0, // Horizontal spacing between items
                              runSpacing: 4.0, // Vertical spacing between lines
                              children: [
                                for (int j = 0; j < items.length; j++)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.deepOrange.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      items[j],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,

                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
