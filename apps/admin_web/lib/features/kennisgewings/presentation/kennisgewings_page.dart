import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:intl/intl.dart';

class KennisgewingsPage extends StatefulWidget {
  const KennisgewingsPage({super.key});
  @override
  State<KennisgewingsPage> createState() => _KennisgewingsPageState();
}

class _KennisgewingsPageState extends State<KennisgewingsPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _gebruikers = [];
  bool _isLoading = true;

  // Filters
  String _soortFilter = 'alles'; // alles | gebruiker | globaal
  String _tipeFilter =
      'alle_tipes'; // alle_tipes | info | waarskuwing | fout | sukses
  String? _selectedGebruikerId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _laaiData();
  }

  Future<void> _laaiData() async {
    setState(() => _isLoading = true);
    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      // Laai ALLE kennisgewings (gebruiker + globaal)
      final kennisgewings = await kennisgewingRepo
          .kryAlleKennisgewingsVirAdmin();

      // Laai alle gebruikers vir die filter
      final gebruikersData = await Supabase.instance.client
          .from('gebruikers')
          .select('gebr_id, gebr_naam, gebr_van, gebr_epos')
          .order('gebr_naam');

      setState(() {
        _all = kennisgewings;
        _gebruikers = List<Map<String, dynamic>>.from(gebruikersData);
        _isLoading = false;
      });
    } catch (e) {
      print('Fout met laai kennisgewings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _gefilterde {
    return _all.where((final Map<String, dynamic> k) {
      final soort = k['_kennisgewing_soort'] ?? 'globaal';
      final bool matchSoort = _soortFilter == 'alles' || soort == _soortFilter;

      final bool matchTipe =
          _tipeFilter == 'alle_tipes' ||
          (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') ==
              _tipeFilter;

      // Filter op gebruiker
      bool matchGebruiker = true;
      if (_selectedGebruikerId != null) {
        if (soort == 'gebruiker') {
          matchGebruiker = k['gebr_id'] == _selectedGebruikerId;
        } else {
          matchGebruiker =
              false; // Globale kennisgewings het nie 'n spesifieke gebruiker nie
        }
      }

      // Filter op datum
      bool matchDatum = true;
      if (_dateRange != null) {
        final datum = DateTime.parse(
          k['kennis_geskep_datum'] ?? k['glob_kennis_geskep_datum'],
        );
        matchDatum =
            datum.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            datum.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }

      return matchSoort && matchTipe && matchGebruiker && matchDatum;
    }).toList();
  }

  // Groepeer kennisgewings op titel, beskrywing en datum (om batch kennisgewings saam te groepeer)
  Map<String, List<Map<String, dynamic>>> get _gegroepeerdeKennisgewings {
    final Map<String, List<Map<String, dynamic>>> groepe = {};

    for (var k in _gefilterde) {
      final titel = k['kennis_titel'] ?? k['glob_kennis_titel'] ?? '';
      final beskrywing =
          k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? '';
      final datum = DateTime.parse(
        k['kennis_geskep_datum'] ?? k['glob_kennis_geskep_datum'],
      );
      final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
      final soort = k['_kennisgewing_soort'];

      // Skep 'n unieke sleutel vir groepe (titel + beskrywing + datum tot op minuut + tipe + soort)
      final datumString = DateFormat('yyyy-MM-dd HH:mm').format(datum);
      final sleutel = '$titel|$beskrywing|$datumString|$tipe|$soort';

      if (!groepe.containsKey(sleutel)) {
        groepe[sleutel] = [];
      }
      groepe[sleutel]!.add(k);
    }

    return groepe;
  }

  int get _gebruikerKennisgewings =>
      _all.where((k) => k['_kennisgewing_soort'] == 'gebruiker').length;
  int get _globaleKennisgewings =>
      _all.where((k) => k['_kennisgewing_soort'] == 'globaal').length;
  int get _waarskuwings => _all
      .where(
        (k) =>
            (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') ==
            'waarskuwing',
      )
      .length;

  Future<void> _openSkepDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SkepRedigeerDialog(gebruikers: _gebruikers),
    );

    if (result == true) {
      await _laaiData();
    }
  }

  Future<void> _openRedigeerDialog(Map<String, dynamic> k) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _SkepRedigeerDialog(kennisgewing: k, gebruikers: _gebruikers),
    );

    if (result == true) {
      await _laaiData();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groepe = _gegroepeerdeKennisgewings;

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
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kennisgewings Bestuur",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        "Bestuur kennisgewings en kennisgewings",
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
              // Right section: action buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openSkepDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Skep Kennisgewing'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Statistieke
                LayoutBuilder(
                  builder: (context, constraints) {
                    final int cols = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 800
                        ? 2
                        : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: cols,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.9,
                      children: <Widget>[
                        _stat(
                          'Totaal',
                          '${_all.length}',
                          Icons.notifications_none,
                          Theme.of(context).colorScheme.primary,
                        ),
                        _stat(
                          'Gebruiker',
                          '$_gebruikerKennisgewings',
                          Icons.person_outline,
                          Colors.blue,
                        ),
                        _stat(
                          'Globaal',
                          '$_globaleKennisgewings',
                          Icons.public,
                          Colors.green,
                        ),
                        _stat(
                          'Waarskuwings',
                          '$_waarskuwings',
                          Icons.warning_amber_rounded,
                          Colors.orange,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Filters en Aksies
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.filter_list,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Filters',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            // Soort Filter
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 180,
                                maxWidth: 220,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _soortFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Soort',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'alles',
                                    child: Text(
                                      'Alle',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'gebruiker',
                                    child: Text(
                                      'Gebruiker',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'globaal',
                                    child: Text(
                                      'Globaal',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) =>
                                    setState(() => _soortFilter = v ?? 'alles'),
                              ),
                            ),

                            // Tipe Filter
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 180,
                                maxWidth: 220,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _tipeFilter,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tipe',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.label),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'alle_tipes',
                                    child: Text(
                                      'Alle tipes',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'info',
                                    child: Text(
                                      'Inligting',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'waarskuwing',
                                    child: Text(
                                      'Waarskuwing',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fout',
                                    child: Text(
                                      'Fout',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sukses',
                                    child: Text(
                                      'Sukses',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'help',
                                    child: Text(
                                      'Help',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) => setState(
                                  () => _tipeFilter = v ?? 'alle_tipes',
                                ),
                              ),
                            ),

                            // Gebruiker Filter
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 200,
                                maxWidth: 280,
                              ),
                              child: DropdownButtonFormField<String?>(
                                value: _selectedGebruikerId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Gebruiker',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      'Alle Gebruikers',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  ..._gebruikers.map(
                                    (g) => DropdownMenuItem<String?>(
                                      value: g['gebr_id'],
                                      child: Text(
                                        '${g['gebr_naam']} ${g['gebr_van']}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) =>
                                    setState(() => _selectedGebruikerId = v),
                              ),
                            ),

                            // Datum Reeks Filter
                            OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _dateRange == null
                                    ? 'Kies Datum Reeks'
                                    : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                              ),
                            ),

                            if (_dateRange != null)
                              IconButton(
                                onPressed: _clearDateRange,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Verwyder Datum Filter',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Gegroepeerde Kennisgewings Lys
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: [
                            Text(
                              'Kennisgewings',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${groepe.length} ${groepe.length == 1 ? 'groep' : 'groepe'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_gefilterde.length} van ${_all.length} kennisgewings',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (groepe.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: <Widget>[
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Geen Kennisgewings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: groepe.entries.map((entry) {
                              final kennisgewings = entry.value;
                              final eerstKennisgewing = kennisgewings.first;

                              return AnnouncementGroupCard(
                                kennisgewings: kennisgewings,
                                eerstKennisgewing: eerstKennisgewing,
                                onEdit: () =>
                                    _openRedigeerDialog(eerstKennisgewing),
                                onDelete: () => _verwyderGroep(kennisgewings),
                              );
                            }).toList(),
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

  Future<void> _verwyderGroep(List<Map<String, dynamic>> kennisgewings) async {
    final bevestig = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig Verwydering'),
        content: Text(
          kennisgewings.length > 1
              ? 'Is jy seker jy wil hierdie ${kennisgewings.length} kennisgewings verwyder?'
              : 'Is jy seker jy wil hierdie kennisgewing verwyder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kanselleer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwyder'),
          ),
        ],
      ),
    );

    if (bevestig != true) return;

    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      for (var k in kennisgewings) {
        final soort = k['_kennisgewing_soort'];
        if (soort == 'globaal') {
          await kennisgewingRepo.verwyderGlobaleKennisgewing(
            k['glob_kennis_id'],
          );
        } else {
          await kennisgewingRepo.verwyderKennisgewing(k['kennis_id']);
        }
      }

      await _laaiData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kennisgewings.length > 1
                  ? '${kennisgewings.length} kennisgewings suksesvol verwyder!'
                  : 'Kennisgewing suksesvol verwyder!',
            ),
          ),
        );
      }
    } catch (e) {
      print('Fout met verwyder: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout: $e')));
      }
    }
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Herbruikbare AnnouncementGroupCard widget
class AnnouncementGroupCard extends StatelessWidget {
  final List<Map<String, dynamic>> kennisgewings;
  final Map<String, dynamic> eerstKennisgewing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementGroupCard({
    super.key,
    required this.kennisgewings,
    required this.eerstKennisgewing,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _typeIcon(String tipe) {
    switch (tipe) {
      case 'waarskuwing':
        return Icons.warning_amber_rounded;
      case 'fout':
        return Icons.error_outline;
      case 'sukses':
        return Icons.check_circle_outline;
      case 'help':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _typeColor(String tipe) {
    switch (tipe) {
      case 'waarskuwing':
        return Colors.orange;
      case 'fout':
        return Colors.red;
      case 'sukses':
        return Colors.green;
      case 'help':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime d) {
    return DateFormat('dd MMM yyyy HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final soort = eerstKennisgewing['_kennisgewing_soort'] ?? 'globaal';
    final tipe =
        eerstKennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final datum = DateTime.parse(
      eerstKennisgewing['kennis_geskep_datum'] ??
          eerstKennisgewing['glob_kennis_geskep_datum'],
    );
    final titel =
        eerstKennisgewing['kennis_titel'] ??
        eerstKennisgewing['glob_kennis_titel'] ??
        '';
    final beskrywing =
        eerstKennisgewing['kennis_beskrywing'] ??
        eerstKennisgewing['glob_kennis_beskrywing'] ??
        'Kennisgewing';

    // Kry ontvanger inligting
    String ontvanger = 'Alle gebruikers';
    if (soort == 'gebruiker') {
      if (kennisgewings.length > 1) {
        ontvanger = '${kennisgewings.length} gebruikers';
      } else {
        final gebruiker = eerstKennisgewing['gebruikers'];
        if (gebruiker != null) {
          ontvanger = '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']}';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _typeColor(tipe).withOpacity(0.03),
        border: Border.all(
          color: _typeColor(tipe).withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: kennisgewings.length > 1
              ? () => _toonGroepDetails(context)
              : () => _toonKennisgewingDetail(context, eerstKennisgewing),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _typeColor(tipe).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _typeColor(tipe).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _typeIcon(tipe),
                        color: _typeColor(tipe),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (titel.isNotEmpty) ...[
                                      Text(
                                        titel,
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Builder(
                                      builder: (context) {
                                        String formatted = beskrywing;
                                        if (tipe == 'help') {
                                          String? helpEmail;
                                          final regex = RegExp(
                                            r'E-pos:\s*([^\s]+)',
                                            caseSensitive: false,
                                          );
                                          final match = regex.firstMatch(
                                            beskrywing,
                                          );
                                          if (match != null &&
                                              match.groupCount >= 1) {
                                            helpEmail = match.group(1);
                                          } else {
                                            final lines = beskrywing
                                                .split('\n')
                                                .map((e) => e.trim())
                                                .where((e) => e.isNotEmpty)
                                                .toList();
                                            if (lines.isNotEmpty) {
                                              final last = lines.last;
                                              final emailRegex = RegExp(
                                                r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
                                                caseSensitive: false,
                                              );
                                              final emailMatch = emailRegex
                                                  .firstMatch(last);
                                              if (emailMatch != null)
                                                helpEmail = emailMatch.group(0);
                                            }
                                          }

                                          final messageOnly = beskrywing
                                              .split('\n')
                                              .where(
                                                (line) => !line
                                                    .trim()
                                                    .toLowerCase()
                                                    .startsWith('e-pos'),
                                              )
                                              .join('\n')
                                              .trim();

                                          if (helpEmail != null) {
                                            formatted = messageOnly.isNotEmpty
                                                ? '$messageOnly\nE-pos: $helpEmail'
                                                : 'E-pos: $helpEmail';
                                          } else {
                                            formatted = messageOnly.isNotEmpty
                                                ? messageOnly
                                                : beskrywing;
                                          }
                                        }

                                        return Text(
                                          formatted,
                                          style: TextStyle(
                                            fontSize: titel.isNotEmpty
                                                ? 14
                                                : 17,
                                            fontWeight: titel.isNotEmpty
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            color: titel.isNotEmpty
                                                ? Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color
                                                : Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge?.color,
                                          ),
                                          softWrap: true,
                                          maxLines: tipe == 'help' ? null : 2,
                                          overflow: tipe == 'help'
                                              ? TextOverflow.visible
                                              : TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: soort == 'globaal'
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: soort == 'globaal'
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                                child: Text(
                                  soort == 'globaal' ? 'GLOBAAL' : 'GEBRUIKER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: soort == 'globaal'
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ontvanger,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(datum),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _typeColor(tipe).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tipe.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _typeColor(tipe),
                                  ),
                                ),
                              ),
                              if (kennisgewings.length > 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.group,
                                        size: 12,
                                        color: Colors.purple,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${kennisgewings.length}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (kennisgewings.length > 1)
                      OutlinedButton.icon(
                        onPressed: () => _toonGroepDetails(context),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Bekyk Groep'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: tipe == 'help' ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Redigeer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tipe == 'help'
                            ? Colors.grey
                            : Colors.blue,
                        side: BorderSide(
                          color: tipe == 'help' ? Colors.grey : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Verwyder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toonGroepDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.purple, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groep Kennisgewings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                            ),
                          ),
                          Text(
                            '${kennisgewings.length} kennisgewings gestuur saam',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
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
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: kennisgewings.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final k = kennisgewings[index];
                    final soort = k['_kennisgewing_soort'] ?? 'globaal';

                    String ontvanger = 'Alle gebruikers';
                    if (soort == 'gebruiker') {
                      final gebruiker = k['gebruikers'];
                      if (gebruiker != null) {
                        ontvanger =
                            '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']} (${gebruiker['gebr_epos']})';
                      }
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context);
                        _toonKennisgewingDetail(context, k);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: soort == 'globaal'
                                    ? Colors.green
                                    : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ontvanger,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toonKennisgewingDetail(BuildContext context, Map<String, dynamic> k) {
    final soort = k['_kennisgewing_soort'] ?? 'globaal';
    final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final datum = DateTime.parse(
      k['kennis_geskep_datum'] ?? k['glob_kennis_geskep_datum'],
    );
    final titel = k['kennis_titel'] ?? k['glob_kennis_titel'] ?? '';
    final beskrywing =
        k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? 'Kennisgewing';

    String ontvanger = 'Alle gebruikers';
    if (soort == 'gebruiker') {
      final gebruiker = k['gebruikers'];
      if (gebruiker != null) {
        ontvanger =
            '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']} (${gebruiker['gebr_epos']})';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _typeColor(tipe).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _typeColor(tipe).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(_typeIcon(tipe), color: _typeColor(tipe), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kennisgewing Besonderhede',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    _formatDate(datum),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _typeColor(tipe).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _typeColor(tipe).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _typeIcon(tipe),
                          color: _typeColor(tipe),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tipe.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _typeColor(tipe),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: soort == 'globaal'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: soort == 'globaal'
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          child: Text(
                            soort == 'globaal' ? 'GLOBAAL' : 'GEBRUIKER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: soort == 'globaal'
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (titel.isNotEmpty) ...[
                      Text(
                        titel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Builder(
                      builder: (context) {
                        String formatted = beskrywing;
                        if (tipe == 'help') {
                          // Ensure message + newline + E-pos: email
                          String? helpEmail;
                          final regex = RegExp(
                            r'E-pos:\s*([^\s]+)',
                            caseSensitive: false,
                          );
                          final match = regex.firstMatch(beskrywing);
                          if (match != null && match.groupCount >= 1) {
                            helpEmail = match.group(1);
                          } else {
                            final lines = beskrywing
                                .split('\n')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (lines.isNotEmpty) {
                              final last = lines.last;
                              final emailRegex = RegExp(
                                r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
                                caseSensitive: false,
                              );
                              final emailMatch = emailRegex.firstMatch(last);
                              if (emailMatch != null)
                                helpEmail = emailMatch.group(0);
                            }
                          }

                          final messageOnly = beskrywing
                              .split('\n')
                              .where(
                                (line) => !line.trim().toLowerCase().startsWith(
                                  'e-pos',
                                ),
                              )
                              .join('\n')
                              .trim();

                          if (helpEmail != null) {
                            formatted = messageOnly.isNotEmpty
                                ? '$messageOnly\nE-pos: $helpEmail'
                                : 'E-pos: $helpEmail';
                          } else {
                            formatted = messageOnly.isNotEmpty
                                ? messageOnly
                                : beskrywing;
                          }
                        }

                        return Text(
                          formatted,
                          style: TextStyle(
                            fontSize: titel.isNotEmpty ? 16 : 18,
                            fontWeight: titel.isNotEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                            height: 1.5,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ontvanger: $ontvanger',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gestuur op: ${_formatDate(datum)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maak Toe'),
          ),
        ],
      ),
    );
  }
}

// Dialog vir skep/redigeer kennisgewings
class _SkepRedigeerDialog extends StatefulWidget {
  final Map<String, dynamic>? kennisgewing;
  final List<Map<String, dynamic>> gebruikers;

  const _SkepRedigeerDialog({this.kennisgewing, required this.gebruikers});

  @override
  State<_SkepRedigeerDialog> createState() => _SkepRedigeerDialogState();
}

class _SkepRedigeerDialogState extends State<_SkepRedigeerDialog> {
  final TextEditingController _titelCtrl = TextEditingController();
  final TextEditingController _kortCtrl = TextEditingController();
  String _nuweTipe = 'info';
  String _nuweDoelgroep = 'alle';
  List<String> _selectedGebruikerIds = [];
  bool _isRedigeer = false;

  @override
  void initState() {
    super.initState();

    if (widget.kennisgewing != null) {
      _isRedigeer = true;
      final k = widget.kennisgewing!;
      _titelCtrl.text = k['kennis_titel'] ?? k['glob_kennis_titel'] ?? '';
      _kortCtrl.text =
          k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? '';
      _nuweTipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
      _nuweDoelgroep = k['_kennisgewing_soort'] == 'globaal'
          ? 'alle'
          : 'spesifiek';
    }
  }

  @override
  void dispose() {
    _titelCtrl.dispose();
    _kortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            _isRedigeer ? Icons.edit : Icons.add_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            _isRedigeer ? 'Redigeer Kennisgewing' : 'Skep Nuwe Kennisgewing',
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _titelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titel (opsioneel)',
                  hintText: 'Voer die kennisgewing titel in...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kortCtrl,
                decoration: const InputDecoration(
                  labelText: 'Boodskap *',
                  hintText: 'Voer die kennisgewing boodskap in...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _nuweTipe,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipe *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Inligting'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'waarskuwing',
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Waarskuwing'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'sukses',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Sukses'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'fout',
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Fout'),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _nuweTipe = v ?? 'info'),
              ),
              if (!_isRedigeer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _nuweDoelgroep,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Stuur Aan *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.send),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'alle',
                      child: Row(
                        children: [
                          Icon(Icons.public, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Alle Gebruikers (Globaal)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'admins',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.purple,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Slegs Admins'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'studente',
                      child: Row(
                        children: [
                          Icon(Icons.school, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Slegs Studente'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'personeel',
                      child: Row(
                        children: [
                          Icon(Icons.work, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Slegs Personeel'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'spesifiek',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Text('Spesifieke Gebruikers'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _nuweDoelgroep = v ?? 'alle'),
                ),

                if (_nuweDoelgroep == 'spesifiek') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kies Gebruikers (${_selectedGebruikerIds.length} gekies)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.gebruikers.length,
                            itemBuilder: (context, index) {
                              final gebruiker = widget.gebruikers[index];
                              final isSelected = _selectedGebruikerIds.contains(
                                gebruiker['gebr_id'],
                              );

                              return CheckboxListTile(
                                dense: true,
                                value: isSelected,
                                title: Text(
                                  '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']}',
                                ),
                                subtitle: Text(gebruiker['gebr_epos'] ?? ''),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedGebruikerIds.add(
                                        gebruiker['gebr_id'],
                                      );
                                    } else {
                                      _selectedGebruikerIds.remove(
                                        gebruiker['gebr_id'],
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Kanselleer'),
        ),
        FilledButton.icon(
          onPressed: _stuurKennisgewing,
          icon: Icon(_isRedigeer ? Icons.check : Icons.send),
          label: Text(_isRedigeer ? 'Opdateer' : 'Stuur Kennisgewing'),
        ),
      ],
    );
  }

  Future<void> _stuurKennisgewing() async {
    if (_kortCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul asseblief die boodskap in')),
      );
      return;
    }

    if (!_isRedigeer &&
        _nuweDoelgroep == 'spesifiek' &&
        _selectedGebruikerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kies asseblief ten minste een gebruiker'),
        ),
      );
      return;
    }

    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      bool sukses = false;

      if (_isRedigeer) {
        // Redigeer bestaande kennisgewing
        final k = widget.kennisgewing!;
        final soort = k['_kennisgewing_soort'];

        if (soort == 'globaal') {
          sukses = await kennisgewingRepo.opdateerGlobaleKennisgewing(
            globKennisId: k['glob_kennis_id'],
            titel: _titelCtrl.text.trim().isNotEmpty
                ? _titelCtrl.text.trim()
                : '',
            beskrywing: _kortCtrl.text.trim(),
            tipeNaam: _nuweTipe,
          );
        } else {
          sukses = await kennisgewingRepo.opdateerKennisgewing(
            kennisId: k['kennis_id'],
            titel: _titelCtrl.text.trim().isNotEmpty
                ? _titelCtrl.text.trim()
                : '',
            beskrywing: _kortCtrl.text.trim(),
            tipeNaam: _nuweTipe,
          );
        }
      } else {
        // Skep nuwe kennisgewing
        switch (_nuweDoelgroep) {
          case 'alle':
            sukses = await kennisgewingRepo.stuurAanAlleGebruikers(
              titel: _titelCtrl.text.trim().isNotEmpty
                  ? _titelCtrl.text.trim()
                  : null,
              beskrywing: _kortCtrl.text.trim(),
              tipeNaam: _nuweTipe,
            );
            break;
          case 'admins':
            final admins = await Supabase.instance.client
                .from('gebruikers')
                .select('gebr_id')
                .not('admin_tipe_id', 'is', null);
            final adminIds = admins
                .map((a) => a['gebr_id'].toString())
                .toList();

            sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
              titel: _titelCtrl.text.trim().isNotEmpty
                  ? _titelCtrl.text.trim()
                  : null,
              gebrIds: adminIds,
              beskrywing: _kortCtrl.text.trim(),
              tipeNaam: _nuweTipe,
            );
            break;
          case 'studente':
            final studente = await Supabase.instance.client
                .from('gebruikers')
                .select('gebr_id')
                .eq('gebr_tipe_id', 'student');
            final studentIds = studente
                .map((s) => s['gebr_id'].toString())
                .toList();

            sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
              titel: _titelCtrl.text.trim().isNotEmpty
                  ? _titelCtrl.text.trim()
                  : null,
              gebrIds: studentIds,
              beskrywing: _kortCtrl.text.trim(),
              tipeNaam: _nuweTipe,
            );
            break;
          case 'personeel':
            final personeel = await Supabase.instance.client
                .from('gebruikers')
                .select('gebr_id')
                .eq('gebr_tipe_id', 'personeel');
            final personeelIds = personeel
                .map((p) => p['gebr_id'].toString())
                .toList();

            sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
              titel: _titelCtrl.text.trim().isNotEmpty
                  ? _titelCtrl.text.trim()
                  : null,
              gebrIds: personeelIds,
              beskrywing: _kortCtrl.text.trim(),
              tipeNaam: _nuweTipe,
            );
            break;
          case 'spesifiek':
            sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
              titel: _titelCtrl.text.trim().isNotEmpty
                  ? _titelCtrl.text.trim()
                  : null,
              gebrIds: _selectedGebruikerIds,
              beskrywing: _kortCtrl.text.trim(),
              tipeNaam: _nuweTipe,
            );
            break;
        }
      }

      if (sukses && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRedigeer
                  ? 'Kennisgewing suksesvol opgedateer!'
                  : 'Kennisgewing suksesvol gestuur!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRedigeer
                  ? 'Fout met opdateer kennisgewing!'
                  : 'Fout met stuur kennisgewing!',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
