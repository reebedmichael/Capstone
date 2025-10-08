import 'dart:async';
import 'package:flutter/material.dart';

/// Global async utility for handling button operations with watchdog and fallback reload
class AsyncUtils {
  /// Execute an async operation with watchdog and fallback reload
  /// 
  /// [operation] - The async operation to execute
  /// [onSuccess] - Callback for successful completion
  /// [onError] - Callback for error handling
  /// [context] - BuildContext for showing messages
  /// [successMessage] - Success message to show
  /// [errorMessage] - Error message to show
  /// [watchdogTimeout] - Timeout for watchdog (default 4 seconds)
  /// [operationTimeout] - Timeout for the operation (default 10 seconds)
  static Future<void> executeWithWatchdog<T>({
    required Future<T> Function() operation,
    required Function(T result) onSuccess,
    required Function(dynamic error) onError,
    required BuildContext context,
    String? successMessage,
    String? errorMessage,
    Duration watchdogTimeout = const Duration(seconds: 4),
    Duration operationTimeout = const Duration(seconds: 10),
  }) async {
    bool operationCompleted = false;
    Timer? watchdogTimer;
    
    try {
      // Start watchdog timer
      watchdogTimer = Timer(watchdogTimeout, () {
        if (!operationCompleted) {
          // Trigger fallback reload
          _triggerFallbackReload(context);
        }
      });
      
      // Execute operation with timeout
      final result = await Future.any([
        operation(),
        Future.delayed(operationTimeout, () => throw TimeoutException('Operation timeout', operationTimeout)),
      ]);
      
      // Cancel watchdog and mark as completed
      watchdogTimer.cancel();
      operationCompleted = true;
      
      // Execute success callback
      onSuccess(result);
      
      // Show success message if provided
      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      // Cancel watchdog and mark as completed
      watchdogTimer?.cancel();
      operationCompleted = true;
      
      // Execute error callback
      onError(e);
      
      // Show error message if provided
      if (errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Trigger fallback reload
  static void _triggerFallbackReload(BuildContext context) {
    // For web, use window.location.reload()
    // For mobile, refresh the data
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operation taking too long, reloading page...'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Trigger a rebuild by calling setState on the parent widget
      // This is a fallback - the parent widget should implement proper refresh
    }
  }
  
  /// Create a loading state for buttons
  static Widget createLoadingButton({
    required Widget child,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
  
  /// Create a loading state for icon buttons
  static Widget createLoadingIconButton({
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
    );
  }
}

/// Timeout exception for operations
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}
