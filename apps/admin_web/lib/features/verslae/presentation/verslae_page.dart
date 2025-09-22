import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class VerslaePage extends StatefulWidget {
	const VerslaePage({super.key});

	@override
	State<VerslaePage> createState() => _VerslaePageState();
}

class _VerslaePageState extends State<VerslaePage> {
	bool isLoading = true;
	String? errorMessage;
	bool isExporting = false;
	
	// Data
	List<Map<String, dynamic>> bestellings = [];
	List<Map<String, dynamic>> bestellingItems = [];
	List<Map<String, dynamic>> gebruikers = [];
	List<Map<String, dynamic>> kosItems = [];
	List<Map<String, dynamic>> gebruikerTipes = [];
	List<Map<String, dynamic>> adminTipes = [];
	List<Map<String, dynamic>> kampusse = [];
	List<Map<String, dynamic>> bestellingTerugvoer = [];
	List<Map<String, dynamic>> terugvoerTipes = [];
	
	// Calculated KPIs
	double totalSales = 0.0;
	int totalOrders = 0;
	double avgOrderValue = 0.0;
	int newUsers = 0;

	// Aggregations
	List<_TopItem> topItemCountsWithFeedback = const [];
	List<_LabeledCount> userCountsByGebruikerTipe = const [];
	List<_LabeledCount> userCountsByAdminTipe = const [];
	List<_LabeledCount> orderCountsByKampus = const [];

	// Constants
	static const List<String> _exportTables = <String>[
		'admin_tipes',
		'gebruiker_tipes',
		'kampus',
		'gebruikers',
		'kos_item',
		'bestelling',
		'bestelling_kos_item',
		'kos_item_statusse',
		'best_kos_item_statusse',
		'terugvoer',
		'bestelling_terugvoer',
		'spyskaart',
		'spyskaart_kos_item',
		'week_dag',
		'beursie_transaksie',
		'transaksie_tipe',
	];

	@override
	void initState() {
		super.initState();
		_loadData();
	}

	Future<List<Map<String, dynamic>>> _selectAll(
		String table, {
		String? columns,
		String? orderBy,
		bool ascending = true,
	}) async {
		final query = Supabase.instance.client.from(table).select(columns ?? '*');
		final result = orderBy != null
			? await query.order(orderBy, ascending: ascending)
			: await query;
		return List<Map<String, dynamic>>.from(result);
	}

	Future<void> _loadData() async {
		setState(() {
			isLoading = true;
			errorMessage = null;
		});

		try {
			// Load all data in parallel
			final results = await Future.wait([
				_loadBestellings(),
				_loadBestellingItems(),
				_loadGebruikers(),
				_loadKosItems(),
				_loadGebruikerTipes(),
				_loadAdminTipes(),
				_loadKampusse(),
				_loadBestellingTerugvoer(),
				_loadTerugvoerTipes(),
			]);

			bestellings = results[0];
			bestellingItems = results[1];
			gebruikers = results[2];
			kosItems = results[3];
			gebruikerTipes = results[4];
			adminTipes = results[5];
			kampusse = results[6];
			bestellingTerugvoer = results[7];
			terugvoerTipes = results[8];

			// Calculate KPIs
			_calculateKPIs();
			_computeAggregations();

			setState(() {
				isLoading = false;
			});
		} catch (e) {
			setState(() {
				errorMessage = e.toString();
				isLoading = false;
			});
		}
	}

	Future<List<Map<String, dynamic>>> _loadBestellings() async {
		return _selectAll('bestelling', orderBy: 'best_geskep_datum', ascending: false);
	}

	Future<List<Map<String, dynamic>>> _loadBestellingItems() async {
		return _selectAll(
			'bestelling_kos_item',
			columns: '''
				*,
				kos_item:kos_item_id(*),
				bestelling:best_id(*),
				best_kos_item_statusse:best_kos_id(
					*,
					kos_item_statusse:kos_stat_id(*)
				)
			''',
		);
	}

	Future<List<Map<String, dynamic>>> _loadGebruikers() async {
		return _selectAll('gebruikers', orderBy: 'gebr_geskep_datum', ascending: false);
	}

	Future<List<Map<String, dynamic>>> _loadKosItems() async {
		return _selectAll('kos_item');
	}

	Future<List<Map<String, dynamic>>> _loadGebruikerTipes() async {
		return _selectAll('gebruiker_tipes');
	}

	Future<List<Map<String, dynamic>>> _loadAdminTipes() async {
		return _selectAll('admin_tipes');
	}

	Future<List<Map<String, dynamic>>> _loadKampusse() async {
		return _selectAll('kampus');
	}

	Future<List<Map<String, dynamic>>> _loadBestellingTerugvoer() async {
		return _selectAll(
			'bestelling_terugvoer',
			columns: '''
				*,
				terugvoer:terug_id(*)
			''',
		);
	}

	Future<List<Map<String, dynamic>>> _loadTerugvoerTipes() async {
		return _selectAll('terugvoer');
	}

	void _calculateKPIs() {
		// Total sales
		totalSales = bestellings.fold(0.0, (sum, order) => 
			sum + (order['best_volledige_prys'] as num? ?? 0.0).toDouble());
		
		// Total orders
		totalOrders = bestellings.length;
		
		// Average order value
		avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;
		
		// New users (last 30 days)
		final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
		newUsers = gebruikers.where((user) {
			final createdDate = DateTime.tryParse(user['gebr_geskep_datum'] ?? '');
			return createdDate != null && createdDate.isAfter(thirtyDaysAgo);
		}).length;
	}

	Future<void> _exportAllTablesToCsv() async {
		setState(() {
			isExporting = true;
		});
		try {
			final client = Supabase.instance.client;

			for (final table in _exportTables) {
				try {
					final rows = await client.from(table).select();
					await _downloadCsv(table, List<Map<String, dynamic>>.from(rows));
				} catch (_) {
					// Ignore tables that do not exist or fail due to RLS
				}
			}
		} finally {
			if (mounted) {
				setState(() {
					isExporting = false;
				});
			}
		}
	}

	Future<void> _downloadCsv(String tableName, List<Map<String, dynamic>> data) async {
		if (data.isEmpty) {
			final emptyBlob = html.Blob(['']);
			final url = html.Url.createObjectUrlFromBlob(emptyBlob);
			html.AnchorElement(href: url)
				..download = '${tableName}.csv'
				..click();
			html.Url.revokeObjectUrl(url);
			return;
		}
		// Headers
		final headers = data.first.keys.toList();
		final csvRows = <String>[];
		csvRows.add(headers.map(_escapeCsv).join(','));
		for (final row in data) {
			csvRows.add(headers.map((h) => _escapeCsv(_stringify(row[h]))).join(','));
		}
		final csvContent = csvRows.join('\n');
		final blob = html.Blob([utf8.encode(csvContent)], 'text/csv');
		final url = html.Url.createObjectUrlFromBlob(blob);
		html.AnchorElement(href: url)
			..download = '${tableName}.csv'
			..click();
		html.Url.revokeObjectUrl(url);
	}

	String _escapeCsv(String input) {
		final needsQuotes = input.contains(',') || input.contains('\n') || input.contains('"');
		var out = input.replaceAll('"', '""');
		return needsQuotes ? '"' + out + '"' : out;
	}

	String _stringify(dynamic value) {
		if (value == null) return '';
		if (value is String) return value;
		return jsonEncode(value);
	}

	void _computeAggregations() {
		// Users by gebruiker tipe
		final Map<String, int> gebruikersByTipeId = {};
		for (final g in gebruikers) {
			final id = g['gebr_tipe_id'] as String?;
			if (id != null) {
				gebruikersByTipeId[id] = (gebruikersByTipeId[id] ?? 0) + 1;
			}
		}
		userCountsByGebruikerTipe = gebruikersByTipeId.entries.map((e) {
			final tipe = gebruikerTipes.firstWhere(
				(t) => t['gebr_tipe_id'] == e.key,
				orElse: () => const {},
			);
			final label = (tipe['gebr_tipe_naam'] as String?) ?? 'Onbekend';
			return _LabeledCount(label: label, count: e.value);
		}).toList()
			..sort((a, b) => b.count.compareTo(a.count));

		// Users by admin tipe
		final Map<String, int> gebruikersByAdminTipeId = {};
		for (final g in gebruikers) {
			final id = g['admin_tipe_id'] as String?;
			if (id != null) {
				gebruikersByAdminTipeId[id] = (gebruikersByAdminTipeId[id] ?? 0) + 1;
			}
		}
		userCountsByAdminTipe = gebruikersByAdminTipeId.entries.map((e) {
			final tipe = adminTipes.firstWhere(
				(t) => t['admin_tipe_id'] == e.key,
				orElse: () => const {},
			);
			final label = (tipe['admin_tipe_naam'] as String?) ?? 'Onbekend';
			return _LabeledCount(label: label, count: e.value);
		}).toList()
			..sort((a, b) => b.count.compareTo(a.count));

		// Orders by campus
		final Map<String, int> ordersByKampusId = {};
		for (final b in bestellings) {
			final id = b['kampus_id'] as String?;
			if (id != null) {
				ordersByKampusId[id] = (ordersByKampusId[id] ?? 0) + 1;
			}
		}
		orderCountsByKampus = ordersByKampusId.entries.map((e) {
			final kampus = kampusse.firstWhere(
				(k) => k['kampus_id'] == e.key,
				orElse: () => const {},
			);
			final label = (kampus['kampus_naam'] as String?) ?? 'Onbekend';
			return _LabeledCount(label: label, count: e.value);
		}).toList()
			..sort((a, b) => b.count.compareTo(a.count));

		// Top items with feedback (order-level feedback mapped to items)
		final Map<String, int> itemCounts = {};
		final Map<String, Set<String>> itemFeedbackLabels = {};
		for (final item in bestellingItems) {
			final kos = item['kos_item'] as Map<String, dynamic>?;
			if (kos == null) continue;
			final itemName = (kos['kos_item_naam'] as String?) ?? 'Onbekend';
			final bestId = (item['best_id'] as String?);
			final quantity = item['item_hoev'] as int? ?? 1;
			itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
			if (bestId != null) {
				final feedbackForOrder = bestellingTerugvoer.where((bt) => bt['best_id'] == bestId);
				for (final bt in feedbackForOrder) {
					final tv = bt['terugvoer'] as Map<String, dynamic>?;
					final label = tv != null ? (tv['terug_naam'] as String? ?? 'Terugvoer') : 'Terugvoer';
					(itemFeedbackLabels[itemName] ??= <String>{}).add(label);
				}
			}
		}
		final sorted = itemCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
		topItemCountsWithFeedback = sorted.take(10).map((e) {
			final labels = (itemFeedbackLabels[e.key] ?? const <String>{}).toList()..sort();
			return _TopItem(name: e.key, quantity: e.value, extraLabel: labels.isEmpty ? null : labels.join(', '));
		}).toList();
	}

	List<_KPI> _getKPIs(BuildContext context) {
		return [
			_KPI('Totale Verkope', 'R ${totalSales.toStringAsFixed(2)}', 
				Icons.payments_outlined, Theme.of(context).colorScheme.primary),
			_KPI('Bestellings', '$totalOrders', 
				Icons.receipt_long_outlined, Colors.blue),
			_KPI('Gem. Bestelwaarde', 'R ${avgOrderValue.toStringAsFixed(2)}', 
				Icons.attach_money_outlined, Colors.green),
			_KPI('Nuwe Gebruikers', '$newUsers', 
				Icons.group_outlined, Colors.orange),
		];
	}

	@override
	Widget build(BuildContext context) {
		if (isLoading) {
			return const Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						CircularProgressIndicator(),
						SizedBox(height: 16),
						Text('Laai verslae data...'),
					],
				),
			);
		}

		if (errorMessage != null) {
			return Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						const Icon(Icons.error_outline, size: 64, color: Colors.red),
						const SizedBox(height: 16),
						Text('Fout met laai van data:', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 8),
						Text(errorMessage!, textAlign: TextAlign.center),
						const SizedBox(height: 16),
						ElevatedButton(
							onPressed: _loadData,
							child: const Text('Probeer Weer'),
						),
					],
				),
			);
		}

		final kpis = _getKPIs(context);

		return SingleChildScrollView(
			padding: const EdgeInsets.all(24),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					// Header with refresh button
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text('Verslae Dashboard', style: Theme.of(context).textTheme.headlineMedium),
							Row(children: [
								TextButton.icon(
									onPressed: isExporting ? null : _exportAllTablesToCsv,
									icon: isExporting
										? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
										: const Icon(Icons.download_outlined),
									label: const Text('Exporteer CSVs'),
								),
								const SizedBox(width: 8),
								IconButton(
									onPressed: _loadData,
									icon: const Icon(Icons.refresh),
									tooltip: 'Verfris Data',
								),
							]),
						],
					),
					const SizedBox(height: 24),

					// KPI Cards
					LayoutBuilder(builder: (context, constraints) {
						final int cols = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
						return GridView.count(
							shrinkWrap: true,
							physics: const NeverScrollableScrollPhysics(),
							crossAxisCount: cols,
							mainAxisSpacing: 16,
							crossAxisSpacing: 16,
						childAspectRatio: 3.0,
							children: kpis.map((k) => _kpiCard(context, k)).toList(),
						);
					}),

					const SizedBox(height: 24),

					// Charts Row
					LayoutBuilder(builder: (context, constraints) {
						if (constraints.maxWidth > 1200) {
							// Two columns for larger screens
							return Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Expanded(
										child: _buildSalesChart(context),
									),
									const SizedBox(width: 16),
									Expanded(
										child: _buildOrderStatusChart(context),
									),
								],
							);
						} else {
							// Single column for smaller screens
							return Column(
								children: [
									_buildSalesChart(context),
									const SizedBox(height: 24),
									_buildOrderStatusChart(context),
								],
							);
						}
					}),

					const SizedBox(height: 24),

					// Top Items Chart
					_buildTopItemsChart(context),
					const SizedBox(height: 24),
					
					// Users by types
					_buildUsersByTypeCharts(context),
					const SizedBox(height: 24),
					
					// Orders per campus
					_buildOrdersByCampusChart(context),
				],
			),
		);
	}

  //TODO: kyk duer die db, en probeer uitvind watter grafieke en statistieke useful sal wees vir 'n admin.
  //TODO: laat die data as 'n csv file geexporteer kan word.

	Widget _kpiCard(BuildContext context, _KPI k) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Row(children: <Widget>[
					Container(width: 40, height: 40, decoration: BoxDecoration(color: k.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(k.icon, color: k.color)),
					const SizedBox(width: 12),
					Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
						Text(k.title, style: Theme.of(context).textTheme.titleSmall),
						const SizedBox(height: 6),
						Text(k.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: k.color)),
					])),
				]),
			),
		);
	}

	Widget _buildSalesChart(BuildContext context) {
		final salesData = _getSalesData();
		
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Text('Verkope – Laaste 7 dae', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 12),
						Container(
							height: 300,
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: Colors.grey.shade300),
							),
							child: salesData.isNotEmpty
								? LineChart(
									LineChartData(
										gridData: FlGridData(show: true),
										titlesData: FlTitlesData(
											leftTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													reservedSize: 40,
													getTitlesWidget: (value, meta) {
														return Text('R${value.toInt()}');
													},
												),
											),
											bottomTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													getTitlesWidget: (value, meta) {
														final index = value.toInt();
														if (index >= 0 && index < salesData.length) {
															return Text(salesData[index].day);
														}
														return const Text('');
													},
												),
											),
											topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
											rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
										),
										minY: 0,
										borderData: FlBorderData(show: true),
										lineBarsData: [
											LineChartBarData(
												spots: salesData.asMap().entries.map((e) {
													return FlSpot(e.key.toDouble(), e.value.amount);
												}).toList(),
												isCurved: false,
												color: Theme.of(context).primaryColor,
												barWidth: 3,
												dotData: FlDotData(show: true),
												belowBarData: BarAreaData(
													show: true,
													color: Theme.of(context).primaryColor.withOpacity(0.1),
												),
											),
										],
									),
								)
								: const Center(
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Icon(Icons.bar_chart, size: 48, color: Colors.grey),
											SizedBox(height: 8),
											Text('Geen data beskikbaar', style: TextStyle(color: Colors.grey)),
										],
									),
								),
						),
					],
				),
			),
		);
	}

	Widget _buildOrderStatusChart(BuildContext context) {
		final statusData = _getOrderStatusData();
		
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Text('Bestelling Status', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 12),
						Container(
							height: 300,
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: Colors.grey.shade300),
							),
							child: statusData.isNotEmpty
								? PieChart(
									PieChartData(
										sections: statusData.map((data) {
											return PieChartSectionData(
												color: data.color,
												value: data.value,
												title: '${data.value.toInt()}',
												radius: 80,
												titleStyle: const TextStyle(
													fontSize: 12,
													fontWeight: FontWeight.bold,
													color: Colors.white,
												),
											);
										}).toList(),
										sectionsSpace: 2,
										centerSpaceRadius: 40,
									),
								)
								: const Center(
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Icon(Icons.pie_chart, size: 48, color: Colors.grey),
											SizedBox(height: 8),
											Text('Geen data beskikbaar', style: TextStyle(color: Colors.grey)),
										],
									),
								),
						),
						if (statusData.isNotEmpty) ...[
							const SizedBox(height: 12),
							Wrap(
								spacing: 8,
								children: statusData.map((data) {
									return Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Container(
												width: 12,
												height: 12,
												decoration: BoxDecoration(
													color: data.color,
													shape: BoxShape.circle,
												),
											),
											const SizedBox(width: 4),
											Text(data.label, style: const TextStyle(fontSize: 12)),
										],
									);
								}).toList(),
							),
						],
					],
				),
			),
		);
	}

	Widget _buildTopItemsChart(BuildContext context) {
		final topItems = topItemCountsWithFeedback.isNotEmpty ? topItemCountsWithFeedback : _getTopItems();
		
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Text('Top Verkoper Items', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 12),
						Container(
							height: 400,
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: Colors.grey.shade300),
							),
							child: topItems.isNotEmpty
								? BarChart(
									BarChartData(
										alignment: BarChartAlignment.spaceAround,
										maxY: topItems.isNotEmpty ? topItems.first.quantity * 1.2 : 10,
										barTouchData: BarTouchData(enabled: true),
										titlesData: FlTitlesData(
											leftTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													reservedSize: 40,
													getTitlesWidget: (value, meta) {
														return Text(value.toInt().toString());
													},
												),
											),
											bottomTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
									getTitlesWidget: (value, meta) {
														final index = value.toInt();
														if (index >= 0 && index < topItems.length) {
											return Transform.rotate(
												angle: -0.8,
												child: Padding(
													padding: const EdgeInsets.only(top: 16),
													child: Text(
														topItems[index].name,
														style: const TextStyle(fontSize: 10),
														overflow: TextOverflow.visible,
													),
												),
											);
														}
														return const Text('');
													},
												),
											),
											topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
											rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
										),
										borderData: FlBorderData(show: true),
										barGroups: topItems.asMap().entries.map((e) {
											return BarChartGroupData(
												x: e.key,
												barRods: [
													BarChartRodData(
														toY: e.value.quantity.toDouble(),
														color: Colors.blue.withOpacity(0.7),
														width: 20,
														borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
													),
												],
											);
										}).toList(),
									),
								)
								: const Center(
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											Icon(Icons.trending_up, size: 48, color: Colors.grey),
											SizedBox(height: 8),
											Text('Geen data beskikbaar', style: TextStyle(color: Colors.grey)),
										],
									),
								),
						),
					],
				),
			),
		);
	}

	Widget _buildUsersByTypeCharts(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text('Gebruikers per tipe', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 12),
						SizedBox(
							height: 300,
							child: Row(
								children: [
									Expanded(child: _simplePie(userCountsByGebruikerTipe, 'Gebruiker Tipes')),
									const SizedBox(width: 12),
									Expanded(child: _simplePie(userCountsByAdminTipe, 'Admin Tipes')),
								],
							),
						),
					],
				),
			),
		);
	}

	Widget _buildOrdersByCampusChart(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text('Bestellings per kampus', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 12),
						SizedBox(
							height: 320,
							child: orderCountsByKampus.isEmpty
								? const Center(child: Text('Geen data'))
								: BarChart(
									BarChartData(
										alignment: BarChartAlignment.spaceAround,
										maxY: orderCountsByKampus.first.count * 1.2,
										titlesData: FlTitlesData(
											leftTitles: AxisTitles(
												sideTitles: SideTitles(showTitles: true, reservedSize: 40),
											),
											bottomTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													getTitlesWidget: (value, meta) {
														final index = value.toInt();
														if (index >= 0 && index < orderCountsByKampus.length) {
															return Padding(
																padding: const EdgeInsets.only(top: 8),
																child: Text(orderCountsByKampus[index].label, style: const TextStyle(fontSize: 10)),
															);
														}
														return const Text('');
													},
												),
											),
										),
										barGroups: orderCountsByKampus.asMap().entries.map((e) {
											return BarChartGroupData(
												x: e.key,
												barRods: [
													BarChartRodData(
														toY: e.value.count.toDouble(),
														color: Colors.teal,
														width: 20,
														borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
														rodStackItems: const [],
														borderSide: BorderSide.none,
													),
												],
												showingTooltipIndicators: const [],
											);
										}).toList(),
									),
								),
						),
					],
				),
			),
		);
	}

	Widget _simplePie(List<_LabeledCount> data, String title) {
		if (data.isEmpty) return const Center(child: Text('Geen data'));
		final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.indigo];
		return Column(
			children: [
				Expanded(
					child: PieChart(
						PieChartData(
							sections: data.asMap().entries.map((e) {
								final color = colors[e.key % colors.length];
								return PieChartSectionData(
									color: color,
									value: e.value.count.toDouble(),
									title: '${e.value.count}',
									radius: 70,
									titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
								);
							}).toList(),
							sectionsSpace: 2,
							centerSpaceRadius: 40,
						),
					),
				),
				const SizedBox(height: 8),
				Wrap(
					spacing: 8,
					runSpacing: 4,
					children: data.asMap().entries.map((e) {
						final color = colors[e.key % colors.length];
						return Row(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
								const SizedBox(width: 4),
								Text(e.value.label, style: const TextStyle(fontSize: 12)),
							],
						);
					}).toList(),
				),
			],
		);
	}

	// Data processing methods
	List<_SalesData> _getSalesData() {
		final now = DateTime.now();
		final salesData = <_SalesData>[];
		
		for (int i = 6; i >= 0; i--) {
			final date = now.subtract(Duration(days: i));
			final dayName = _getDayName(date.weekday);
			
			// Calculate sales for this day
			double daySales = 0.0;
			for (final order in bestellings) {
				final orderDate = DateTime.tryParse(order['best_geskep_datum'] ?? '');
				if (orderDate != null && 
					orderDate.year == date.year &&
					orderDate.month == date.month &&
					orderDate.day == date.day) {
					daySales += (order['best_volledige_prys'] as num? ?? 0.0).toDouble();
				}
			}
			
			salesData.add(_SalesData(day: dayName, amount: daySales));
		}
		
		return salesData;
	}

	List<_StatusData> _getOrderStatusData() {
		final statusCounts = <String, int>{};
		
		// Count statuses from bestelling items
		for (final item in bestellingItems) {
			String status = 'Wag vir afhaal'; // Default status
			
			// Check if item has status information
			if (item['best_kos_item_statusse'] != null && 
				item['best_kos_item_statusse'] is List &&
				(item['best_kos_item_statusse'] as List).isNotEmpty) {
				final statuses = item['best_kos_item_statusse'] as List;
				final latestStatus = statuses.last;
				if (latestStatus['kos_item_statusse'] != null) {
					status = latestStatus['kos_item_statusse']['kos_stat_naam'] ?? 'Wag vir afhaal';
				}
			}
			
			statusCounts[status] = (statusCounts[status] ?? 0) + 1;
		}
		
		final colors = [Colors.orange, Colors.blue, Colors.green, Colors.red, Colors.purple];
		return statusCounts.entries.map((entry) {
			final colorIndex = statusCounts.keys.toList().indexOf(entry.key) % colors.length;
			return _StatusData(
				label: entry.key,
				value: entry.value.toDouble(),
				color: colors[colorIndex],
			);
		}).toList();
	}

	List<_TopItem> _getTopItems() {
		final itemCounts = <String, int>{};
		
		// Count quantities for each item
		for (final item in bestellingItems) {
			if (item['kos_item'] != null) {
				final kosItem = item['kos_item'] as Map<String, dynamic>;
				final itemName = kosItem['kos_item_naam'] ?? 'Unknown Item';
				final quantity = item['item_hoev'] as int? ?? 1;
				
				itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
			}
		}
		
		// Sort by quantity and take top 10
		final sortedItems = itemCounts.entries.toList()
			..sort((a, b) => b.value.compareTo(a.value));
		
		return sortedItems.take(10).map((entry) {
			return _TopItem(name: entry.key, quantity: entry.value);
		}).toList();
	}

	String _getDayName(int weekday) {
		const days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Sa', 'So'];
		return days[weekday - 1];
	}
}

// Helper classes
class _KPI {
	final String title;
	final String value;
	final IconData icon;
	final Color color;
	const _KPI(this.title, this.value, this.icon, this.color);
}

class _SalesData {
	final String day;
	final double amount;
	_SalesData({required this.day, required this.amount});
}

class _StatusData {
	final String label;
	final double value;
	final Color color;
	_StatusData({required this.label, required this.value, required this.color});
}

class _TopItem {
	final String name;
	final int quantity;
	final String? extraLabel;
	_TopItem({required this.name, required this.quantity, this.extraLabel});
}

class _LabeledCount {
	final String label;
	final int count;
	_LabeledCount({required this.label, required this.count});
}