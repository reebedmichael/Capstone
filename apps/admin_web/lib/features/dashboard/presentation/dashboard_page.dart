import 'package:capstone_admin/features/dashboard/Widgets/quick_actions.dart';
import 'package:capstone_admin/features/dashboard/Widgets/dashboard_header.dart';
import 'package:capstone_admin/features/dashboard/Widgets/kpi_cards.dart';
import 'package:capstone_admin/features/dashboard/Widgets/sales_overview.dart';
import 'package:capstone_admin/features/dashboard/Widgets/important_notifications.dart';
import 'package:capstone_admin/features/dashboard/Widgets/todays_orders.dart';
import 'package:capstone_admin/features/dashboard/Widgets/next_weeks_menu.dart';
import 'package:capstone_admin/features/dashboard/Widgets/pending_user_approvals.dart';
import 'package:flutter/material.dart';

typedef NavigateCallback = void Function(String page);

class DashboardPage extends StatefulWidget {
  final NavigateCallback? onNavigate;

  const DashboardPage({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedLocation = 'all';

  List<Map<String, dynamic>> todaysOrders = [
    {
      'id': '#12345',
      'customer': 'John Doe',
      'status': 'In Progress',
      'time': '10:30 AM',
      'items': 3,
      'location': 'Downtown',
    },
    {
      'id': '#12346',
      'customer': 'Jane Smith',
      'status': 'Ready',
      'time': '11:15 AM',
      'items': 2,
      'location': 'Uptown',
    },
    {
      'id': '#12347',
      'customer': 'Mike Johnson',
      'status': 'Pending',
      'time': '12:00 PM',
      'items': 1,
      'location': 'Downtown',
    },
    {
      'id': '#12348',
      'customer': 'Sarah Wilson',
      'status': 'Delivered',
      'time': '09:45 AM',
      'items': 4,
      'location': 'Mall',
    },
    {
      'id': '#12349',
      'customer': 'Alex Brown',
      'status': 'Pending',
      'time': '12:30 PM',
      'items': 2,
      'location': 'Uptown',
    },
    {
      'id': '#12350',
      'customer': 'Emma Davis',
      'status': 'In Progress',
      'time': '01:00 PM',
      'items': 3,
      'location': 'Mall',
    },
    {
      'id': '#12351',
      'customer': 'Tom Wilson',
      'status': 'Ready',
      'time': '01:15 PM',
      'items': 1,
      'location': 'Downtown',
    },
    {
      'id': '#12352',
      'customer': 'Lisa Chen',
      'status': 'Out for Delivery',
      'time': '11:30 AM',
      'items': 2,
      'location': 'Uptown',
    },
    {
      'id': '#12353',
      'customer': 'David Park',
      'status': 'Pending',
      'time': '01:45 PM',
      'items': 1,
      'location': 'Mall',
    },
    {
      'id': '#12354',
      'customer': 'Rachel Green',
      'status': 'Delivered',
      'time': '10:15 AM',
      'items': 3,
      'location': 'Downtown',
    },
  ];

  final List<String> locations = [
    'All Locations',
    'Downtown',
    'Uptown',
    'Mall',
  ];

  late final List<DateTime> nextWeekDates;
  late List<Map<String, dynamic>> weeklyMenu;

  List<Map<String, dynamic>> pendingUsers = [
    {
      'id': 'user_001',
      'name': 'Michael Rodriguez',
      'email': 'michael.rodriguez@email.com',
      'phone': '+1 (555) 123-4567',
      'registrationDate': '2024-10-04',
      'accountType': 'Customer',
      'location': 'Downtown',
    },
    {
      'id': 'user_002',
      'name': 'Jessica Thompson',
      'email': 'jessica.thompson@email.com',
      'phone': '+1 (555) 987-6543',
      'registrationDate': '2024-10-04',
      'accountType': 'Delivery Partner',
      'location': 'Uptown',
    },
    {
      'id': 'user_003',
      'name': 'Ahmed Hassan',
      'email': 'ahmed.hassan@email.com',
      'phone': '+1 (555) 456-7890',
      'registrationDate': '2024-10-03',
      'accountType': 'Customer',
      'location': 'Mall',
    },
    {
      'id': 'user_004',
      'name': 'Sofia Chen',
      'email': 'sofia.chen@email.com',
      'phone': '+1 (555) 321-0987',
      'registrationDate': '2024-10-03',
      'accountType': 'Restaurant Partner',
      'location': 'Downtown',
    },
  ];

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

  List<Map<String, dynamic>> importantNotifications = [
    {
      'id': 'notif_001',
      'type': 'critical',
      'title': 'Payment System Issue',
      'message':
          'Credit card processing is experiencing delays. Some orders may be affected.',
      'time': '2 mins ago',
      'actionRequired': true,
      'dismissed': false,
    },
    {
      'id': 'notif_002',
      'type': 'warning',
      'title': 'Low Stock Alert',
      'message':
          'Chicken Breast inventory is running low at Downtown location (3 items remaining).',
      'time': '15 mins ago',
      'actionRequired': true,
      'dismissed': false,
    },
    {
      'id': 'notif_003',
      'type': 'info',
      'title': 'Delivery Partner Update',
      'message':
          'New delivery partner Sarah M. has joined the Uptown area team.',
      'time': '1 hour ago',
      'actionRequired': false,
      'dismissed': false,
    },
    {
      'id': 'notif_004',
      'type': 'success',
      'title': 'System Maintenance Complete',
      'message':
          'Scheduled database optimization completed successfully. Performance improved by 15%.',
      'time': '2 hours ago',
      'actionRequired': false,
      'dismissed': false,
    },
    {
      'id': 'notif_005',
      'type': 'warning',
      'title': 'Weather Alert',
      'message':
          'Heavy rain expected this evening. Consider adjusting delivery schedules.',
      'time': '3 hours ago',
      'actionRequired': true,
      'dismissed': false,
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

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'In Progress':
        return Colors.blue;
      case 'Ready':
        return Colors.purple;
      case 'Out for Delivery':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String? getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return 'In Progress';
      case 'In Progress':
        return 'Ready';
      case 'Ready':
        return 'Out for Delivery';
      case 'Out for Delivery':
        return 'Delivered';
      case 'Delivered':
        return null;
      default:
        return null;
    }
  }

  void updateOrdersByStatus(String currentStatus) {
    final nextStatus = getNextStatus(currentStatus);
    if (nextStatus == null) return;
    setState(() {
      todaysOrders = todaysOrders.map((order) {
        if (order['status'] == currentStatus &&
            (selectedLocation == 'all' ||
                order['location'] == selectedLocation)) {
          final updated = Map<String, dynamic>.from(order);
          updated['status'] = nextStatus;
          return updated;
        }
        return order;
      }).toList();
    });
  }

  List<Map<String, dynamic>> getFilteredOrders() {
    if (selectedLocation == 'all') return todaysOrders;
    return todaysOrders
        .where((o) => o['location'] == selectedLocation)
        .toList();
  }

  List<Map<String, dynamic>> getStatusGroups() {
    final filtered = getFilteredOrders();
    final Map<String, int> summary = {};
    for (var order in filtered) {
      final s = order['status'] as String;
      summary[s] = (summary[s] ?? 0) + 1;
    }
    final groups = [
      {
        'status': 'Pending',
        'count': summary['Pending'] ?? 0,
        'color': getStatusColor('Pending'),
      },
      {
        'status': 'In Progress',
        'count': summary['In Progress'] ?? 0,
        'color': getStatusColor('In Progress'),
      },
      {
        'status': 'Ready',
        'count': summary['Ready'] ?? 0,
        'color': getStatusColor('Ready'),
      },
      {
        'status': 'Out for Delivery',
        'count': summary['Out for Delivery'] ?? 0,
        'color': getStatusColor('Out for Delivery'),
      },
      {
        'status': 'Delivered',
        'count': summary['Delivered'] ?? 0,
        'color': getStatusColor('Delivered'),
      },
    ];
    return groups.where((g) => (g['count'] as int) > 0).toList();
  }

  void approveUser(String userId) {
    setState(() {
      pendingUsers = pendingUsers.where((u) => u['id'] != userId).toList();
    });
    // API call would go here
  }

  void rejectUser(String userId) {
    setState(() {
      pendingUsers = pendingUsers.where((u) => u['id'] != userId).toList();
    });
    // API call would go here
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

  void dismissNotification(String id) {
    setState(() {
      importantNotifications = importantNotifications.map((notif) {
        if (notif['id'] == id) {
          final copy = Map<String, dynamic>.from(notif);
          copy['dismissed'] = true;
          return copy;
        }
        return notif;
      }).toList();
    });
  }

  List<Map<String, dynamic>> getActiveNotifications() {
    return importantNotifications
        .where((n) => n['dismissed'] == false)
        .toList();
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
          ingetekendGebruikerNaam: 'Admin User', // TODO: Get from auth service
          ongeleeseKennisgewings: importantNotifications
              .where((n) => n['dismissed'] == false)
              .length,
          onNavigeerNaKennisgewings: () {
            // TODO: Navigate to notifications page
          },
          onUitteken: () {
            // TODO: Handle sign out
          },
        ),

        // Main Dashboard Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // KPI Cards
                KpiCards(mediaWidth: mediaWidth),

                const SizedBox(height: 16),

                // Charts & Important Notifications
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
                        importantNotifications: importantNotifications,
                        onDismissNotification: dismissNotification,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Today's Orders & Weekly Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Orders (left)
                    Expanded(
                      child: TodaysOrders(
                        todaysOrders: todaysOrders,
                        selectedLocation: selectedLocation,
                        locations: locations,
                        onLocationChanged: (location) {
                          setState(() {
                            selectedLocation = location;
                          });
                        },
                        onUpdateOrdersByStatus: updateOrdersByStatus,
                        onNavigateToOrders: widget.onNavigate ?? (page) {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Weekly Menu (right)
                    Expanded(
                      child: NextWeeksMenu(
                        weeklyMenu: weeklyMenu,
                        nextWeekDates: nextWeekDates,
                        onNavigateToMenu: widget.onNavigate ?? (page) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pending User Approvals
                PendingUserApprovals(
                  pendingUsers: pendingUsers,
                  onApproveUser: approveUser,
                  onRejectUser: rejectUser,
                  onNavigateToUsers: widget.onNavigate ?? (page) {},
                ),

                const SizedBox(height: 16),

                // Quick Actions
                QuickActions(
                  isLarge: isLarge,
                  isMedium: isMedium,
                  widget: widget,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
