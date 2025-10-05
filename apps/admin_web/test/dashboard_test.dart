import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spys_ui_shared/spys_ui_shared.dart';

void main() {
  group('Admin Dashboard Tests', () {
    testWidgets('Dashboard components render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Test stat cards
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Active Orders',
                          subtitle: '5',
                          icon: Icons.receipt_long,
                        ),
                      ),
                      Expanded(
                        child: InfoCard(
                          title: 'Sales This Week',
                          subtitle: 'R1,250.00',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  // Test buttons
                  PrimaryButton(
                    text: 'Refresh Data',
                    onPressed: () {},
                    icon: Icons.refresh,
                  ),
                  // Test loading state
                  LoadingIndicator(message: 'Loading dashboard data...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify components render
      expect(find.text('Active Orders'), findsOneWidget);
      expect(find.text('Sales This Week'), findsOneWidget);
      expect(find.text('Refresh Data'), findsOneWidget);
      expect(find.text('Loading dashboard data...'), findsOneWidget);
    });
  });
}
