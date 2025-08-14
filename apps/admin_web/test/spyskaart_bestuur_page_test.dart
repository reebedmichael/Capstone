import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:capstone_admin/features/spyskaart/presentation/spyskaart_bestuur_page.dart';

void main() {
	testWidgets('Spyskaart bestuur renders controls', (tester) async {
		await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SpyskaartBestuurPage())));
		expect(find.text('Voeg nuwe item by'), findsOneWidget);
		expect(find.text('Soek'), findsOneWidget);
	});
} 