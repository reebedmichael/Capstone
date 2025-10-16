import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/auth_providers.dart';

class HulpPage extends ConsumerStatefulWidget {
  const HulpPage({super.key});

  @override
  ConsumerState<HulpPage> createState() => _HulpPageState();
}

class _HulpPageState extends ConsumerState<HulpPage> {
  int? openFAQ; // Track which FAQ is expanded
  bool isLoading = false;
  String suksesBoodskap = '';
  String? algemeneFout;

  // Form controllers
  final naamCtrl = TextEditingController();
  final eposCtrl = TextEditingController();
  final onderwerpCtrl = TextEditingController();
  final boodskapCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prefill form fields when user profile is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final userProfileAsync = ref.read(userProfileProvider);
    userProfileAsync.whenData((profile) {
      if (profile != null && mounted) {
        final naam = profile['gebr_naam'] as String? ?? '';
        final van = profile['gebr_van'] as String? ?? '';
        final epos = profile['gebr_epos'] as String? ?? '';

        if (naam.isNotEmpty) {
          naamCtrl.text = '$naam $van';
        }
        if (epos.isNotEmpty) {
          eposCtrl.text = epos;
        }
      }
    });
  }

  final List<Map<String, String>> faqItems = [
    {
      "vraag": "Hoe voeg ek 'n nuwe kositem by die spyskaart?",
      "antwoord":
          "Gaan na 'Spyskaart' en dan 'Kositems' vanaf die paneelbord. Klik op 'Voeg Nuwe Item By' en vul alle velde in. Maak seker om bestanddele en allergene te spesifiseer.",
    },
    {
      "vraag": "Hoe kan ek bestellings se status verander?",
      "antwoord":
          "In 'Bestelling Bestuur', klik op die pyl ikoon langs die bestelling status. Vir massa status opdateerings klik op die bovorder bestellings na knoppie en kies dan die status waarna die bestellings moet opgedateer word.",
    },
    {
      "vraag": "Wat doen ek as ek my wagwoord vergeet het?",
      "antwoord":
          "Klik op 'Vergeet wagwoord?' op die tekenin skerm of die Instellings skerm. 'n Herstel skakel sal na jou geregistreerde e-pos gestuur word.",
    },
    {
      "vraag": "Hoe keur ek nuwe admin gebruikers goed?",
      "antwoord":
          "Gaan na 'Gebruikers Bestuur' en soek vir gebruikers met 'Wag Goedkeuring' status. Klik op die admin tipe om hulle goed te keur.",
    },
    {
      "vraag": "Kan ek templates vir gereelde spyskaart items skep?",
      "antwoord":
          "Ja! Gebruik 'Templates' om kositem templates te skep wat jy later kan hergebruik. Jy kan ook week templates skep vir gereelde spyskaart beplanning.",
    },
    {
      "vraag": "Hoe genereer ek verslae?",
      "antwoord":
          "Die 'Verslae' skerm bied gedetailleerde analise. Kies jou tydperk en klik 'Eksporteer CSV' om data as CSV af te laai.",
    },
  ];

  void _stuurNavraag() async {
    // Only validate subject and message since name and email are read-only
    if (onderwerpCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onderwerp is verpligtend'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (boodskapCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boodskap is verpligtend'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (boodskapCtrl.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boodskap moet ten minste 10 karakters wees'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig E-pos Stuur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Is jy seker jy wil hierdie navraag stuur?'),
            const SizedBox(height: 12),
            Text('E-pos: ${eposCtrl.text}'),
            Text('Onderwerp: ${onderwerpCtrl.text}'),
            const SizedBox(height: 8),
            const Text(
              'Die e-pos sal na debeermichael17@gmail.com gestuur word.',
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
            child: const Text('Stuur E-pos'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
      algemeneFout = null;
      suksesBoodskap = '';
    });

    try {
      // Get current user ID for email sending
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Geen ingeteken gebruiker gevind nie');
      }

      // Create email content
      final emailContent =
          '''
Navraag van: ${naamCtrl.text}
E-pos: ${eposCtrl.text}
Onderwerp: ${onderwerpCtrl.text}

Boodskap:
${boodskapCtrl.text}

---
Gestuur vanaf Spys Admin Web Interface
Tyd: ${DateTime.now().toString().split('.')[0]}
      ''';

      // Create HTML email content
      final htmlContent =
          '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Navraag van Spys Admin</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .field { margin-bottom: 15px; }
        .label { font-weight: bold; color: #555; }
        .value { margin-top: 5px; }
        .footer { margin-top: 20px; padding: 15px; background-color: #e9e9e9; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>📧 Nuwe Navraag van Spys Admin</h2>
        </div>
        <div class="content">
            <div class="field">
                <div class="label">👤 Naam:</div>
                <div class="value">${naamCtrl.text}</div>
            </div>
            <div class="field">
                <div class="label">📧 E-pos:</div>
                <div class="value">${eposCtrl.text}</div>
            </div>
            <div class="field">
                <div class="label">📋 Onderwerp:</div>
                <div class="value">${onderwerpCtrl.text}</div>
            </div>
            <div class="field">
                <div class="label">💬 Boodskap:</div>
                <div class="value">${boodskapCtrl.text}</div>
            </div>
        </div>
        <div class="footer">
            Gestuur vanaf Spys Admin Web Interface<br>
            Tyd: ${DateTime.now().toString().split('.')[0]}
        </div>
    </div>
</body>
</html>
      ''';

      // Send email directly to debeermichael17@gmail.com
      final response = await Supabase.instance.client.functions.invoke(
        'send-email',
        body: {
          'to': 'debeermichael17@gmail.com',
          'subject': 'Navraag: ${onderwerpCtrl.text}',
          'html': htmlContent,
          'text': emailContent,
        },
      );

      final success = response.status == 200;

      if (!mounted) return;

      if (success) {
        setState(() {
          suksesBoodskap =
              "✅ E-pos suksesvol gestuur! Ons span sal jou binnekort kontak.";
          isLoading = false;
        });

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text('E-pos Gestuur'),
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
                        Text('📧 Naam: ${naamCtrl.text}'),
                        Text('📧 E-pos: ${eposCtrl.text}'),
                        Text('📋 Onderwerp: ${onderwerpCtrl.text}'),
                        Text(
                          '⏰ Gestuur: ${DateTime.now().toString().split('.')[0]}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ons ondersteuning span sal jou binnekort kontak.',
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
        }

        // Also show snackbar for additional feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.email, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(suksesBoodskap)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Sluit',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Kon nie e-pos stuur nie. Probeer weer later.');
      }
    } catch (e) {
      // Handle any errors during email sending
      setState(() {
        algemeneFout = "Fout tydens e-pos stuur: ${e.toString()}";
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(algemeneFout!), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    // Don't clear name and email as they are read-only and prefilled
    onderwerpCtrl.clear();
    boodskapCtrl.clear();

    // Clear success message after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => suksesBoodskap = '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for user profile changes and prefill fields
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null && mounted) {
          final naam = profile['gebr_naam'] as String? ?? '';
          final van = profile['gebr_van'] as String? ?? '';
          final epos = profile['gebr_epos'] as String? ?? '';

          if (naam.isNotEmpty && naamCtrl.text.isEmpty) {
            naamCtrl.text = '$naam $van';
          }
          if (epos.isNotEmpty && eposCtrl.text.isEmpty) {
            eposCtrl.text = epos;
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
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
              leading: Icon(Icons.phone),
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
              subtitle: Text("debeermichael17@gmail.com"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: AppColors.primary),
              title: Text("Telefoon Ondersteuning"),
              subtitle: Text("071 123 4567"),
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
              subtitle: Text(
                "Akademia Leriba-kampus, 245 End St, Clubview, Centurion, 0157",
              ),
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
            ...tips.map(
              (t) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                title: Text(t, style: const TextStyle(fontSize: 14)),
              ),
            ),
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
        child: Column(
          children: [
            Text(
              "Stuur 'n Navraag",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),

            // Naam & Epos (Read-only, prefilled from user profile)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: naamCtrl,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Jou Naam",
                      border: OutlineInputBorder(),
                      filled: true,
                      // fillColor: Colors.grey,
                    ),
                    // style: const TextStyle(color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: eposCtrl,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "E-pos Adres",
                      border: OutlineInputBorder(),
                      filled: true,
                      // fillColor: Colors.grey,
                    ),
                    // style: const TextStyle(color: Colors.black87),
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
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.email),
              label: Text(
                isLoading ? "Stuur E-pos..." : "Stuur E-pos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: isLoading ? null : _stuurNavraag,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = mediaWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title section
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.help_outline, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hulp en Ondersteuning",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Kry hulp en stuur navrae",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Left section: logo + title + description
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.help_outline, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hulp en Ondersteuning",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Kry hulp en stuur navrae",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
