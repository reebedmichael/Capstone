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

      setState(() {
        _gebruikers = List<Map<String, dynamic>>.from(gebruikersData);
        _toelaeTransaksies = transaksies;
        _loading = false;
      });
      
      // Debug: Print first user to see the data structure
      if (gebruikersData.isNotEmpty) {
        print('🔍 First user data: ${gebruikersData.first}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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

    setState(() => _loading = true);

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
      setState(() => _selectedGebruiker = null);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _gebruikers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.account_balance_wallet, 
                    size: 32, 
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Toelae Bestuur',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bestuur toelae vir gebruikers',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

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
                                setState(() => _selectedGebruiker = null);
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
                        prefixIcon: const Icon(Icons.attach_money),
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
                              trailing: Container(
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
                            onTap: () {
                              setState(() => _selectedGebruiker = g);
                            },
                            );
                          },
                        ),
                      ),
                  ],
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
                      'Transaksie Geskiedenis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    if (_toelaeTransaksies.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Geen transaksies gevind nie'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _toelaeTransaksies.take(10).length,
                        itemBuilder: (context, index) {
                          final t = _toelaeTransaksies[index];
                          final bedrag = (t['trans_bedrag'] as num?)?.toDouble() ?? 0.0;
                          final tipeNaam = t['trans_tipe_naam'] ?? '';
                          final isInbetaling = tipeNaam.contains('inbetaling');
                          final datum = DateTime.tryParse(t['trans_geskep_datum'] ?? '');
                          final beskrywing = t['trans_beskrywing'] ?? '';
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
                            trailing: Text(
                              '${isInbetaling ? '+' : '-'}R${bedrag.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isInbetaling ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

