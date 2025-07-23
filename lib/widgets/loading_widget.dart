import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/utils/color_utils.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
