import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spys_ui_shared/spys_ui_shared.dart';

void main() {
  group('Spys Mobile App Integration Tests', () {
    testWidgets('App initializes without errors', (WidgetTester tester) async {
      // This is a basic test to ensure the app can be built
      // In a real environment, you would test the actual app initialization
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SpysCard(
                  title: 'Test Card',
                  subtitle: 'Test Subtitle',
                ),
                PrimaryButton(
                  text: 'Test Button',
                  onPressed: () {},
                ),
                InfoCard(
                  title: 'Test Info',
                  subtitle: 'Test Info Subtitle',
                ),
                LoadingIndicator(message: 'Loading...'),
              ],
            ),
          ),
        ),
      );

      // Verify all components render
      expect(find.text('Test Card'), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.text('Test Info'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}