import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../services/order_service.dart';
import '../../../models/order.dart';
import 'package:spys/l10n/app_localizations.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    setState(() {
      _order = _orderService.getOrderById(widget.orderId);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.orderDetailTitle),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.orderDetailTitle),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.orderNotFound),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bestelling #${_order!.id}'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_order!.status == 'ready')
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQRCode(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Order Info Card
            _buildOrderInfoCard(),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Items Card
            _buildItemsCard(),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Pickup Info Card
            _buildPickupInfoCard(),
            
            // Allergies Warning
            if (_order!.allergiesWarning.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              _buildAllergiesCard(),
            ],
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Action Buttons
            _buildActionButtons(),
            
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_order!.status);
    final statusIcon = _getStatusIcon(_order!.status);
    final statusText = _getStatusText(_order!.status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor, setOpacity(statusColor, 204/255)], // Changed from .withOpacity
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              statusText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              _getStatusDescription(_order!.status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: setOpacity(Colors.white, 230/255), // Changed from .withOpacity
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderInfoTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildInfoRow(AppLocalizations.of(context)!.orderIdLabel, '#${_order!.id}'),
            _buildInfoRow(AppLocalizations.of(context)!.orderDateLabel, _formatDateTime(_order!.orderDate)),
            _buildInfoRow(AppLocalizations.of(context)!.totalAmountLabel, 'R${_order!.totalAmount.toStringAsFixed(2)}'),
            _buildInfoRow(AppLocalizations.of(context)!.itemsLabel, '${_order!.items.length}'),
            if (_order!.notes != null)
              _buildInfoRow(AppLocalizations.of(context)!.notesLabel, _order!.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderedItemsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ..._order!.items.map((item) => _buildItemRow(item)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.subtotalLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'R${(_order!.totalAmount / 1.15).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.vatLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'R${(_order!.totalAmount * 0.15 / 1.15).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.totalLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R${_order!.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.pickupInfoTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: Text(
                    _order!.pickupLocation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_order!.pickupTime != null) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    '${AppLocalizations.of(context)!.readyUntil}: ${_formatDateTime(_order!.pickupTime!)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (_order!.status == 'ready') ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: setOpacity(AppConstants.successColor, 25/255), // Changed from .withOpacity
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppConstants.successColor,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.yourOrderIsReadyForPickup}. ${AppLocalizations.of(context)!.showYourQRCodeAtTheCounter}',
                        style: const TextStyle(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: setOpacity(AppConstants.warningColor, 25/255), // Changed from .withOpacity
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: AppConstants.warningColor,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Text(
                  AppLocalizations.of(context)!.allergyWarningTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              AppLocalizations.of(context)!.allergiesWarningDescription,
              style: const TextStyle(color: AppConstants.warningColor),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _order!.allergiesWarning.map((allergy) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.warningColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    allergy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // QR Code Button (if ready)
        if (_order!.status == 'ready') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showQRCode(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              icon: const Icon(Icons.qr_code),
              label: Text(
                AppLocalizations.of(context)!.showQRCodeButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
        ],

        // Cancel Button (if can cancel)
        if (_order!.canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.errorColor),
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              icon: const Icon(Icons.cancel, color: AppConstants.errorColor),
              label: Text(
                AppLocalizations.of(context)!.cancelOrderButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.errorColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
        ],

        // Feedback Button (if delivered and no feedback yet)
        if (_order!.status == 'delivered' && _order!.feedback == null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFeedbackDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              icon: const Icon(Icons.star),
              label: Text(
                AppLocalizations.of(context)!.giveFeedbackButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],

        // Show feedback if already given
        if (_order!.feedback != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: setOpacity(AppConstants.primaryColor, 25/255), // Changed from .withOpacity
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      '${AppLocalizations.of(context)!.yourRating}: ${_order!.feedback!.rating}/5',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_order!.feedback!.comment != null) ...[
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    '"${_order!.feedback!.comment}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: setOpacity(AppConstants.primaryColor, 0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
            ),
            child: const Icon(
              Icons.restaurant,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.quantity}x R${item.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (item.specialInstructions != null) ...[
                  Text(
                    '${AppLocalizations.of(context)!.specialInstructions}: ${item.specialInstructions}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'R${(item.price * item.quantity).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.qrCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mock QR Code (in real app, use qr_flutter package)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 100,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    AppLocalizations.of(context)!.qrCodeLabel,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '#${_order!.id}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              '${AppLocalizations.of(context)!.showThisCodeAt} ${_order!.pickupLocation}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              '${AppLocalizations.of(context)!.qrCode}: ${_order!.qrCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _order!.qrCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.qrCodeCopied)),
              );
            },
            child: Text(AppLocalizations.of(context)!.copy),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelOrderTitle),
        content: Text(
          '${AppLocalizations.of(context)!.areYouSureToCancelOrder} #${_order!.id}?\n\n'
          '${AppLocalizations.of(context)!.yourMoneyWillBeRefundedToYourAccount}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await _orderService.cancelOrder(_order!.id);
              if (success) {
                _loadOrderDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppLocalizations.of(context)!.orderCancelled}. ${AppLocalizations.of(context)!.moneyRefunded}'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.couldNotCancelOrder),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.yesCancelOrder),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.giveFeedbackTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.of(context)!.howWasYourExperienceWithOrder} #${_order!.id}?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${AppLocalizations.of(context)!.rating}: '),
                  ...List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                  Text('${rating.toInt()}/5'),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.commentOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final success = await _orderService.submitFeedback(
                  _order!.id,
                  rating,
                  commentController.text.isEmpty ? null : commentController.text,
                );
                
                if (success) {
                  _loadOrderDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.thankYouForFeedback),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.send),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppConstants.warningColor;
      case 'processing':
        return AppConstants.secondaryColor;
      case 'ready':
        return AppConstants.successColor;
      case 'delivered':
        return AppConstants.primaryColor;
      case 'cancelled':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'processing':
        return AppLocalizations.of(context)!.processing;
      case 'ready':
        return AppLocalizations.of(context)!.readyForPickup;
      case 'delivered':
        return AppLocalizations.of(context)!.delivered;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return AppLocalizations.of(context)!.pendingDescription;
      case 'processing':
        return AppLocalizations.of(context)!.processingDescription;
      case 'ready':
        return AppLocalizations.of(context)!.readyDescription;
      case 'delivered':
        return AppLocalizations.of(context)!.deliveredDescription;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelledDescription;
      default:
        return AppLocalizations.of(context)!.statusUnknown;
    }
  }
} 
