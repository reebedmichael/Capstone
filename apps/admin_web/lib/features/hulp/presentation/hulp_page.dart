import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HulpPage extends StatefulWidget {
  const HulpPage({super.key});

  @override
  State<HulpPage> createState() => _HulpPageState();
}

class _HulpPageState extends State<HulpPage> {
  int? openFAQ; // Track which FAQ is expanded
  bool isLoading = false;
  String suksesBoodskap = '';
  String? algemeneFout;

  // Form controllers
  final naamCtrl = TextEditingController();
  final eposCtrl = TextEditingController();
  final onderwerpCtrl = TextEditingController();
  final boodskapCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> faqItems = [
    {
      "vraag": "Hoe voeg ek 'n nuwe kositem by die spyskaart?",
      "antwoord":
          "Gaan na 'Spyskaart Bestuur' vanaf die dashboard. Klik op 'Voeg Nuwe Item By' en vul alle velde in. Maak seker om bestanddele en allergene te spesifiseer.",
    },
    {
      "vraag": "Hoe kan ek bestellings se status verander?",
      "antwoord":
          "In 'Bestelling Bestuur', klik op die wysig ikoon langs die bestelling. Kies die nuwe status en voeg 'n rede by indien nodig.",
    },
    {
      "vraag": "Wat doen ek as ek my wagwoord vergeet het?",
      "antwoord":
          "Klik op 'Vergeet wagwoord?' op die tekenin skerm. 'n Herstel skakel sal na jou geregistreerde e-pos gestuur word.",
    },
    {
      "vraag": "Hoe keur ek nuwe admin gebruikers goed?",
      "antwoord":
          "Gaan na 'Gebruikers Bestuur' en soek vir gebruikers met 'Wag Goedkeuring' status. Klik op die groen vinkje om hulle goed te keur.",
    },
    {
      "vraag": "Kan ek templates vir gereelde spyskaart items skep?",
      "antwoord":
          "Ja! Gebruik 'Templates' om kositem templates te skep wat jy later kan hergebruik. Jy kan ook week templates skep vir gereelde spyskaart beplanning.",
    },
    {
      "vraag": "Hoe genereer ek verslae?",
      "antwoord":
          "Die 'Verslae' skerm bied gedetailleerde analise. Kies jou tydperk en klik 'Genereer Verslag' om data as PDF of Excel af te laai.",
    },
  ];

  void _stuurNavraag() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      algemeneFout = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        suksesBoodskap =
            "Jou navraag is gestuur! Ons span sal jou binnekort kontak.";
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(suksesBoodskap), backgroundColor: Colors.green),
      );

      naamCtrl.clear();
      eposCtrl.clear();
      onderwerpCtrl.clear();
      boodskapCtrl.clear();

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => suksesBoodskap = '');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text("Hulp en Ondersteuning")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (algemeneFout != null)
              Card(
                color: Colors.red.shade100,
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(algemeneFout!),
                ),
              ),
            const SizedBox(height: 16),

            // Layout: Contact Info + Tips | FAQ + Form
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 900;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        children: [
                          _buildContactCard(),
                          const SizedBox(height: 16),
                          _buildTipsCard(),
                        ],
                      ),
                    ),
                    if (isWide) const SizedBox(width: 16),
                    // Right Column
                    Expanded(
                      flex: isWide ? 2 : 0,
                      child: Column(
                        children: [
                          _buildFAQCard(),
                          const SizedBox(height: 16),
                          _buildNavraagForm(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            ListTile(
              leading: Icon(Icons.phone, color: Colors.black),
              title: Text(
                "Kontak Besonderhede",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: Text("Kontak ons direk vir onmiddelike hulp"),
            ),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.mail, color: AppColors.primary),
              title: Text("E-pos Ondersteuning"),
              subtitle: Text("ondersteuning@voedselbestuur.co.za"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: AppColors.primary),
              title: Text("Telefoon Ondersteuning"),
              subtitle: Text("021 123 4567"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.access_time, color: AppColors.primary),
              title: Text("Ondersteuning Ure"),
              subtitle: Text("Ma-Vr: 08:00 - 17:00"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: AppColors.primary),
              title: Text("Kantoor Adres"),
              subtitle: Text("123 Hulp Straat, Kaapstad, 8001"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      "Kyk gereeld jou kennisgewings vir belangrike opdaterings",
      "Gebruik templates om tyd te bespaar met gereelde take",
      "Genereer gereelde verslae om tendense te monitor",
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .start, // Optional: Align the content to the start
          children: [
            Text(
              "Vinige wenke",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8), // Optional: Space between title and list
            ...tips
                .map(
                  (t) => ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    title: Text(t, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help),
                Text(
                  " Gereelde Vrae (FAQ)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Vind antwoorde op algemene vrae"),
            SizedBox(height: 20),
            ExpansionPanelList(
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (i, isOpen) {
                setState(() {
                  openFAQ = openFAQ == i ? null : i; // toggle
                });
              },
              children: faqItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isExpanded = openFAQ == i;
                return ExpansionPanel(
                  canTapOnHeader: true,
                  isExpanded: isExpanded,
                  headerBuilder: (context, _) => ListTile(
                    title: Text(
                      item["vraag"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      item["antwoord"]!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavraagForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Stuur 'n Navraag",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 16),

              // Naam & Epos
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: naamCtrl,
                      decoration: const InputDecoration(
                        labelText: "Jou Naam",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? "Naam is verpligtend"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: eposCtrl,
                      decoration: const InputDecoration(
                        labelText: "E-pos Adres",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "E-pos is verpligtend";
                        }
                        final regex = RegExp(r'^\S+@\S+\.\S+$');
                        if (!regex.hasMatch(v))
                          return "Ongeldige e-pos formaat";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Onderwerp
              TextFormField(
                controller: onderwerpCtrl,
                decoration: const InputDecoration(
                  labelText: "Onderwerp",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Onderwerp is verpligtend"
                    : null,
              ),
              const SizedBox(height: 12),

              // Boodskap
              TextFormField(
                controller: boodskapCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Jou Boodskap",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Boodskap is verpligtend";
                  } else if (v.length < 10) {
                    return "Boodskap moet ten minste 10 karakters wees";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Submit button
              ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(isLoading ? "Stuur Navraag..." : "Stuur Navraag"),
                onPressed: isLoading ? null : _stuurNavraag,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
