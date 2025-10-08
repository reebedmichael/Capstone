import 'dart:async';

/// Global notifier for order refresh events
class OrderRefreshNotifier {
  static final OrderRefreshNotifier _instance = OrderRefreshNotifier._internal();
  factory OrderRefreshNotifier() => _instance;
  OrderRefreshNotifier._internal();

  final StreamController<void> _refreshController = StreamController<void>.broadcast();

  /// Stream that emits when orders should be refreshed
  Stream<void> get refreshStream => _refreshController.stream;

  /// Trigger a refresh event
  void triggerRefresh() {
    _refreshController.add(null);
    print('🔄 Order refresh triggered globally');
  }

  /// Dispose the controller
  void dispose() {
    _refreshController.close();
  }
}
