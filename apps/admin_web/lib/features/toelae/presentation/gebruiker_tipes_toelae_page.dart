import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:spys_api_client/spys_api_client.dart';

class GebruikerTipesToelaePage extends StatefulWidget {
  const GebruikerTipesToelaePage({super.key});

  @override
  State<GebruikerTipesToelaePage> createState() => _GebruikerTipesToelaePageState();
}

class _GebruikerTipesToelaePageState extends State<GebruikerTipesToelaePage> {
  final ToelaeRepository _toelaeRepo = GetIt.instance<ToelaeRepository>();
  
  List<Map<String, dynamic>> _gebruikerTipes = [];
  bool _isLoading = true;
  String? _error;
  bool _isDistributing = false;

  @override
  void initState() {
    super.initState();
    _loadGebruikerTipes();
  }

  Future<void> _loadGebruikerTipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tipes = await _toelaeRepo.lysGebruikerTipes();
      setState(() {
        _gebruikerTipes = tipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

    setState(() => _isDistributing = true);

    try {
      final result = await _toelaeRepo.distribueeMaandelikseToelaes();
      
      final usersCredited = result['users_credited'] ?? 0;
      final totalAmount = (result['total_amount'] as num?)?.toDouble() ?? 0.0;

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout tydens distribusie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDistributing = false);
    }
  }

  void _showEditDialog(Map<String, dynamic> tipe) {
    final controller = TextEditingController(
      text: ((tipe['gebr_toelaag'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
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
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gebruiker Tipes & Toelaes',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bestuur maandelikse toelaes vir elke gebruiker tipe',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isDistributing ? null : _distribueeMaandelikseToelaes,
                  icon: _isDistributing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isDistributing ? 'Besig...' : 'Distribueer Maandelikse Toelaes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Fout: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadGebruikerTipes,
                      child: const Text('Probeer Weer'),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Gebruiker Tipe')),
                          DataColumn(label: Text('Beskrywing')),
                          DataColumn(label: Text('Maandelikse Toelae')),
                          DataColumn(label: Text('Aksies')),
                        ],
                        rows: _gebruikerTipes.map((tipe) {
                          final naam = tipe['gebr_tipe_naam'] ?? 'Onbekend';
                          final beskrywing = tipe['gebr_tipe_beskrywing'] ?? '-';
                          final toelaag = (tipe['gebr_toelaag'] as num?)?.toDouble() ?? 0.0;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  naam,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(
                                Text(
                                  beskrywing.isEmpty ? '-' : beskrywing,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(tipe),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: toelaag > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: toelaag > 0 ? Colors.green.shade200 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'R${toelaag.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: toelaag > 0 ? Colors.green.shade900 : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: toelaag > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Wysig'),
                                  onPressed: () => _showEditDialog(tipe),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),

            const SizedBox(height: 16),

            // Quick setup and Info
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.flash_on, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Vinnige Opset',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Klik op die toelae bedrag of "Wysig" knoppie om die maandelikse toelae te verander.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Stel Student → R1000'),
                                onPressed: () => _setQuickToelaag('Student', 1000),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Stel Personeel → R15000'),
                                onPressed: () => _setQuickToelaag('Personeel', 15000),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoe Dit Werk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1. Stel maandelikse toelae\n'
                                  '2. Druk "Distribueer"\n'
                                  '3. Alle aktiewe gebruikers ontvang toelae',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

