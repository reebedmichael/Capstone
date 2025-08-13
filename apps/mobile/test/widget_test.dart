// apps/mobile/test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke: renders a widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('ok'))),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
