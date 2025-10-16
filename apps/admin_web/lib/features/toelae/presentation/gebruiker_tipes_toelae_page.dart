import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spys_api_client/spys_api_client.dart';

class GebruikerTipesToelaePage extends StatefulWidget {
  const GebruikerTipesToelaePage({super.key});

  @override
  State<GebruikerTipesToelaePage> createState() =>
      _GebruikerTipesToelaePageState();
}

class _GebruikerTipesToelaePageState extends State<GebruikerTipesToelaePage> {
  final ToelaeRepository _toelaeRepo = GetIt.instance<ToelaeRepository>();
  final InstellingsRepository _instellingsRepo =
      GetIt.instance<InstellingsRepository>();

  List<Map<String, dynamic>> _gebruikerTipes = [];
  bool _isLoading = true;
  String? _error;
  bool _isDistributing = false;

  // Settings
  int _verspreidingDag = 1;
  bool _loadingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadGebruikerTipes();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final dag = await _instellingsRepo.kryToelaeVerspreidingDag();
      if (mounted) {
        setState(() {
          _verspreidingDag = dag;
        });
      }
    } catch (e) {
      print('Fout met laai instellings: $e');
    }
  }

  Future<void> _updateVerspreidingDag(int nieuweDag) async {
    setState(() => _loadingSettings = true);

    try {
      await _instellingsRepo.updateToelaeVerspreidingDag(nieuweDag);

      if (mounted) {
        setState(() {
          _verspreidingDag = nieuweDag;
          _loadingSettings = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Toelae sal nou versprei word op dag $nieuweDag van elke maand',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSettings = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getNextDistributionDate() {
    final now = DateTime.now();
    DateTime nextDate;

    if (now.day < _verspreidingDag) {
      // Next distribution is this month
      nextDate = DateTime(now.year, now.month, _verspreidingDag);
    } else {
      // Next distribution is next month
      nextDate = DateTime(now.year, now.month + 1, _verspreidingDag);
    }

    final months = [
      'Jan',
      'Feb',
      'Mrt',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${nextDate.day} ${months[nextDate.month - 1]} ${nextDate.year}';
  }

  void _showVerspreidingDagDialog() {
    int selectedDag = _verspreidingDag;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verander Verspreiding Dag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kies die dag van die maand waarop toelae outomaties versprei moet word:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kies \'n dag tussen 1-28 om te verseker alle maande is gedek',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<int>(
                value: selectedDag,
                decoration: const InputDecoration(
                  labelText: 'Dag van die Maand',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(28, (index) {
                  final dag = index + 1;
                  return DropdownMenuItem(value: dag, child: Text('Dag $dag'));
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDag = value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVerspreidingDag(selectedDag);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stoor'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadGebruikerTipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tipes = await _toelaeRepo.lysGebruikerTipes();
      if (mounted) {
        setState(() {
          _gebruikerTipes = tipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateToelaag(String gebrTipeId, double nieuweToelaag) async {
    try {
      await _toelaeRepo.updateToelaagVirTipe(
        gebrTipeId: gebrTipeId,
        nieuweToelaag: nieuweToelaag,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toelae bedrag opgedateer!')),
      );

      await _loadGebruikerTipes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setQuickToelaag(String tipeNaam, double bedrag) async {
    final tipe = _gebruikerTipes.firstWhere(
      (t) => t['gebr_tipe_naam'] == tipeNaam,
      orElse: () => {},
    );

    if (tipe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gebruiker tipe "$tipeNaam" nie gevind nie')),
      );
      return;
    }

    await _updateToelaag(tipe['gebr_tipe_id'], bedrag);
  }

  Future<void> _distribueeMaandelikseToelaes() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig Maandelikse Distribusie'),
        content: const Text(
          'Is jy seker jy wil maandelikse toelaes distribueer aan alle gebruikers?\n\n'
          'Dit sal elke aktiewe gebruiker se toelae volgens hulle gebruiker tipe byvoeg.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Distribueer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      setState(() => _isDistributing = true);
    }

    try {
      final result = await _toelaeRepo.distribueeMaandelikseToelaes();

      final usersCredited = result['users_credited'] ?? 0;
      final totalAmount = (result['total_amount'] as num?)?.toDouble() ?? 0.0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Suksesvol! $usersCredited gebruikers gekrediteer met R${totalAmount.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        await _loadGebruikerTipes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout tydens distribusie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDistributing = false);
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> tipe) {
    final controller = TextEditingController(
      text: ((tipe['gebr_toelaag'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(
        2,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wysig Toelae: ${tipe['gebr_tipe_naam']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Huidige toelae: R${((tipe['gebr_toelaag'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuwe Maandelikse Toelae (R)',
                border: OutlineInputBorder(),
                prefixText: 'R ',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dit sal toegepas word op alle gebruikers van hierdie tipe tydens die volgende maandelikse distribusie.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              final nieuweToelaag = double.tryParse(controller.text);
              if (nieuweToelaag != null && nieuweToelaag >= 0) {
                Navigator.pop(context);
                _updateToelaag(tipe['gebr_tipe_id'], nieuweToelaag);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voer \'n geldige bedrag in')),
                );
              }
            },
            child: const Text('Stoor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Icons.group_work,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gebruiker Tipes & Toelaes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        "Bestuur maandelikse toelaes vir elke gebruiker tipe",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              // Right section: action button
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isDistributing
                        ? null
                        : _distribueeMaandelikseToelaes,
                    icon: _isDistributing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isDistributing ? 'Besig...' : 'Distribueer Nou',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Settings Card - Verspreiding Dag
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Outomatiese Verspreiding Instellings',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Maandelikse Verspreiding Dag',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toelae word outomaties versprei op dag $_verspreidingDag van elke maand om middernag',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Volgende verspreiding: ${_getNextDistributionDate()}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: _loadingSettings
                                    ? null
                                    : () {
                                        _showVerspreidingDagDialog();
                                      },
                                icon: _loadingSettings
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.edit),
                                label: const Text('Verander Dag'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fout: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadGebruikerTipes,
                          child: const Text('Probeer Weer'),
                        ),
                      ],
                    ),
                  )
                else
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gebruiker Tipes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: const Color(
                                0xFFE7D9CF,
                              ), // subtle warm divider like screenshot
                            ),
                            child: DataTableTheme(
                              data: DataTableThemeData(
                                dividerThickness: 1,
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.grey.shade100,
                                ),
                                headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 68,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  columnSpacing: 64,
                                  horizontalMargin: 24,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Gebruiker Tipe',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Beskrywing',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      numeric: false,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Maandelikse Toelae',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      numeric: false,
                                    ),
                                  ],
                                  rows: _gebruikerTipes.map((tipe) {
                                    final naam =
                                        tipe['gebr_tipe_naam'] ?? 'Onbekend';
                                    final beskrywing =
                                        tipe['gebr_tipe_beskrywing'] ?? '-';
                                    final toelaag =
                                        (tipe['gebr_toelaag'] as num?)
                                            ?.toDouble() ??
                                        0.0;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            naam,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            beskrywing.isEmpty
                                                ? '-'
                                                : beskrywing,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: () =>
                                                  _showEditDialog(tipe),
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 220,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.green.shade400,
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'R${toelaag.toStringAsFixed(2)}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Colors
                                                                  .green
                                                                  .shade800,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
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
