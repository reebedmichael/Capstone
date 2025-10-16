import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../locator.dart';
import 'package:intl/intl.dart';

class ToelaeBestuurPage extends StatefulWidget {
  const ToelaeBestuurPage({super.key});

  @override
  State<ToelaeBestuurPage> createState() => _ToelaeBestuurPageState();
}

class _ToelaeBestuurPageState extends State<ToelaeBestuurPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _gebruikers = [];
  List<Map<String, dynamic>> _toelaeTransaksies = [];
  Map<String, dynamic>? _selectedGebruiker;
  
  final _bedragController = TextEditingController();
  final _beskrywingController = TextEditingController();
  final _scrollController = ScrollController();
  String _transaksieMode = 'add'; // 'add' or 'deduct'
  
  String _searchQuery = '';
  bool _showLowAllowance = false;
  String _selectedUserType = 'alle'; // 'alle', 'studente', 'admin', 'laag'
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bedragController.dispose();
    _beskrywingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      
      // Load users with balance (beursie_balans = allowance + wallet)
      final gebruikersData = await sb
          .from('gebruikers')
          .select('gebr_id, gebr_naam, gebr_van, gebr_epos, beursie_balans, gebr_tipe:gebr_tipe_id(gebr_tipe_naam), admin_tipes:admin_tipe_id(admin_tipe_naam)')
          .eq('is_aktief', true)
          .order('gebr_naam');

      // Load all allowance transactions
      final toelaeRepo = sl<ToelaeRepository>();
      final transaksies = await toelaeRepo.lysAlleToelaeTransaksies();

      if (mounted) {
        setState(() {
          _gebruikers = List<Map<String, dynamic>>.from(gebruikersData);
          _toelaeTransaksies = transaksies;
          _loading = false;
        });
      }
      
      // Debug: Print first user to see the data structure
      if (gebruikersData.isNotEmpty) {
        print('🔍 First user data: ${gebruikersData.first}');
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

  List<Map<String, dynamic>> get _filteredGebruikers {
    var filtered = _gebruikers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((g) {
        final naam = '${g['gebr_naam'] ?? ''} ${g['gebr_van'] ?? ''}'.toLowerCase();
        final epos = (g['gebr_epos'] ?? '').toString().toLowerCase();
        return naam.contains(_searchQuery.toLowerCase()) ||
            epos.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply user type filter
    if (_selectedUserType != 'alle') {
      filtered = filtered.where((g) {
        final adminTipe = g['admin_tipes']?['admin_tipe_naam']?.toString().toLowerCase() ?? '';
        final gebrTipe = g['gebr_tipe']?.toString().toLowerCase() ?? '';
        
        // Debug print for admin filter
        if (_selectedUserType == 'admin') {
          print('🔍 User: ${g['gebr_naam']}, AdminTipe: $adminTipe, GebrTipe: $gebrTipe');
        }
        
        switch (_selectedUserType) {
          case 'studente':
            return gebrTipe.contains('student') || gebrTipe.contains('studente');
          case 'admin':
            // Check if user has any admin type (not "None" or "Pending")
            final isAdmin = adminTipe.isNotEmpty && 
                   adminTipe != 'none' && 
                   adminTipe != 'pending' &&
                   (adminTipe.contains('primary') || 
                    adminTipe.contains('secondary') || 
                    adminTipe.contains('tertiary'));
            if (_selectedUserType == 'admin') {
              print('🔍 Is admin: $isAdmin for ${g['gebr_naam']}');
            }
            return isAdmin;
          case 'laag':
            final balans = (g['beursie_balans'] as num?)?.toDouble() ?? 0.0;
            return balans < 50.0;
          default:
            return true;
        }
      }).toList();
    }

    // Apply low balance filter (separate from user type filter)
    if (_showLowAllowance) {
      filtered = filtered.where((g) {
        final balans = (g['beursie_balans'] as num?)?.toDouble() ?? 0.0;
        return balans < 50.0;
      }).toList();
    }

    return filtered;
  }

  void _showUserTransactionDetails(Map<String, dynamic> gebruiker) {
    showDialog(
      context: context,
      builder: (context) => _UserTransactionDetailsDialog(
        gebruiker: gebruiker,
        allTransactions: _toelaeTransaksies,
      ),
    );
  }

  Future<void> _submitTransaction() async {
    if (_selectedGebruiker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kies eers \'n gebruiker')),
      );
      return;
    }

    final bedrag = double.tryParse(_bedragController.text);
    if (bedrag == null || bedrag <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer \'n geldige bedrag in')),
      );
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final toelaeRepo = sl<ToelaeRepository>();
      final gebrId = _selectedGebruiker!['gebr_id'].toString();

      if (_transaksieMode == 'add') {
        await toelaeRepo.voegToelaeBy(
          gebrId: gebrId,
          bedrag: bedrag,
          beskrywing: _beskrywingController.text.isEmpty
              ? 'Toelae bygevoeg deur admin'
              : _beskrywingController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('R${bedrag.toStringAsFixed(2)} bygevoeg')),
          );
        }
      } else {
        await toelaeRepo.trekToelaeAf(
          gebrId: gebrId,
          bedrag: bedrag,
          beskrywing: _beskrywingController.text.isEmpty
              ? 'Toelae afgetrek deur admin'
              : _beskrywingController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('R${bedrag.toStringAsFixed(2)} afgetrek')),
          );
        }
      }

      // Clear form and reload
      _bedragController.clear();
      _beskrywingController.clear();
      setState(() {
        _selectedGebruiker = null;
      });
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _gebruikers.isEmpty) {
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
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Individuele Toelae",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        "Bestuur toelae vir individuele gebruikers",
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
            controller: _scrollController,
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

            // Transaction Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksie',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Transaction mode selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'add',
                          label: Text('Voeg By'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: 'deduct',
                          label: Text('Trek Af'),
                          icon: Icon(Icons.remove),
                        ),
                      ],
                      selected: {_transaksieMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _transaksieMode = newSelection.first);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Selected user display
                    if (_selectedGebruiker != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedGebruiker!['gebr_naam'] ?? ''} ${_selectedGebruiker!['gebr_van'] ?? ''}'.trim(),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedGebruiker!['gebr_epos'] ?? ''}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Balans: R${((_selectedGebruiker!['beursie_balans'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedGebruiker = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                              tooltip: 'Verwyder gebruiker',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // User selection prompt
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_add,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Kies \'n gebruiker uit die lys hieronder',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 16),

                    // Amount field
                    TextField(
                      controller: _bedragController,
                      decoration: InputDecoration(
                        labelText: 'Bedrag',
                        border: const OutlineInputBorder(),
                        prefixText: 'R ',
                        helperText: 'Voer bedrag in (bv. 100.00)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description field
                    TextField(
                      controller: _beskrywingController,
                      decoration: const InputDecoration(
                        labelText: 'Beskrywing (opsioneel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submitTransaction,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_transaksieMode == 'add' ? Icons.add : Icons.remove),
                        label: Text(_transaksieMode == 'add' ? 'Voeg Toelae By' : 'Trek Toelae Af'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: _transaksieMode == 'add'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Users List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gebruikers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        FilterChip(
                          label: const Text('Lae Toelae'),
                          selected: _showLowAllowance,
                          onSelected: (selected) {
                            setState(() => _showLowAllowance = selected);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Alle'),
                          selected: !_showLowAllowance && _searchQuery.isEmpty && _selectedUserType == 'alle',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _showLowAllowance = false;
                                _searchQuery = '';
                                _selectedUserType = 'alle';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // User type filters
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Studente'),
                          selected: _selectedUserType == 'studente',
                          onSelected: (selected) {
                            setState(() {
                              _selectedUserType = selected ? 'studente' : 'alle';
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Admins'),
                          selected: _selectedUserType == 'admin',
                          onSelected: (selected) {
                            setState(() {
                              _selectedUserType = selected ? 'admin' : 'alle';
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Lae Balans'),
                          selected: _selectedUserType == 'laag',
                          onSelected: (selected) {
                            setState(() {
                              _selectedUserType = selected ? 'laag' : 'alle';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Soek gebruikers',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Soek volgens naam of epos...',
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Results count
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_filteredGebruikers.length} van ${_gebruikers.length} gebruikers gevind',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    if (_filteredGebruikers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? 'Geen gebruikers gevind vir "$_searchQuery"'
                                    : 'Geen gebruikers gevind nie',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Text('Maak soek skoon'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 400, // Fixed height to prevent overflow
                        child: ListView.builder(
                          itemCount: _filteredGebruikers.length,
                          itemBuilder: (context, index) {
                            final g = _filteredGebruikers[index];
                            final naam = '${g['gebr_naam'] ?? ''} ${g['gebr_van'] ?? ''}'.trim();
                            final epos = g['gebr_epos'] ?? '';
                            final balans = (g['beursie_balans'] as num?)?.toDouble() ?? 0.0;
                            final tipe = g['gebr_tipe']?['gebr_tipe_naam'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: balans < 50
                                    ? Colors.orange
                                    : Colors.green,
                                child: Text(
                                  (naam.isNotEmpty ? naam[0] : 'U').toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(naam.isEmpty ? 'Geen naam' : naam),
                              subtitle: Text(epos),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: balans < 50
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'R${balans.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: balans < 50 ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _showUserTransactionDetails(g),
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'Bekyk transaksie geskiedenis',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                  ),
                                ],
                              ),
                            onTap: () {
                              setState(() {
                                _selectedGebruiker = g;
                              });
                              // Auto scroll to transaction form
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _scrollController.animateTo(
                                  0, // Scroll to top where transaction form is
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              });
                            },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserTransactionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> gebruiker;
  final List<Map<String, dynamic>> allTransactions;

  const _UserTransactionDetailsDialog({
    required this.gebruiker,
    required this.allTransactions,
  });

  @override
  State<_UserTransactionDetailsDialog> createState() => _UserTransactionDetailsDialogState();
}

class _UserTransactionDetailsDialogState extends State<_UserTransactionDetailsDialog> {
  String _selectedTransactionType = 'alle';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;

  Widget _buildQuickDateChipDialog(String label, VoidCallback onTap, {bool isClear = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isClear ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isClear ? Colors.red.shade200 : Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isClear ? Colors.red.shade700 : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFieldDialog({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            if (date != null)
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.clear,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _userTransactions {
    return widget.allTransactions
        .where((t) => t['gebr_id']?.toString() == widget.gebruiker['gebr_id']?.toString())
        .toList();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = _userTransactions;

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

  @override
  Widget build(BuildContext context) {
    final naam = '${widget.gebruiker['gebr_naam'] ?? ''} ${widget.gebruiker['gebr_van'] ?? ''}'.trim();
    final epos = widget.gebruiker['gebr_epos'] ?? '';
    final balans = (widget.gebruiker['beursie_balans'] as num?)?.toDouble() ?? 0.0;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: balans < 50 ? Colors.orange : Colors.green,
                  child: Text(
                    (naam.isNotEmpty ? naam[0] : 'U').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        naam.isEmpty ? 'Geen naam' : naam,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        epos,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: balans < 50 ? Colors.orange.shade100 : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Balans: R${balans.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balans < 50 ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildQuickDateChipDialog('Vandag', () {
                          final today = DateTime.now();
                          setState(() {
                            _selectedDateFrom = today;
                            _selectedDateTo = today;
                          });
                        }),
                        _buildQuickDateChipDialog('7 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 7));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChipDialog('14 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 14));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChipDialog('30 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 30));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChipDialog('90 Dae', () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedDateFrom = now.subtract(const Duration(days: 90));
                            _selectedDateTo = now;
                          });
                        }),
                        _buildQuickDateChipDialog('Maak Skoon', () {
                          setState(() {
                            _selectedDateFrom = null;
                            _selectedDateTo = null;
                          });
                        }, isClear: true),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
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
                          child: _buildDateFieldDialog(
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateFieldDialog(
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results count
            Row(
              children: [
                Text(
                  'Transaksie Geskiedenis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredTransactions.length} van ${_userTransactions.length} transaksies',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Transactions List
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Geen transaksies gevind nie',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
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
                        final adminNaam = t['admin_naam'] != null
                            ? '${t['admin_naam']} ${t['admin_van'] ?? ''}'.trim()
                            : 'Stelsel';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isInbetaling
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: Icon(
                                isInbetaling ? Icons.add : Icons.remove,
                                color: isInbetaling ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              beskrywing.isNotEmpty ? beskrywing : tipeNaam,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
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
}

