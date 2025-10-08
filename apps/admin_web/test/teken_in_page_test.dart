import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:capstone_admin/features/auth/presentation/teken_in_page.dart';

void main() {
	testWidgets('TekenIn page fields render', (tester) async {
		await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TekenInPage())));
		expect(find.text('Teken In'), findsOneWidget);
		expect(find.widgetWithText(TextField, 'E-pos'), findsOneWidget);
		expect(find.widgetWithText(TextField, 'Wagwoord'), findsOneWidget);
	});
} 