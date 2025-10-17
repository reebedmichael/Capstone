import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String searchQuery = '';
  String selectedCategory = 'all';
  bool isSending = false;
  String? algemeneFout;
  String suksesBoodskap = '';

  final List<Map<String, String>> faqItems = [
    {
      'id': '1',
      'question': 'Hoe sien ek my transaksie geskiedenis?',
      'answer':
          "Gaan na die Beursie seksie, kies 'Transaksies'. Jy sal die transaksie geskiedenis vir jou rekening sien.",
      'category': 'wallet',
    },
    {
      'id': '2',
      'question': 'Hoe laai ek my beursie?',
      'answer':
          "Gaan na die Beursie seksie, kies 'Laai Beursie', kies 'n bedrag, en volg die betaalinstruksies. Jy kan met bankkaart, SnapScan of EFT betaal.",
      'category': 'wallet',
    },
    {
      'id': "3",
      'question': "Kan ek my bestelling kanselleer?",
      'answer':
          'Ja, bestellings kan gekanselleer totdat die bestelling uit gestuur word vir aflewering. Gaan na "Bestellings" en klik "Kanselleer" by die relevante bestelling.',
      'category': "orders",
    },
    {
      'id': "4",
      'question': "Hoe werk die QR-kode afhaal?",
      'answer':
          "Op die dag van jou bestelling sal jy 'n QR-kode kry. Wys hierdie kode by die afhaallokasie aan die personeel om jou kos te kry.",
      'category': "orders",
    },
    {
      'id': "5",
      'question': "Wanneer ontvang ek my maandelikse toelae?",
      'answer':
          "Indien jy kwalifiseer vir 'n toelaag sal die toelae outomaties bygevoeg word op 'n datum gespesifiseer deur admin (gewoonlik 1ste van die maand). ",
      'category': "allowance",
    },
    {
      'id': "6",
      'question': "Hoe verander ek my dieet voorkeure?",
      'answer':
          'Gaan na "Profiel", en opdateer jou dieëtvereistes onder die relevante seksie.',
      'category': "account",
    },
    {
      'id': "7",
      'question': "Wat as ek my wagwoord vergeet het?",
      'answer':
          'Klik "Wagwoord vergeet?" op die teken-in skerm of die skakel in die Instellings skerm. Jy sal \'n e-pos ontvang met instruksies om jou wagwoord te herstel.',
      'category': "account",
    },
    {
      'id': "8",
      'question': "Hoe gee ek terugvoer op my bestelling?",
      'answer':
          'Na \'n suksesvolle bestelling kan jy terugvoer gee in die "Bestellings" seksie. Klik "Voltooi" seksie en kies "Terugvoer" by die relevante bestelling.',
      'category': "orders",
    },
    // Add more FAQ items similarly
  ];

  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'Alles'},
    {'id': 'account', 'name': 'Rekening'},
    {'id': 'orders', 'name': 'Bestellings'},
    {'id': 'wallet', 'name': 'Beursie'},
    {'id': 'allowance', 'name': 'Toelae'},
  ];

  final TextEditingController naamController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController onderwerpController = TextEditingController();
  final TextEditingController boodskapController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillUserData());
  }

  Future<void> _prefillUserData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final row = await Supabase.instance.client
          .from('gebruikers')
          .select('gebr_naam, gebr_van, gebr_epos')
          .eq('gebr_id', currentUser.id)
          .maybeSingle();

      if (row != null && mounted) {
        final String naam = (row['gebr_naam'] ?? '').toString();
        final String van = (row['gebr_van'] ?? '').toString();
        final String epos = (row['gebr_epos'] ?? '').toString();
        if (naam.isNotEmpty || van.isNotEmpty) {
          naamController.text = [
            naam,
            van,
          ].where((e) => e.isNotEmpty).join(' ');
        }
        if (epos.isNotEmpty) {
          emailController.text = epos;
        }
      }
    } catch (_) {
      // Ignore prefill errors
    }
  }

  void _sendQuery() async {
    // Validate only subject and message
    if (onderwerpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Onderwerp is verpligtend')));
      return;
    }

    if (boodskapController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Boodskap is verpligtend')));
      return;
    }

    if (boodskapController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boodskap moet ten minste 10 karakters wees'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig Navraag Stuur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Is jy seker jy wil hierdie navraag stuur?'),
            const SizedBox(height: 12),
            Text('E-pos: ${emailController.text}'),
            Text('Onderwerp: ${onderwerpController.text}'),
            const SizedBox(height: 8),
            const Text(
              'Die navraag sal as kennisgewing na alle admins gestuur word.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Stuur navraag'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSending = true;
      algemeneFout = null;
      suksesBoodskap = '';
    });

    try {
      // Create notification for all admins
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      // Get all admin users
      final admins = await Supabase.instance.client
          .from('gebruikers')
          .select('gebr_id')
          .not('admin_tipe_id', 'is', null);

      final adminIds = admins.map((a) => a['gebr_id'].toString()).toList();

      if (adminIds.isNotEmpty) {
        // Create notification content
        final titel = onderwerpController.text.trim();
        final beskrywing =
            '${boodskapController.text.trim()}\n\nE-pos: ${emailController.text}';

        // Send notification to all admins
        final sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
          titel: titel,
          gebrIds: adminIds,
          beskrywing: beskrywing,
          tipeNaam: 'help',
        );

        if (!mounted) return;

        if (sukses) {
          setState(() {
            suksesBoodskap =
                '✅ Navraag suksesvol gestuur! Ons span sal jou binnekort kontak.';
            isSending = false;
          });
        } else {
          throw Exception('Kon nie navraag stuur nie');
        }
      } else {
        throw Exception('Geen admin gebruikers gevind nie');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        algemeneFout = "Fout tydens navraag stuur: ${e.toString()}";
        isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(algemeneFout!), backgroundColor: Colors.red),
      );
      return;
    }

    // Success dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Navraag Gestuur'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jou navraag is suksesvol gestuur!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Naam: ${naamController.text}'),
                  Text('📧 E-pos: ${emailController.text}'),
                  Text('📋 Onderwerp: ${onderwerpController.text}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ons admin span het jou navraag ontvang en sal jou binnekort kontak.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(suksesBoodskap)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Sluit',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _clearForm() {
    onderwerpController.clear();
    boodskapController.clear();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = faqItems.where((item) {
      final matchesSearch =
          item['question']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item['answer']!.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'all' || item['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hulp & Ondersteuning'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/settings');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kontak Ons",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text('071 123 4567'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.mail,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text('ondersteuning@spys.ac.za'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 8),
                        Text('Ure: Maandag-Vrydag 08:00-17:00'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FAQ Search
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Soek in vrae...',
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Category Buttons
            Wrap(
              spacing: 8,
              children: categories.map((category) {
                final bool isSelected = selectedCategory == category['id'];
                return ChoiceChip(
                  label: Text(category['name']!),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category['id']!;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // FAQ List
            if (filteredFAQs.isEmpty)
              const Center(child: Text('Geen FAQ items gevind nie'))
            else
              ...filteredFAQs.map(
                (item) => ExpansionTile(
                  title: Text(item['question']!),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item['answer']!),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Contact Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Stuur 'n Navraag",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: naamController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Jou Naam',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-pos Adres',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: onderwerpController,
                      decoration: const InputDecoration(
                        labelText: 'Onderwerp',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: boodskapController,
                      decoration: const InputDecoration(
                        labelText: 'Jou Boodskap',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isSending ? null : _sendQuery,
                      icon: isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.email),
                      label: Text(
                        isSending ? 'Stuur Navraag...' : 'Stuur Navraag',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Links
            _buildCard(
              title: "Nuttige Skakels",
              icon: Icons.help,
              children: [
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text("Akademia"),
                  onTap: () async {
                    final Uri url = Uri.parse('https://akademia.ac.za/');
                    if (await canLaunch(url.toString())) {
                      await launch(url.toString());
                    } else {
                      // If the URL can't be launched, you can show a message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kan nie die webwerf oopmaak nie'),
                        ),
                      );
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profiel"),
                  onTap: () => context.go('/profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Instellings"),
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tips
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Wenke',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Kyk eers die FAQ voordat jy ons kontak'),
                    Text('• Sluit jou gebruiker ID in by navrae'),
                    Text('• Wees so spesifiek as moontlik oor jou probleem'),
                    Text('• Ons antwoord gewoonlik binne 24 uur'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
