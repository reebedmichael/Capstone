import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:capstone_admin/features/dashboard/presentation/dashboard_page.dart';

void main() {
	testWidgets('Dashboard cards render', (tester) async {
		await tester.pumpWidget(const MaterialApp(home: Scaffold(body: DashboardPage())));
		expect(find.text('Aktiewe bestellings'), findsOneWidget);
		expect(find.text('Verkope (7 dae)'), findsOneWidget);
	});
} 