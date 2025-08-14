import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

const List<String> FEEDBACK_OPTIONS = [
  'Baie lekker!',
  'Goed',
  'Reguit',
  'Moet verbeter',
];

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool refreshing = false;
  int _bottomIndex = 1;

  List<Map<String, dynamic>> orders = [
    {
      'id': '123',
      'status': 'Wag vir afhaal',
      'orderDate': DateTime.now().subtract(const Duration(hours: 1)),
      'pickupLocation': 'Spys Kiosk',
      'total': 150.50,
      'items': [
        {
          'quantity': 2,
          'foodItem': {
            'name': 'Burger',
            'price': 50.00,
            'imageUrl': 'https://via.placeholder.com/150',
          },
        },
        {
          'quantity': 2,
          'foodItem': {
            'name': 'Chips',
            'price': 25.25,
            'imageUrl': 'https://via.placeholder.com/150',
          },
        },
      ],
      'feedback': null,
    },
    {
      'id': '456',
      'status': 'Afgehaal',
      'orderDate': DateTime.now().subtract(const Duration(days: 1)),
      'pickupLocation': 'Kafetaria',
      'total': 75.00,
      'items': [
        {
          'quantity': 1,
          'foodItem': {
            'name': 'Pizza',
            'price': 75.00,
            'imageUrl': 'https://via.placeholder.com/150',
          },
        },
      ],
      'feedback': {
        'liked': true,
        'selectedFeedback': 'Baie lekker!',
        'date': DateTime.now().subtract(const Duration(hours: 10)),
      },
    },
  ];

  // For detailed feedback dialog
  String _selectedFeedback = '';
  String _feedbackOrderId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mrt",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return months[month - 1];
  }

  void handleRefresh() {
    setState(() => refreshing = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => refreshing = false);
      Fluttertoast.showToast(msg: "Bestellings opgedateer");
    });
  }

  bool cancelOrder(String orderId) {
    final orderIndex = orders.indexWhere((o) => o['id'] == orderId);
    if (orderIndex == -1) return false;
    setState(() {
      orders[orderIndex]['status'] = 'Gekanselleer';
    });
    Fluttertoast.showToast(msg: 'Bestelling gekanselleer');
    return true;
  }

  void handleCancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bevestig kansellasie"),
        content: const Text(
          "Is jy seker jy wil hierdie bestelling kanselleer? Die geld sal na jou beursie terugbetaal word.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nee"),
          ),
          ElevatedButton(
            onPressed: () {
              cancelOrder(orderId);
              Navigator.pop(context);
            },
            child: const Text("Ja"),
          ),
        ],
      ),
    );
  }

  bool canCancelOrder(Map<String, dynamic> order) {
    return order['status'] == 'Wag vir afhaal' &&
        order['status'] != 'In voorbereiding' &&
        order['status'] != 'Afgehaal';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Wag vir afhaal':
        return Colors.orange.shade100;
      case 'In voorbereiding':
        return Colors.blue.shade100;
      case 'Afgehaal':
        return Colors.green.shade100;
      case 'Gekanselleer':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'Wag vir afhaal':
        return const Icon(FeatherIcons.package, color: Colors.orange, size: 16);
      case 'In voorbereiding':
        return const Icon(FeatherIcons.clock, color: Colors.blue, size: 16);
      case 'Afgehaal':
        return const Icon(
          FeatherIcons.checkCircle,
          color: Colors.green,
          size: 16,
        );
      case 'Gekanselleer':
        return const Icon(FeatherIcons.circle, color: Colors.red, size: 16);
      default:
        return const Icon(FeatherIcons.package, size: 16);
    }
  }

  void _toggleLikeFeedback(String orderId) {
    final idx = orders.indexWhere((o) => o['id'] == orderId);
    if (idx == -1) return;
    final currentlyLiked = orders[idx]['feedback']?['liked'] ?? false;
    setState(() {
      if (currentlyLiked) {
        orders[idx]['feedback'] = null;
        Fluttertoast.showToast(msg: 'Terugvoer verwyder');
      } else {
        orders[idx]['feedback'] = {'liked': true, 'date': DateTime.now()};
        Fluttertoast.showToast(msg: 'Dankie vir jou terugvoer!');
      }
    });
  }

  void _openDetailedFeedback(String orderId) {
    _selectedFeedback = '';
    _feedbackOrderId = orderId;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kies Gedetailleerde Terugvoer'),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedFeedback.isEmpty ? null : _selectedFeedback,
                  items: FEEDBACK_OPTIONS
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) =>
                      setLocalState(() => _selectedFeedback = v ?? ''),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kanselleer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedFeedback.isEmpty
                            ? null
                            : () {
                                final idx = orders.indexWhere(
                                  (o) => o['id'] == _feedbackOrderId,
                                );
                                if (idx != -1) {
                                  setState(() {
                                    orders[idx]['feedback'] = {
                                      'liked': true,
                                      'selectedFeedback': _selectedFeedback,
                                      'date': DateTime.now(),
                                    };
                                  });
                                }
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: 'Gedetailleerde terugvoer gestuur!',
                                );
                              },
                        child: const Text('Stuur'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = orders
        .where(
          (o) =>
              o['status'] == 'Wag vir afhaal' ||
              o['status'] == 'In voorbereiding',
        )
        .toList();
    final completedOrders = orders
        .where(
          (o) => o['status'] == 'Afgehaal' || o['status'] == 'Gekanselleer',
        )
        .toList();

    final displayedOrders = _tabController.index == 0
        ? activeOrders
        : completedOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bestellings'),
        actions: [
          IconButton(
            onPressed: refreshing ? null : handleRefresh,
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FeatherIcons.refreshCcw),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(text: 'Aktief (${activeOrders.length})'),
            Tab(text: 'Voltooi (${completedOrders.length})'),
          ],
        ),
      ),
      body: displayedOrders.isEmpty
          ? _buildEmptyState(_tabController.index == 0)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: displayedOrders.length,
              itemBuilder: (_, index) {
                final order = displayedOrders[index];
                return _buildOrderCard(order);
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bestelling #${order['id']}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(FeatherIcons.clock, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(order['orderDate']),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R${order['total'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(order['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusIcon(order['status']),
                          const SizedBox(width: 6),
                          Text(
                            order['status'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            // Pickup
            Row(
              children: [
                const Icon(FeatherIcons.mapPin, size: 14),
                const SizedBox(width: 6),
                Text(
                  order['pickupLocation'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items
            Column(
              children: (order['items'] as List).map<Widget>((item) {
                final food = item['foodItem'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          food['imageUrl'] ?? '',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          food['name'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'R${(item['quantity'] * (food['price'] ?? 0)).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Feedback for completed orders
            if (order['status'] == 'Afgehaal') ...[
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Terugvoer:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            // Like button
                            IconButton(
                              onPressed: () => _toggleLikeFeedback(order['id']),
                              icon: Icon(
                                orders.firstWhere(
                                          (o) => o['id'] == order['id'],
                                        )['feedback']?['liked'] ==
                                        true
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_off_alt,
                              ),
                            ),

                            // Add detailed feedback if none
                            if (order['feedback'] == null ||
                                order['feedback']?['selectedFeedback'] == null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openDetailedFeedback(order['id']),
                                icon: const Icon(FeatherIcons.plus, size: 16),
                                label: const Text('Voeg terugvoer by'),
                              ),
                          ],
                        ),
                      ],
                    ),

                    if (order['feedback'] != null &&
                        order['feedback']?['selectedFeedback'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(FeatherIcons.checkCircle, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order['feedback']['selectedFeedback'] ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Order Actions
            if (order['status'] == 'Wag vir afhaal') ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      label: const Text('Wys QR Kode'),
                      onPressed: () {
                        Fluttertoast.showToast(msg: 'QR-kode skerm (dummy)');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canCancelOrder(order))
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(FeatherIcons.alertCircle, size: 16),
                        label: const Text('Kanselleer'),
                        onPressed: () => handleCancelOrder(order['id']),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool activeTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.package, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Geen ${activeTab ? 'aktiewe' : 'voltooide'} bestellings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              activeTab
                  ? 'Jou aktiewe bestellings sal hier verskyn'
                  : 'Jou voltooide bestellings sal hier verskyn',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (activeTab)
              ElevatedButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: 'Begin bestel (dummy)');
                },
                child: const Text('Begin Bestel'),
              ),
          ],
        ),
      ),
    );
  }
}
