import 'package:capstone_admin/features/dashboard/Widgets/dashboard_header.dart';
import 'package:capstone_admin/features/dashboard/Widgets/kpi_cards.dart';
import 'package:capstone_admin/features/dashboard/Widgets/sales_overview.dart';
import 'package:capstone_admin/features/dashboard/Widgets/important_notifications.dart';
import 'package:capstone_admin/features/dashboard/Widgets/todays_orders.dart';
import 'package:capstone_admin/features/dashboard/Widgets/next_weeks_menu.dart';
import 'package:capstone_admin/features/dashboard/Widgets/pending_user_approvals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef NavigateCallback = void Function(String page);

class DashboardPage extends StatefulWidget {
  final NavigateCallback? onNavigate;

  const DashboardPage({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _unreadNotificationCount = 0;

  // Add ValueNotifier to trigger KPI refresh
  final ValueNotifier<int> _kpiRefreshTrigger = ValueNotifier<int>(0);

  late final List<DateTime> nextWeekDates;
  late List<Map<String, dynamic>> weeklyMenu;

  final List<Map<String, String>> recentActivity = [
    {'action': 'Admin John updated the menu template', 'time': '5 mins ago'},
    {
      'action': 'New order #12349 received from Alex Brown',
      'time': '12 mins ago',
    },
    {'action': 'Admin Sarah processed order #12340', 'time': '30 mins ago'},
    {
      'action': 'Menu item "Spicy Burger" marked as out of stock',
      'time': '1 hour ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    nextWeekDates = getNextWeekDates();
    weeklyMenu = [
      {
        'day': 'Monday',
        'date': nextWeekDates[0],
        'items': ['Grilled Chicken Salad', 'Beef Burger', 'Vegetarian Pizza'],
        'totalItems': 8,
        'readyItems': 6,
      },
      {
        'day': 'Tuesday',
        'date': nextWeekDates[1],
        'items': ['Fish Tacos', 'Caesar Wrap', 'Mushroom Risotto'],
        'totalItems': 7,
        'readyItems': 7,
      },
      {
        'day': 'Wednesday',
        'date': nextWeekDates[2],
        'items': ['Steak Dinner', 'Chicken Noodle Soup', 'Garden Salad'],
        'totalItems': 9,
        'readyItems': 5,
      },
      {
        'day': 'Thursday',
        'date': nextWeekDates[3],
        'items': ['Pasta Carbonara', 'BBQ Ribs', 'Quinoa Bowl'],
        'totalItems': 6,
        'readyItems': 6,
      },
      {
        'day': 'Friday',
        'date': nextWeekDates[4],
        'items': ['Fish & Chips', 'Thai Curry', 'Mediterranean Wrap'],
        'totalItems': 10,
        'readyItems': 8,
      },
      {
        'day': 'Saturday',
        'date': nextWeekDates[5],
        'items': ['Weekend Special Brunch', 'Grilled Salmon', 'Veggie Burger'],
        'totalItems': 8,
        'readyItems': 4,
      },
      {
        'day': 'Sunday',
        'date': nextWeekDates[6],
        'items': ['Sunday Roast', 'Chicken Wings', 'Fresh Fruit Bowl'],
        'totalItems': 7,
        'readyItems': 7,
      },
    ];
  }

  List<DateTime> getNextWeekDates() {
    final today = DateTime.now();
    // compute next Monday
    int weekday = today.weekday; // Monday=1 ... Sunday=7
    int daysUntilNextMonday = ((8 - weekday) % 7);
    if (daysUntilNextMonday == 0) daysUntilNextMonday = 7;
    final nextMonday = today.add(Duration(days: daysUntilNextMonday));
    final List<DateTime> weekDays = [];
    for (int i = 0; i < 7; i++) {
      weekDays.add(nextMonday.add(Duration(days: i)));
    }
    return weekDays;
  }

  TextStyle accountTypeTextStyle(String type) {
    switch (type) {
      case 'Customer':
        return TextStyle(color: Colors.blue[800]);
      case 'Delivery Partner':
        return TextStyle(color: Colors.green[800]);
      case 'Restaurant Partner':
        return TextStyle(color: Colors.purple[800]);
      default:
        return TextStyle(color: Colors.grey[800]);
    }
  }

  Icon getNotificationIcon(String type) {
    switch (type) {
      case 'critical':
        return const Icon(Icons.error, color: Colors.red);
      case 'warning':
        return const Icon(Icons.warning, color: Colors.amber);
      case 'info':
        return const Icon(Icons.info, color: Colors.blue);
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  BoxDecoration getNotificationDecoration(String type) {
    switch (type) {
      case 'critical':
        return BoxDecoration(
          color: Colors.red.shade50,
          border: Border(left: BorderSide(color: Colors.red, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'warning':
        return BoxDecoration(
          color: Colors.amber.shade50,
          border: Border(left: BorderSide(color: Colors.amber, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'info':
        return BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(left: BorderSide(color: Colors.blue, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'success':
        return BoxDecoration(
          color: Colors.green.shade50,
          border: Border(left: BorderSide(color: Colors.green, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      default:
        return BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
    }
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
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isLarge = mediaWidth >= 1200;
    final isMedium = mediaWidth >= 800 && mediaWidth < 1200;

    return Column(
      children: [
        // Dashboard Header
        DashboardHeader(
          ongeleeseKennisgewings: _unreadNotificationCount,
          onNavigeerNaKennisgewings: () => context.go('/kennisgewings'),
          onUitteken: () {
            // No longer needed - handled internally by DashboardHeader
          },
        ),

        // Main Dashboard Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // KPI Cards
                KpiCards(
                  mediaWidth: mediaWidth,
                  refreshTrigger: _kpiRefreshTrigger,
                ),

                const SizedBox(height: 16),

                // Charts & Important Notifications
                if (isLarge || isMedium)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sales chart (left, large)
                      Expanded(flex: 2, child: SalesOverview()),
                      const SizedBox(width: 16),
                      // Important Notifications (right, small)
                      Expanded(
                        flex: 1,
                        child: ImportantNotifications(
                          onNotificationCountChanged: (count) {
                            setState(() {
                              _unreadNotificationCount = count;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      SalesOverview(),
                      const SizedBox(height: 16),
                      ImportantNotifications(
                        onNotificationCountChanged: (count) {
                          setState(() {
                            _unreadNotificationCount = count;
                          });
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Today's Orders & Weekly Menu
                if (isLarge || isMedium)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Orders (left)
                      Expanded(
                        child: TodaysOrders(
                          onStatusChangedToDone: () {
                            // Refresh KPI cards when status changes to done
                            _kpiRefreshTrigger.value++;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Weekly Menu (right)
                      Expanded(
                        child: NextWeeksMenu(
                          onNavigateToMenu: widget.onNavigate ?? (page) {},
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TodaysOrders(
                        onStatusChangedToDone: () {
                          // Refresh KPI cards when status changes to done
                          _kpiRefreshTrigger.value++;
                        },
                      ),
                      const SizedBox(height: 16),
                      NextWeeksMenu(
                        onNavigateToMenu: widget.onNavigate ?? (page) {},
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // User Management Summary
                const UserManagementSummary(),

                const SizedBox(height: 16),

                // Quick Actions
                // QuickActions(
                //   isLarge: isLarge,
                //   isMedium: isMedium,
                //   widget: widget,
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
