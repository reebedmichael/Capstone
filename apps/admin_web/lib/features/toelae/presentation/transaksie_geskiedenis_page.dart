import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../locator.dart';
import 'package:intl/intl.dart';

class TransaksieGeskiedenisPage extends StatefulWidget {
  const TransaksieGeskiedenisPage({super.key});

  @override
  State<TransaksieGeskiedenisPage> createState() => _TransaksieGeskiedenisPageState();
}

class _TransaksieGeskiedenisPageState extends State<TransaksieGeskiedenisPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _toelaeTransaksies = [];
  
  // Transaction history filters
  String _selectedTransactionType = 'alle'; // 'alle', 'inbetaling', 'afbetaling'
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load all allowance transactions
      final toelaeRepo = sl<ToelaeRepository>();
      final transaksies = await toelaeRepo.lysAlleToelaeTransaksies();

      if (mounted) {
        setState(() {
          _toelaeTransaksies = transaksies;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = _toelaeTransaksies;

    // Filter by transaction type
    if (_selectedTransactionType != 'alle') {
      filtered = filtered.where((t) {
        final transTipeId = t['trans_tipe_id']?.toString() ?? '';
        if (_selectedTransactionType == 'inbetaling') {
          return transTipeId == '1654002c-61bc-4e31-9186-edb75a34d181' || // inbetaling
                 transTipeId == '9c1d1ea9-5ccb-46b0-83d6-e7ba9cf86d5b' || // admin kanselasie (refund)
                 transTipeId == 'a1e58a24-1a1d-4940-8855-df4c35ae5d5f';   // toelae_inbetaling
        } else if (_selectedTransactionType == 'afbetaling') {
          return transTipeId == 'a2e58a24-1a1d-4940-8855-df4c35ae5d5f' || // toelae_uitbetaling
                 transTipeId == 'bdfb88ce-b0c9-483d-97a2-226cfca4e5ea';   // uitbetaling
        }
        return true;
      }).toList();
    }

    // Filter by date range
    if (_selectedDateFrom != null) {
      filtered = filtered.where((t) {
        final datum = DateTime.tryParse(t['trans_geskep_datum'] ?? '');
        if (datum == null) return false;
        final datumDate = DateTime(datum.year, datum.month, datum.day);
        final fromDate = DateTime(_selectedDateFrom!.year, _selectedDateFrom!.month, _selectedDateFrom!.day);
        return datumDate.isAtSameMomentAs(fromDate) || datumDate.isAfter(fromDate);
      }).toList();
    }

    if (_selectedDateTo != null) {
      filtered = filtered.where((t) {
        final datum = DateTime.tryParse(t['trans_geskep_datum'] ?? '');
        if (datum == null) return false;
        final datumDate = DateTime(datum.year, datum.month, datum.day);
        final toDate = DateTime(_selectedDateTo!.year, _selectedDateTo!.month, _selectedDateTo!.day);
        return datumDate.isAtSameMomentAs(toDate) || datumDate.isBefore(toDate);
      }).toList();
    }

    return filtered;
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap, {bool isClear = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isClear ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClear ? Colors.red.shade200 : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isClear ? Colors.red.shade700 : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            if (date != null)
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.clear,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _toelaeTransaksies.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left section: logo + title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transaksie Geskiedenis",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        "Bekyk alle toelae transaksies",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right section: empty for now
              const SizedBox.shrink(),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Transaction History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alle Transaksies',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Transaction Filters
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction Type Filters
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Alle Tipes'),
                              selected: _selectedTransactionType == 'alle',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? 'alle' : 'alle';
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('Inbetalings'),
                              selected: _selectedTransactionType == 'inbetaling',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? 'inbetaling' : 'alle';
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('Afbetalings'),
                              selected: _selectedTransactionType == 'afbetaling',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTransactionType = selected ? 'afbetaling' : 'alle';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                    
                    // Quick Date Options
                    Text(
                      'Vinnige Datum Opsies:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildQuickDateChip('Vandag', () {
                          final today = DateTime.now();
                          setState(() {
                            _selectedDateFrom = today;
                            _selectedDateTo = today;
                          });
                        }),
                        _buildQuickDateChip('7 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 7));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChip('14 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 14));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChip('30 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 30));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChip('90 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 90));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChip('Maak Skoon', () {
                          setState(() {
                            _selectedDateFrom = null;
                            _selectedDateTo = null;
                          });
                        }, isClear: true),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Custom Date Range
                    Text(
                      'Pasgemaakte Datum Reeks:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Van',
                            date: _selectedDateFrom,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDateFrom ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDateFrom = date;
                                });
                              }
                            },
                            onClear: () {
                              setState(() {
                                _selectedDateFrom = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Tot',
                            date: _selectedDateTo,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDateTo ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDateTo = date;
                                });
                              }
                            },
                            onClear: () {
                              setState(() {
                                _selectedDateTo = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Results count
                    if (_selectedTransactionType != 'alle' || _selectedDateFrom != null || _selectedDateTo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_filteredTransactions.length} van ${_toelaeTransaksies.length} transaksies gevind',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    if (_filteredTransactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Geen transaksies gevind nie'),
                        ),
                      )
                    else
                      SizedBox(
                        height: 600, // Fixed height for scrolling
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTransactions[index];
                            final bedrag = (t['trans_bedrag'] as num?)?.toDouble() ?? 0.0;
                            final tipeNaam = t['trans_tipe_naam'] ?? '';
                            final datum = DateTime.tryParse(t['trans_geskep_datum'] ?? '');
                            final beskrywing = t['trans_beskrywing'] ?? '';
                            // Determine if this is an addition or deduction based on trans_tipe_id
                            final transTipeId = t['trans_tipe_id']?.toString() ?? '';
                            final isInbetaling = transTipeId == '1654002c-61bc-4e31-9186-edb75a34d181' || // inbetaling
                                               transTipeId == '9c1d1ea9-5ccb-46b0-83d6-e7ba9cf86d5b' || // admin kanselasie (refund)
                                               transTipeId == 'a1e58a24-1a1d-4940-8855-df4c35ae5d5f';   // toelae_inbetaling
                            final gebruikerNaam = '${t['gebr_naam'] ?? ''} ${t['gebr_van'] ?? ''}'.trim();
                            final adminNaam = t['admin_naam'] != null
                                ? '${t['admin_naam']} ${t['admin_van'] ?? ''}'.trim()
                                : 'Stelsel';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isInbetaling
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                child: Icon(
                                  isInbetaling ? Icons.add : Icons.remove,
                                  color: isInbetaling ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(gebruikerNaam),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(beskrywing),
                                  Text(
                                    'Deur: $adminNaam',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (datum != null)
                                    Text(
                                      DateFormat('dd MMM yyyy HH:mm').format(datum),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isInbetaling ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isInbetaling ? Colors.green.shade200 : Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  '${isInbetaling ? '+' : '-'}R${bedrag.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isInbetaling ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),],
              ),
            ),),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
