import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String searchQuery = '';
  String selectedCategory = 'all';

  final List<Map<String, String>> faqItems = [
    {
      'id': '1',
      'question': 'Hoe registreer ek vir die app?',
      'answer':
          "Klik op 'Registreer' op die welkom skerm, vul jou besonderhede in, en volg die instruksies. Jy sal 'n verifikasie e-pos ontvang.",
      'category': 'account',
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
          'Ja, bestellings kan gekanselleer word binne 10 minute na plaasing. Gaan na "Bestellings" en klik "Kanselleer" by die relevante bestelling.',
      'category': "orders",
    },
    {
      'id': "4",
      'question': "Hoe werk die QR-kode afhaal?",
      'answer':
          "Na bestelling sal jy 'n QR-kode kry. Wys hierdie kode by die afhaallokasie aan die personeel om jou kos te kry.",
      'category': "orders",
    },
    {
      'id': "5",
      'question': "Wanneer ontvang ek my maandelikse toelae?",
      'answer':
          "Maandelikse toelaes word outomaties bygevoeg op die 1ste van elke maand. Studente ontvang R1000 en personeel R500.",
      'category': "allowance",
    },
    {
      'id': "6",
      'question': "Hoe verander ek my dieet voorkeure?",
      'answer':
          'Gaan na "Profiel", klik "Wysig Profiel", en updateer jou dieëtvereistes onder die relevante seksie.',
      'category': "account",
    },
    {
      'id': "7",
      'question': "Wat as ek my wagwoord vergeet het?",
      'answer':
          'Klik "Wagwoord vergeet?" op die teken-in skerm. Jy sal \'n e-pos ontvang met instruksies om jou wagwoord te herstel.',
      'category': "account",
    },
    {
      'id': "8",
      'question': "Hoe gee ek terugvoer op my bestelling?",
      'answer':
          'Na \'n suksesvolle bestelling kan jy terugvoer gee in die "Bestellings" seksie. Klik "Gee Terugvoer" by die relevante bestelling.',
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

  void _sendQuery() {
    if (naamController.text.isEmpty ||
        emailController.text.isEmpty ||
        onderwerpController.text.isEmpty ||
        boodskapController.text.isEmpty) {
      // Show error if any required field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul al die vereiste velde in.')),
      );
    } else {
      // If all fields are filled
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Navraag is gestuur.')));

      // You can also handle the submission logic here
      // For example, sending the data to the backend or API
    }
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
                      children: const [
                        Icon(Icons.phone, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('021 808 4622'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.mail, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('spys@sun.ac.za'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.access_time, color: Colors.grey),
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
                hintText: 'Soek in FAQ...',
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
                      decoration: const InputDecoration(labelText: 'Naam *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-pos *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: onderwerpController,
                      decoration: const InputDecoration(
                        labelText: 'Onderwerp *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: boodskapController,
                      decoration: const InputDecoration(
                        labelText: 'Boodskap *',
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _sendQuery,
                      child: const Text('Stuur Navraag'),
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
              color: Colors.green[50],
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
