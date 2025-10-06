import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class VerslaePage extends StatefulWidget {
	const VerslaePage({super.key});

	@override
	State<VerslaePage> createState() => _VerslaePageState();
}

class _VerslaePageState extends State<VerslaePage> {
	bool isLoading = true;
	String? errorMessage;
	bool isExporting = false;
	bool _isPrimaryAdmin = false;
	int selectedSalesDays = 7;
	int _topItemsLimit = 10;
	
	// UI State (Terugvoer add form)
	final TextEditingController _terugNaamController = TextEditingController();
	final TextEditingController _terugBeskrywingController = TextEditingController();
	bool isSavingTerugvoer = false;

	// UI State (Terugvoer inline edit rows)
	final Map<String, String> _editNaamById = {};
	final Map<String, String> _editBeskById = {};
	final Set<String> _savingRowIds = <String>{};
	
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
	int totalUsers = 0;
	int totalBestellingKosItems = 0;

	// Aggregations
	List<_TopItem> topItemCountsWithFeedback = const [];
	List<_LabeledCount> userCountsByGebruikerTipe = const [];
	List<_LabeledCount> userCountsByAdminTipe = const [];
	List<_LabeledCount> orderCountsByKampus = const [];
	List<_FieldStats> _numericStats = const [];

	// UI state for Kos Items vs Terugvoer aggregation mode
	String _terugvoerAggMode = 'Per Kos Item'; // or 'Per Terugvoer'

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
		'bestelling_kos_item_terugvoer',
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
		_checkIsPrimaryAdmin();
	}

	Future<void> _checkIsPrimaryAdmin() async {
		try {
			final user = Supabase.instance.client.auth.currentUser;
			if (user == null) return;
			final profile = await Supabase.instance.client
				.from('gebruikers')
				.select('''
					is_aktief,
					admin_tipe:admin_tipe_id(admin_tipe_naam)
				''')
				.eq('gebr_id', user.id)
				.maybeSingle();
			final String? adminTypeName = profile?['admin_tipe']?['admin_tipe_naam'] as String?;
			setState(() {
				_isPrimaryAdmin = (adminTypeName == 'Primary');
			});
		} catch (e) {
			// ignore errors, keep default false
		}
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
			debugPrint('Starting to load verslae data...');
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
			debugPrint('Successfully loaded all verslae data');

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
			_computeNumericStatistics();

			setState(() {
				isLoading = false;
			});
		} catch (e) {
			debugPrint('Error loading verslae data: $e');
			if (e is PostgrestException) {
				debugPrint('PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}');
			}
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
				best_kos_item_statusse!best_kos_item_statusse_best_kos_id_fkey(
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
		try {
			debugPrint('Loading bestelling terugvoer data...');
			final result = await _selectAll(
				'bestelling_kos_item_terugvoer',
				columns: '''
					*,
					terugvoer:terug_id(*),
					bestelling_kos_item!bestelling_kos_item_terugvoer_best_kos_id_fkey(
						*,
						kos_item:kos_item_id(*),
						bestelling:best_id(*)
					)
				''',
			);
			debugPrint('Successfully loaded ${result.length} bestelling terugvoer records');
			return result;
		} catch (e) {
			debugPrint('Error loading bestelling terugvoer: $e');
			if (e is PostgrestException) {
				debugPrint('PostgrestException loading bestelling terugvoer: ${e.message}, code: ${e.code}, details: ${e.details}');
			}
			rethrow;
		}
	}

	Future<List<Map<String, dynamic>>> _loadTerugvoerTipes() async {
		// Only load active terugvoer types if the schema supports terug_is_aktief
		try {
			final rows = await Supabase.instance.client
				.from('terugvoer')
				.select('*')
				.eq('terug_is_aktief', true);
			return List<Map<String, dynamic>>.from(rows);
		} catch (_) {
			// Fallback for older schemas without terug_is_aktief
			return _selectAll('terugvoer');
		}
	}

	void _calculateKPIs() {
		final cutoffDate = _cutoffDate();
		final filteredBestellingItems = _filteredBestellingItems(cutoffDate);
		
		// Calculate total sales from filtered items
		totalSales = filteredBestellingItems.fold(0.0, (sum, item) {
			final kosItem = item['kos_item'] as Map<String, dynamic>?;
			final itemPrice = (kosItem?['kos_item_koste'] as num? ?? 0.0).toDouble();
			final quantity = (item['item_hoev'] as num? ?? 1).toInt();
			return sum + (itemPrice * quantity);
		});
		
		final filteredBestellings = _filteredBestellings(cutoffDate);
		
		// Total orders (filtered by order creation date)
		totalOrders = filteredBestellings.length;
		
		// Total bestelling kos items (filtered by item date)
		totalBestellingKosItems = filteredBestellingItems.length;
		
		// Average order value
		avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;
		
		// Users filtered by created date
		totalUsers = _filteredGebruikers(cutoffDate).length;
	}

	DateTime _cutoffDate() {
		// -1 means "Alle tyd" (no cutoff)
		if (selectedSalesDays == -1) {
			return _earliestDataDate();
		}
		return DateTime.now().subtract(Duration(days: selectedSalesDays));
	}

	DateTime _earliestDataDate() {
		DateTime? earliest;

		DateTime? minDate(DateTime? a, DateTime? b) {
			if (a == null) return b;
			if (b == null) return a;
			return a.isBefore(b) ? a : b;
		}

		DateTime? parse(String? s) => s == null ? null : DateTime.tryParse(s);

		for (final o in bestellings) {
			earliest = minDate(earliest, parse(o['best_geskep_datum'] as String?));
		}
		for (final i in bestellingItems) {
			earliest = minDate(earliest, parse(i['best_datum'] as String?));
		}
		for (final g in gebruikers) {
			earliest = minDate(earliest, parse(g['gebr_geskep_datum'] as String?));
		}
		for (final bt in bestellingTerugvoer) {
			earliest = minDate(earliest, parse(bt['geskep_datum'] as String?));
		}

		return earliest ?? DateTime.fromMillisecondsSinceEpoch(0);
	}

	List<Map<String, dynamic>> _filteredBestellings(DateTime cutoff) {
		return bestellings.where((order) {
			final orderDate = DateTime.tryParse(order['best_geskep_datum'] as String? ?? '');
			return orderDate != null && orderDate.isAfter(cutoff);
		}).toList();
	}

	List<Map<String, dynamic>> _filteredBestellingItems(DateTime cutoff) {
		return bestellingItems.where((item) {
			final itemDate = DateTime.tryParse(item['best_datum'] as String? ?? '');
			return itemDate != null && itemDate.isAfter(cutoff);
		}).toList();
	}

	List<Map<String, dynamic>> _filteredGebruikers(DateTime cutoff) {
		return gebruikers.where((g) {
			final d = DateTime.tryParse(g['gebr_geskep_datum'] as String? ?? '');
			return d != null && d.isAfter(cutoff);
		}).toList();
	}

	List<Map<String, dynamic>> _filteredBestellingTerugvoer(DateTime cutoff) {
		return bestellingTerugvoer.where((bt) {
			final d = DateTime.tryParse(bt['geskep_datum'] as String? ?? '');
			return d != null && d.isAfter(cutoff);
		}).toList();
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
				} catch (e) {
					// Log tables that do not exist or fail due to RLS
					debugPrint('Failed to export table $table: $e');
					if (e is PostgrestException) {
						debugPrint('PostgrestException for table $table: ${e.message}, code: ${e.code}');
					}
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

	Future<void> _addTerugvoer() async {
		final String naam = _terugNaamController.text.trim();
		final String beskrywing = _terugBeskrywingController.text.trim();
		if (naam.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Voer asseblief \"Naam\" in')),
			);
			return;
		}
		setState(() {
			isSavingTerugvoer = true;
		});
		try {
			Map<String, dynamic> payload = {
				'terug_naam': naam,
				'terug_beskrywing': beskrywing,
			};
			// Try set active flag if present in schema
			try {
				payload['terug_is_aktief'] = true;
			} catch (_) {}
			final inserted = await Supabase.instance.client
				.from('terugvoer')
				.insert(payload)
				.select()
				.single();
			// Optimistically update local list
			setState(() {
				terugvoerTipes = List<Map<String, dynamic>>.from(terugvoerTipes)
					..add(Map<String, dynamic>.from(inserted));
				_terugNaamController.clear();
				_terugBeskrywingController.clear();
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Terugvoer bygevoeg')),
			);
		} catch (e) {
			debugPrint('Error adding terugvoer: $e');
			if (e is PostgrestException) {
				debugPrint('PostgrestException adding terugvoer: ${e.message}, code: ${e.code}, details: ${e.details}');
			}
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Kon nie terugvoer byvoeg nie: $e')),
			);
		} finally {
			if (mounted) {
				setState(() {
					isSavingTerugvoer = false;
				});
			}
		}
	}


	Future<void> _saveTerugRow(String terugId) async {
		if (_savingRowIds.contains(terugId)) return;
		final current = terugvoerTipes.firstWhere((e) => e['terug_id'] == terugId, orElse: () => const {});
		final newNaam = _editNaamById[terugId] ?? current['terug_naam'];
		final newBesk = _editBeskById[terugId] ?? current['terug_beskrywing'];
		final Map<String, dynamic> updates = {};
		if (newNaam != null && newNaam != current['terug_naam']) updates['terug_naam'] = newNaam;
		if (newBesk != null && newBesk != current['terug_beskrywing']) updates['terug_beskrywing'] = newBesk;
		if (updates.isEmpty) return;
		setState(() { _savingRowIds.add(terugId); });
		try {
			await Supabase.instance.client
				.from('terugvoer')
				.update(updates)
				.eq('terug_id', terugId);
			final list = await _loadTerugvoerTipes();
			setState(() {
				terugvoerTipes = list;
				_editNaamById.remove(terugId);
				_editBeskById.remove(terugId);
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Veranderinge gestoor')),
			);
		} catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Kon nie veranderinge stoor nie: $e')),
			);
		} finally {
			if (mounted) {
				setState(() { _savingRowIds.remove(terugId); });
			}
		}
	}

	Future<void> _deactivateTerugvoer(String terugId) async {
		try {
			await Supabase.instance.client
				.from('terugvoer')
				.update({'terug_is_aktief': false})
				.eq('terug_id', terugId);
			// Refresh list to only show active ones
			final list = await _loadTerugvoerTipes();
			setState(() {
				terugvoerTipes = list;
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Terugvoer gedeaktiveer')),
			);
		} catch (e) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Kon nie deaktiveer nie: $e')),
			);
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
		final cutoff = _cutoffDate();
		final filteredUsers = _filteredGebruikers(cutoff);
		final filteredOrders = _filteredBestellings(cutoff);
		final filteredItems = _filteredBestellingItems(cutoff);

		// Users by gebruiker tipe (filtered)
		final Map<String, int> gebruikersByTipeId = {};
		for (final g in filteredUsers) {
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

		// Users by admin tipe (filtered)
		final Map<String, int> gebruikersByAdminTipeId = {};
		for (final g in filteredUsers) {
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

		// Orders by campus (filtered)
		final Map<String, int> ordersByKampusId = {};
		for (final b in filteredOrders) {
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

		// Top items with feedback (item-level feedback through linking table)
		final Map<String, int> itemCounts = {};
		final Map<String, Set<String>> itemFeedbackLabels = {};
		
		// Index feedback by best_kos_id (bestelling_kos_item ID)
		final Map<String, List<Map<String, dynamic>>> feedbackByBestKosId = {};
		for (final bt in bestellingTerugvoer) {
			final bestKosId = bt['best_kos_id'] as String?;
			if (bestKosId == null) continue;
			(feedbackByBestKosId[bestKosId] ??= <Map<String, dynamic>>[]).add(bt);
		}
		
		for (final item in filteredItems) {
			final kos = item['kos_item'] as Map<String, dynamic>?;
			if (kos == null) continue;
			final itemName = (kos['kos_item_naam'] as String?) ?? 'Onbekend';
			final bestKosId = (item['best_kos_id'] as String?);
			final quantity = item['item_hoev'] as int? ?? 1;
			itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
			
			if (bestKosId != null) {
				final feedbackForItem = feedbackByBestKosId[bestKosId] ?? <Map<String, dynamic>>[];
				for (final bt in feedbackForItem) {
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

	void _computeNumericStatistics() {
		final List<_FieldStats> out = [];
		void collect(String datasetName, List<Map<String, dynamic>> rows) {
			final Map<String, List<double>> valuesByField = {};
			for (final row in rows) {
				row.forEach((key, value) {
					if (value is num) {
						(valuesByField[key] ??= <double>[]).add(value.toDouble());
					}
				});
			}
			valuesByField.forEach((field, values) {
				values.sort();
				final int count = values.length;
				final double sum = values.fold(0.0, (s, v) => s + v);
				final double mean = count == 0 ? 0.0 : sum / count;
				final double median = count == 0
					? 0.0
					: (count % 2 == 1)
						? values[count ~/ 2]
						: (values[count ~/ 2 - 1] + values[count ~/ 2]) / 2.0;
				// mode
				final Map<double, int> freq = {};
				for (final v in values) {
					freq[v] = (freq[v] ?? 0) + 1;
				}
				double mode = 0.0;
				int modeCount = 0;
				for (final e in freq.entries) {
					if (e.value > modeCount || (e.value == modeCount && e.key < mode)) {
						modeCount = e.value;
						mode = e.key;
					}
				}
				// std dev (population)
				final double variance = count == 0
					? 0.0
					: values.fold(0.0, (s, v) => s + math.pow(v - mean, 2).toDouble()) / count;
				final double stdDev = math.sqrt(variance);
				final double minV = count == 0 ? 0.0 : values.first;
				final double maxV = count == 0 ? 0.0 : values.last;
				out.add(_FieldStats(
					dataset: datasetName,
					field: field,
					count: count,
					sum: sum,
					mean: mean,
					median: median,
					mode: mode,
					stdDev: stdDev,
					min: minV,
					max: maxV,
				));
			});
		}
		collect('bestelling', bestellings);
		collect('bestelling_kos_item', bestellingItems);
		collect('gebruikers', gebruikers);
		collect('kos_item', kosItems);
		collect('gebruiker_tipes', gebruikerTipes);
		collect('admin_tipes', adminTipes);
		collect('kampus', kampusse);
		collect('bestelling_kos_item_terugvoer', bestellingTerugvoer);
		collect('terugvoer', terugvoerTipes);
		// Order by dataset then field for stable display
		out.sort((a, b) => a.dataset != b.dataset ? a.dataset.compareTo(b.dataset) : a.field.compareTo(b.field));
		setState(() {
			_numericStats = out;
		});
	}

	List<_KPI> _getKPIs(BuildContext context) {
		return [
			_KPI('Totale Verkope', 'R ${totalSales.toStringAsFixed(2)}', 
				Icons.payments_outlined, Theme.of(context).colorScheme.primary),
			_KPI('Bestellings', '$totalOrders', 
				Icons.receipt_long_outlined, Colors.blue),
			_KPI('Bestelde Kos Items', '$totalBestellingKosItems', 
				Icons.restaurant_outlined, Colors.purple),
			_KPI('Gem. Bestelwaarde', 'R ${avgOrderValue.toStringAsFixed(2)}', 
				Icons.attach_money_outlined, Colors.green),
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

		return Scaffold(
			appBar: AppBar(
				title: const Text('Verslae Dashboard'),
				toolbarHeight: 64,
				actions: [
					Row(children: [
						Text('Tydperk', style: Theme.of(context).textTheme.titleSmall),
						const SizedBox(width: 8),
						DropdownButton<int>(
							value: selectedSalesDays,
						items: const [-1, 7, 14, 30]
							.map((d) => DropdownMenuItem<int>(
								value: d,
								child: Text(d == -1 ? 'Alle tyd' : 'Laaste ' + d.toString() + ' dae'),
							))
								.toList(),
							onChanged: (v) {
								if (v == null) return;
								setState(() {
									selectedSalesDays = v;
									_calculateKPIs();
									_computeAggregations();
								});
							},
						),
						const SizedBox(width: 16),
						if (_isPrimaryAdmin)
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
						const SizedBox(width: 8),
					])
				],
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.all(24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[

					// KPI Cards (responsive, no overflow)
					LayoutBuilder(builder: (context, constraints) {
						final int cols = constraints.maxWidth > 1400 ? 5 : constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
						final double spacing = 16;
						final double totalSpacing = spacing * (cols - 1);
						final double itemWidth = (constraints.maxWidth - totalSpacing) / cols;
						return Wrap(
							spacing: spacing,
							runSpacing: spacing,
							children: kpis.map((k) => SizedBox(width: itemWidth, child: _kpiCard(context, k))).toList(),
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
					// Kos Items vs Terugvoer (stacked)
					_buildKosItemTerugvoerChart(context),
					
					// Users by types
					_buildUsersByTypeCharts(context),
					const SizedBox(height: 24),
					// Numerical statistics removed
					
					// Orders per campus
					_buildOrdersByCampusChart(context),
					const SizedBox(height: 24),
					// Terugvoer: view and add
					_buildTerugvoerSection(context),
				],
				),
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
		final salesData = _getSalesData(selectedSalesDays);
		
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
						Text(
							selectedSalesDays == -1
								? 'Verkope – Alle tyd'
								: 'Verkope – Laaste ' + selectedSalesDays.toString() + ' dae',
							style: Theme.of(context).textTheme.titleMedium,
						),
					const SizedBox(height: 12),
					Container(
							height: 300,
							decoration: BoxDecoration(
								borderRadius: BorderRadius.circular(12),
								border: Border.all(color: Colors.grey.shade300),
							),
							child: salesData.isNotEmpty
								? Column(
									children: [
										// Cost chart
										SizedBox(
											height: 140,
											child: LineChart(_getCostChartData(context, salesData)),
										),
										const SizedBox(height: 8),
										// Item count chart
										SizedBox(
											height: 140,
											child: LineChart(_getItemCountChartData(context, salesData)),
										),
									],
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
		final allTopItems = topItemCountsWithFeedback.isNotEmpty ? topItemCountsWithFeedback : _getTopItems();
		final topItems = allTopItems.take(_topItemsLimit).toList();
		
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text('Top Verkoper Items', style: Theme.of(context).textTheme.titleMedium),
								Row(children: [
									Text('Top', style: Theme.of(context).textTheme.titleSmall),
									const SizedBox(width: 8),
									DropdownButton<int>(
										value: _topItemsLimit,
										items: const [5, 10, 15, 20]
											.map((n) => DropdownMenuItem<int>(value: n, child: Text('Top ' + n.toString())))
											.toList(),
										onChanged: (v) {
											if (v == null) return;
											setState(() {
												_topItemsLimit = v;
											});
										},
									),
								])
							],
						),
						const SizedBox(height: 12),
						Container(
							height: 360,
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
												reservedSize: 140,
												getTitlesWidget: (value, meta) {
													final index = value.toInt();
													if (index >= 0 && index < topItems.length) {
														return SideTitleWidget(
															axisSide: meta.axisSide,
															space: 16,
															child: Transform.translate(
																offset: const Offset(0, 36),
																child: Transform.rotate(
																	angle: -1.57,
																	child: Text(topItems[index].name, style: const TextStyle(fontSize: 10)),
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
														width: 10,
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
						const SizedBox(height: 8),
						Text('Likes vir Top Items', style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 8),
						SizedBox(
							height: 260,
							child: Builder(
								builder: (context) {
									final Map<String, int> likesByItem = {};
									for (final item in bestellingItems) {
										final kos = item['kos_item'] as Map<String, dynamic>?;
										if (kos == null) continue;
										final name = (kos['kos_item_naam'] as String?) ?? 'Onbekend';
										final liked = item['best_kos_is_liked'] == true;
										if (liked) {
											likesByItem[name] = (likesByItem[name] ?? 0) + 1;
										}
									}

									final likesInTopOrder = topItems.map((t) => likesByItem[t.name] ?? 0).toList();
									final maxLikes = likesInTopOrder.isEmpty ? 0 : likesInTopOrder.reduce((a, b) => a > b ? a : b);

									if (topItems.isEmpty) {
										return const Center(child: Text('Geen data beskikbaar'));
									}

									return BarChart(
										BarChartData(
											alignment: BarChartAlignment.spaceAround,
											maxY: (maxLikes * 1.2).clamp(5, double.infinity).toDouble(),
											gridData: FlGridData(
												show: true,
												drawVerticalLine: false,
												horizontalInterval: () {
													final m = maxLikes;
													if (m <= 10) return 1.0;
													if (m <= 20) return 2.0;
													if (m <= 50) return 5.0;
													if (m <= 100) return 10.0;
													if (m <= 200) return 20.0;
													return 50.0;
												}(),
											),
											titlesData: FlTitlesData(
												leftTitles: AxisTitles(
													sideTitles: SideTitles(
														showTitles: true,
														reservedSize: 40,
														interval: () {
															final m = maxLikes;
															if (m <= 10) return 1.0;
															if (m <= 20) return 2.0;
															if (m <= 50) return 5.0;
															if (m <= 100) return 10.0;
															if (m <= 200) return 20.0;
															return 50.0;
														}(),
														getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
													),
												),
												bottomTitles: AxisTitles(
													sideTitles: SideTitles(
														showTitles: true,
														reservedSize: 140,
														getTitlesWidget: (value, meta) {
															final index = value.toInt();
															if (index >= 0 && index < topItems.length) {
																return SideTitleWidget(
																	axisSide: meta.axisSide,
																	space: 16,
																	child: Transform.translate(
																		offset: const Offset(0, 36),
																		child: Transform.rotate(
																			angle: -1.57,
																			child: Text(topItems[index].name, style: const TextStyle(fontSize: 10)),
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
											barGroups: likesInTopOrder.asMap().entries.map((e) => BarChartGroupData(
												x: e.key,
												barRods: [
													BarChartRodData(
														toY: e.value.toDouble(),
														color: Colors.pinkAccent.withOpacity(0.8),
														width: 10,
														borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
													),
												],
											)).toList(),
										),
									);
								},
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
												sideTitles: SideTitles(
													showTitles: true,
													reservedSize: 40,
													interval: 1.0, // Whole number intervals
													getTitlesWidget: (value, meta) {
														if (value < 0) return const Text('');
														final wholeNumber = value.toInt();
														if (wholeNumber != value) return const Text(''); // Only show whole numbers
														return Text(wholeNumber.toString(), style: const TextStyle(fontSize: 10));
													},
												),
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
											topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
											rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

	Widget _buildTerugvoerSection(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text('Terugvoer (beskikbare tipes)', style: Theme.of(context).textTheme.titleMedium),
								IconButton(
									onPressed: () async {
										final list = await _loadTerugvoerTipes();
										setState(() {
											terugvoerTipes = list;
										});
									},
									icon: const Icon(Icons.refresh),
									tooltip: 'Herlaai Terugvoer',
								),
							],
						),
						const SizedBox(height: 12),
						LayoutBuilder(
							builder: (context, constraints) {
								final double total = constraints.maxWidth;
								const double actionsWidth = 200.0;
								const double spacing = 12.0;
								final double usable = (total - actionsWidth - spacing).clamp(200.0, double.infinity);
								final double nameWidth = (usable * 0.35).clamp(160.0, 360.0);
								final double descWidth = (usable * 0.65).clamp(240.0, 800.0);
								return DataTable(
									columnSpacing: spacing,
									dataRowMinHeight: 96,
									dataRowMaxHeight: 180,
									columns: const [
										DataColumn(label: Text('Naam')),
										DataColumn(label: Text('Beskrywing')),
										DataColumn(label: Text('Aksies')),
									],
									rows: (terugvoerTipes..sort((a, b) => (a['terug_naam'] ?? '').toString().compareTo((b['terug_naam'] ?? '').toString())))
										.map((tv) => DataRow(cells: [
											DataCell(
												SizedBox(
													width: nameWidth,
													child: TextFormField(
														initialValue: _editNaamById[tv['terug_id']] ?? (tv['terug_naam']?.toString() ?? ''),
														decoration: const InputDecoration(border: OutlineInputBorder()),
														onChanged: (v) { setState(() { _editNaamById[tv['terug_id'] as String] = v; }); },
													),
												),
											),
											DataCell(
												SizedBox(
													width: descWidth,
													child: TextFormField(
														initialValue: _editBeskById[tv['terug_id']] ?? (tv['terug_beskrywing']?.toString() ?? ''),
														minLines: 4,
														maxLines: 8,
														decoration: const InputDecoration(border: OutlineInputBorder()),
														onChanged: (v) { setState(() { _editBeskById[tv['terug_id'] as String] = v; }); },
													),
												),
											),
											DataCell(SizedBox(
												width: actionsWidth,
												child: Row(
													children: [
														TextButton.icon(
															onPressed: _savingRowIds.contains(tv['terug_id']) ? null : () => _saveTerugRow(tv['terug_id'] as String),
															icon: _savingRowIds.contains(tv['terug_id'])
																? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
																: const Icon(Icons.save_outlined),
															label: const Text('Stoor'),
														),
														const SizedBox(width: 8),
														IconButton(
															icon: const Icon(Icons.delete_outline),
															onPressed: () => _deactivateTerugvoer(tv['terug_id'] as String),
															tooltip: 'Deaktiveer',
														),
													],
												),
											)),
									]))
										.toList(),
								);
							},
						),
						const SizedBox(height: 16),
						Divider(color: Colors.grey.shade300),
						const SizedBox(height: 16),
						Text('Voeg nuwe Terugvoer by', style: Theme.of(context).textTheme.titleSmall),
						const SizedBox(height: 8),
						LayoutBuilder(builder: (context, constraints) {
							final bool wide = constraints.maxWidth > 800;
							final children = <Widget>[
								Expanded(
									child: TextField(
										controller: _terugNaamController,
										decoration: const InputDecoration(
											labelText: 'Naam',
											border: OutlineInputBorder(),
										),
									),
								),
								const SizedBox(width: 12, height: 12),
								Expanded(
									flex: 2,
									child: TextField(
										controller: _terugBeskrywingController,
										minLines: 1,
										maxLines: 3,
										decoration: const InputDecoration(
											labelText: 'Beskrywing (opsioneel)',
											border: OutlineInputBorder(),
										),
									),
								),
								const SizedBox(width: 12, height: 12),
								SizedBox(
									height: 48,
									child: ElevatedButton.icon(
										onPressed: isSavingTerugvoer ? null : _addTerugvoer,
										icon: isSavingTerugvoer
											? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
											: const Icon(Icons.add),
										label: const Text('Voeg by'),
									),
								),
							];
							return wide
								? Row(children: children)
								: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
						}),
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
List<_SalesData> _getSalesData(int numDays) {
	final now = DateTime.now();
	final salesData = <_SalesData>[];

	DateTime startDate;
	int daysToShow;
	if (numDays == -1) {
		// From earliest date to now
		startDate = _earliestDataDate();
		daysToShow = now.difference(startDate).inDays + 1;
	} else {
		startDate = now.subtract(Duration(days: numDays - 1));
		daysToShow = numDays;
	}

	for (int i = 0; i < daysToShow; i++) {
		final date = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
		final label = '${date.day}/${date.month}';
		double daySales = 0.0;
		int dayCount = 0;
		for (final order in bestellings) {
			final orderDate = DateTime.tryParse(order['best_geskep_datum'] ?? '');
			if (orderDate != null &&
				orderDate.year == date.year &&
				orderDate.month == date.month &&
				orderDate.day == date.day) {
				daySales += (order['best_volledige_prys'] as num? ?? 0.0).toDouble();
			}
		}
		for (final item in bestellingItems) {
			final Map<String, dynamic>? best = item['bestelling'] as Map<String, dynamic>?;
			final String? bestDateStr = best != null ? best['best_geskep_datum'] as String? : null;
			final orderDate = bestDateStr != null ? DateTime.tryParse(bestDateStr) : null;
			if (orderDate != null &&
				orderDate.year == date.year &&
				orderDate.month == date.month &&
				orderDate.day == date.day) {
				dayCount += (item['item_hoev'] as int? ?? 1);
			}
		}
		salesData.add(_SalesData(day: label, amount: daySales, count: dayCount));
	}
	return salesData;
}

	LineChartData _getCostChartData(BuildContext context, List<_SalesData> data) {
		final maxAmount = data.fold<double>(0.0, (m, e) => e.amount > m ? e.amount : m);
		
		return LineChartData(
			gridData: const FlGridData(show: true), // Show grid for cost chart
			titlesData: FlTitlesData(
				leftTitles: AxisTitles(
					axisNameWidget: const Text('Totale Verkope (R)'),
					axisNameSize: 24,
					sideTitles: SideTitles(
						showTitles: true,
						reservedSize: 60,
						getTitlesWidget: (value, meta) {
							if (value < 0) return const Text('');
							return Text('R${value.toInt()}', style: const TextStyle(fontSize: 10));
						},
						),
				),
				bottomTitles: AxisTitles(
					sideTitles: SideTitles(
						showTitles: true,
						interval: 1.0, // Show label once per day
						getTitlesWidget: (value, meta) {
							final index = value.toInt();
							if (index >= 0 && index < data.length) {
								return Padding(
									padding: const EdgeInsets.only(top: 4),
									child: Text(data[index].day, style: const TextStyle(fontSize: 10)),
								);
							}
							return const Text('');
						},
					),
				),
				topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
				rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
			),
			minY: 0,
			maxY: maxAmount * 1.1,
			borderData: FlBorderData(show: true),
			lineBarsData: [
				LineChartBarData(
					spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
					isCurved: false,
					color: Colors.green,
					barWidth: 3,
					dotData: FlDotData(show: true),
					belowBarData: BarAreaData(
						show: true,
						color: Colors.green.withOpacity(0.1),
					),
				),
			],
		);
	}

	LineChartData _getItemCountChartData(BuildContext context, List<_SalesData> data) {
		final maxCount = data.fold<int>(0, (m, e) => e.count > m ? e.count : m);
		
		// Dynamic interval based on data range
		double yLabelInterval;
		double gridInterval;
		if (maxCount <= 10) {
			yLabelInterval = 1.0;
			gridInterval = 1.0;
		} else if (maxCount <= 50) {
			yLabelInterval = 5.0;
			gridInterval = 2.5;
		} else if (maxCount <= 100) {
			yLabelInterval = 10.0;
			gridInterval = 5.0;
		} else if (maxCount <= 500) {
			yLabelInterval = 50.0;
			gridInterval = 25.0;
		} else {
			yLabelInterval = 100.0;
			gridInterval = 50.0;
		}
		
		return LineChartData(
			gridData: FlGridData(
				show: true,
				drawVerticalLine: true,
				horizontalInterval: gridInterval,
				verticalInterval: gridInterval,
			),
			titlesData: FlTitlesData(
				leftTitles: AxisTitles(
					axisNameWidget: const Text('Aantal Items'),
					axisNameSize: 24,
					sideTitles: SideTitles(
						showTitles: true,
						reservedSize: 50,
						interval: yLabelInterval,
						getTitlesWidget: (value, meta) {
							if (value < 0) return const Text('');
							final wholeNumber = value.toInt();
							if (wholeNumber != value) return const Text(''); // Only show whole numbers
							return Text(wholeNumber.toString(), style: const TextStyle(fontSize: 10));
						},
					),
				),
				bottomTitles: AxisTitles(
					sideTitles: SideTitles(
						showTitles: true,
						interval: 1.0, // Show label once per day
						getTitlesWidget: (value, meta) {
							final index = value.toInt();
							if (index >= 0 && index < data.length) {
								return Padding(
									padding: const EdgeInsets.only(top: 4),
									child: Text(data[index].day, style: const TextStyle(fontSize: 10)),
								);
							}
							return const Text('');
						},
					),
				),
				topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
				rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
			),
			minY: 0,
			maxY: maxCount > 0 ? maxCount * 1.1 : 10, // Independent scale for item counts
			borderData: FlBorderData(show: true), // Show border for independent chart
			lineBarsData: [
				LineChartBarData(
					spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
					isCurved: false,
					color: Colors.orange,
					barWidth: 3,
					dotData: FlDotData(show: true),
				),
			],
		);
	}

	List<_StatusData> _getOrderStatusData() {
		final statusCounts = <String, int>{};
		final cutoff = _cutoffDate();
		final filteredItems = _filteredBestellingItems(cutoff);
		// Count statuses from filtered bestelling items
		for (final item in filteredItems) {
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
		final cutoff = _cutoffDate();
		final filteredItems = _filteredBestellingItems(cutoff);
		// Count quantities for each item in period
		for (final item in filteredItems) {
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

    // Removed unused _getDayName helper

	Widget _buildKosItemTerugvoerChart(BuildContext context) {
		final data = _computeKosItemTerugvoerData();
		if (data.isEmpty) {
			return Card(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: const [
							Text('Kos Items vs Terugvoer'),
							SizedBox(height: 12),
							Text('Geen data beskikbaar'),
						],
					),
				),
			);
		}

		// Determine all terugvoer labels
		final Set<String> terugLabels = {};
		for (final entry in data.values) {
			terugLabels.addAll(entry.keys);
		}
		final List<String> terugList = terugLabels.toList()..sort();
		final colors = [
			Colors.blue,
			Colors.orange,
			Colors.green,
			Colors.purple,
			Colors.red,
			Colors.teal,
			Colors.indigo,
			Colors.brown,
		];

		final items = data.entries.toList();
		// Sort by total count desc and take top 10
		items.sort((a, b) {
			final ta = a.value.values.fold<int>(0, (s, v) => s + v);
			final tb = b.value.values.fold<int>(0, (s, v) => s + v);
			return tb.compareTo(ta);
		});
		final topItems = items.take(10).toList();
		final maxCount = topItems.isEmpty
			? 10
			: topItems.map((e) => e.value.values.fold<int>(0, (s, v) => s + v)).reduce((a, b) => a > b ? a : b);
		final maxY = (maxCount * 1.2).ceil().toDouble();

		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text('Kos Items vs Terugvoer', style: Theme.of(context).textTheme.titleMedium),
								Row(children: [
									Text('Aggregasie', style: Theme.of(context).textTheme.titleSmall),
									const SizedBox(width: 8),
									DropdownButton<String>(
										value: _terugvoerAggMode,
										items: const ['Per Kos Item', 'Per Terugvoer']
											.map((m) => DropdownMenuItem<String>(value: m, child: Text(m)))
											.toList(),
										onChanged: (v) {
											if (v == null) return;
											setState(() {
												_terugvoerAggMode = v;
											});
										},
									),
								])
							],
						),
						const SizedBox(height: 12),
						SizedBox(
							height: 420,
							child: _terugvoerAggMode == 'Per Kos Item' 
								? BarChart(
								BarChartData(
									alignment: BarChartAlignment.spaceBetween,
									maxY: maxY,
									minY: 0,
									gridData: FlGridData(
										show: true,
										drawVerticalLine: false,
										horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
										getDrawingHorizontalLine: (value) {
											return FlLine(
												color: Colors.grey.withOpacity(0.3),
												strokeWidth: 1,
											);
										},
									),
									titlesData: FlTitlesData(
											leftTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													reservedSize: 40,
													interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
													getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
												),
											),
										bottomTitles: AxisTitles(
											sideTitles: SideTitles(
												showTitles: true,
												getTitlesWidget: (value, meta) {
													final index = value.toInt();
													if (index >= 0 && index < topItems.length) {
														return SideTitleWidget(
															axisSide: meta.axisSide,
															space: 16,
															child: Transform.translate(
																offset: const Offset(0, 36),
																child: Transform.rotate(
																	angle: -1.57,
																	child: Text(topItems[index].key, style: const TextStyle(fontSize: 10)),
																),
															),
														);
													}
													return const Text('');
												},
												reservedSize: 100,
											),
										),
										topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
										rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
									),
									borderData: FlBorderData(show: true),
								barGroups: topItems.asMap().entries.map((entry) {
										final x = entry.key;
										final map = entry.value.value;
										double running = 0.0;
										final stacks = <BarChartRodStackItem>[];
										for (int i = 0; i < terugList.length; i++) {
											final label = terugList[i];
											final value = (map[label] ?? 0).toDouble();
											if (value == 0) continue;
											final start = running;
											final end = running + value;
											stacks.add(BarChartRodStackItem(start, end, colors[i % colors.length]));
											running = end;
										}
										return BarChartGroupData(
											x: x,
											barRods: [
												BarChartRodData(
													toY: running,
													width: 22,
													borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
													rodStackItems: stacks,
												),
											],
										);
									}).toList(),
								),
						)
						: _buildPerTerugvoerBar(context, data),
						),
						const SizedBox(height: 12),
						Wrap(
							spacing: 8,
							runSpacing: 4,
							children: terugList.asMap().entries.map((e) {
								final color = colors[e.key % colors.length];
								return Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
										const SizedBox(width: 4),
										Text(e.value, style: const TextStyle(fontSize: 12)),
									],
								);
							}).toList(),
						),
					],
				),
			),
		);
	}

	Map<String, Map<String, int>> _computeKosItemTerugvoerData() {
		// Map: kos_item_name -> (terug_naam -> count) for selected period
		final Map<String, Map<String, int>> result = {};
		final cutoff = _cutoffDate();
		final filteredBT = _filteredBestellingTerugvoer(cutoff);
		// Feedback linked to bestelling_kos_item
		for (final bt in filteredBT) {
			final bestKosItem = bt['bestelling_kos_item'] as Map<String, dynamic>?;
			if (bestKosItem == null) continue;
			// Additionally ensure the best_kos item's best_datum is inside the period if present
			final String? bestDatumStr = bestKosItem['best_datum'] as String?;
			final DateTime? bestDatum = bestDatumStr != null ? DateTime.tryParse(bestDatumStr) : null;
			if (bestDatum != null && !bestDatum.isAfter(cutoff)) continue;

			final kos = bestKosItem['kos_item'] as Map<String, dynamic>?;
			if (kos == null) continue;
			
			final kosName = (kos['kos_item_naam'] as String?) ?? 'Onbekend';
			final tvMap = bt['terugvoer'] as Map<String, dynamic>?;
			final label = tvMap != null ? (tvMap['terug_naam'] as String? ?? 'Terugvoer') : 'Terugvoer';
			
			// Skip system-generated like entries for this chart
			if (label == '_LIKE_') continue;
			
			final map = result.putIfAbsent(kosName, () => <String, int>{});
			map[label] = (map[label] ?? 0) + 1;
		}
		return result;
	}

	// Build aggregated per terugvoer type (sum over all items)
	Widget _buildPerTerugvoerBar(BuildContext context, Map<String, Map<String, int>> perItemData) {
		// Flatten per-item map into totals per terugvoer label
		final Map<String, int> totals = {};
		perItemData.forEach((_, tvMap) {
			for (final entry in tvMap.entries) {
				totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
			}
		});
		final labels = totals.keys.toList()..sort();
		final values = labels.map((l) => totals[l] ?? 0).toList();
		final maxVal = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
		final maxY = (maxVal * 1.2).clamp(5, double.infinity).toDouble();
		final colors = [
			Colors.blue,
			Colors.orange,
			Colors.green,
			Colors.purple,
			Colors.red,
			Colors.teal,
			Colors.indigo,
			Colors.brown,
		];

		return BarChart(
			BarChartData(
				alignment: BarChartAlignment.spaceBetween,
				maxY: maxY,
				minY: 0,
				gridData: FlGridData(
					show: true,
					drawVerticalLine: false,
					horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
					getDrawingHorizontalLine: (value) {
						return FlLine(
							color: Colors.grey.withOpacity(0.3),
							strokeWidth: 1,
						);
					},
				),
				titlesData: FlTitlesData(
					leftTitles: AxisTitles(
						sideTitles: SideTitles(
							showTitles: true,
							reservedSize: 40,
							interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
							getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
						),
					),
					bottomTitles: AxisTitles(
						sideTitles: SideTitles(
							showTitles: true,
							getTitlesWidget: (value, meta) {
								final index = value.toInt();
								if (index >= 0 && index < labels.length) {
									return SideTitleWidget(
										axisSide: meta.axisSide,
										space: 16,
										child: Transform.translate(
											offset: const Offset(0, 36),
											child: Transform.rotate(
												angle: -1.57,
												child: Text(labels[index], style: const TextStyle(fontSize: 10)),
											),
										),
									);
								}
								return const Text('');
							},
						reservedSize: 100,
					),
				),
					topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
					rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
				),
				borderData: FlBorderData(show: true),
				barGroups: labels.asMap().entries.map((entry) {
						final x = entry.key;
						final label = entry.value;
						final value = (totals[label] ?? 0).toDouble();
						return BarChartGroupData(
							x: x,
							barRods: [
								BarChartRodData(
									toY: value,
									width: 22,
									borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
									color: colors[x % colors.length],
								),
							],
						);
					}).toList(),
			),
		);
	}

	Widget _buildNumericStatsSection(BuildContext context) {
		return const SizedBox.shrink();
	}

	@override
	void dispose() {
		_terugNaamController.dispose();
		_terugBeskrywingController.dispose();
		super.dispose();
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
	final int count;
	_SalesData({required this.day, required this.amount, required this.count});
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

class _FieldStats {
	final String dataset;
	final String field;
	final int count;
	final double sum;
	final double mean;
	final double median;
	final double mode;
	final double stdDev;
	final double min;
	final double max;
	_FieldStats({
		required this.dataset,
		required this.field,
		required this.count,
		required this.sum,
		required this.mean,
		required this.median,
		required this.mode,
		required this.stdDev,
		required this.min,
		required this.max,
	});
}