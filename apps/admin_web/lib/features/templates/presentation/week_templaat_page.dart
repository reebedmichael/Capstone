import 'package:flutter/material.dart';

class KositemTemplate {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final String? prent;

  KositemTemplate({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prent,
  });

  // Omskep na Map vir stoor
  Map<String, dynamic> toMap() => {
    'id': id,
    'naam': naam,
    'bestanddele': bestanddele,
    'allergene': allergene,
    'prys': prys,
    'kategorie': kategorie,
    'prent': prent,
  };

  // Bou uit Map wanneer jy laai
  factory KositemTemplate.fromMap(Map<String, dynamic> map) {
    return KositemTemplate(
      id: map['id'],
      naam: map['naam'],
      bestanddele: List<String>.from(map['bestanddele']),
      allergene: List<String>.from(map['allergene']),
      prys: (map['prys'] as num).toDouble(),
      kategorie: map['kategorie'],
      prent: map['prent'],
    );
  }
}

class WeekTemplaatPage extends StatefulWidget {
  const WeekTemplaatPage({super.key});

  @override
  State<WeekTemplaatPage> createState() => _WeekTemplaatPageState();
}

class _WeekTemplaatPageState extends State<WeekTemplaatPage>
    with TickerProviderStateMixin {
  bool showFormModal = false;
  bool showDeleteModal = false;
  bool showLoadModal = false;

  String? activeTemplateId;
  String activeDay = 'maandag';
  String successMessage = '';

  final formNameController = TextEditingController();
  final formDescController = TextEditingController();
  List<ScrollController> _scrollControllers = [];
  List<ScrollController> _scrollTemplateControllers = [];
  Map<String, List<KositemTemplate>> formDays = {
    'maandag': [],
    'dinsdag': [],
    'woensdag': [],
    'donderdag': [],
    'vrydag': [],
    'saterdag': [],
    'sondag': [],
  };

  final List<Map<String, dynamic>> weekTemplates = [];

  final Map<String, TextEditingController> searchControllers = {
    'maandag': TextEditingController(),
    'dinsdag': TextEditingController(),
    'woensdag': TextEditingController(),
    'donderdag': TextEditingController(),
    'vrydag': TextEditingController(),
    'saterdag': TextEditingController(),
    'sondag': TextEditingController(),
  };

  final daeVanWeek = const [
    {'key': 'maandag', 'label': 'Maandag'},
    {'key': 'dinsdag', 'label': 'Dinsdag'},
    {'key': 'woensdag', 'label': 'Woensdag'},
    {'key': 'donderdag', 'label': 'Donderdag'},
    {'key': 'vrydag', 'label': 'Vrydag'},
    {'key': 'saterdag', 'label': 'Saterdag'},
    {'key': 'sondag', 'label': 'Sondag'},
  ];
  /////Net vir DA4////////////////////////////////////////////////////////
  final List<KositemTemplate> templates = [
    KositemTemplate(
      id: "1",
      naam: "Beesburger",
      bestanddele: ["Beesvleis", "Broodjie", "Kaas", "Tamatie", "Slaai"],
      allergene: ["Gluten", "Melk"],
      prys: 85.00,
      kategorie: "Hoofgereg",
    ),
    KositemTemplate(
      id: "2",
      naam: "Ontbyt Omelet",
      bestanddele: ["Eiers", "Kaas", "Uie", "Spinasie"],
      allergene: ["Eiers", "Melk"],
      prys: 55.00,
      kategorie: "Ontbyt",
    ),
    KositemTemplate(
      id: "3",
      naam: "Vrugteslaai",
      bestanddele: ["Appel", "Bessie", "Druiwe", "Piesang"],
      allergene: [],
      prys: 45.00,
      kategorie: "Ligte ete",
    ),
    KositemTemplate(
      id: "4",
      naam: "Koffie Latte",
      bestanddele: ["Koffie", "Melk", "Suiker"],
      allergene: ["Melk"],
      prys: 30.00,
      kategorie: "Drankie",
      prent: null,
    ),
  ];
  @override
  void initState() {
    super.initState();
    _scrollControllers = List.generate(
      daeVanWeek.length,
      (index) => ScrollController(),
    );
    // ✅ Maak seker weekTemplates het ten minste 1 voorbeeld
    if (weekTemplates.isEmpty) {
      weekTemplates.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'naam': 'Week Spyskaart',
        'beskrywing': 'Voorbeeld week spyskaart met geregte',
        'dae': {
          'maandag': [templates[0].toMap()], // Beesburger
          'dinsdag': [templates[1].toMap()], // Ontbyt Omelet
          'woensdag': [templates[2].toMap()], // Vrugteslaai
          'donderdag': [templates[3].toMap()], // Koffie Latte
          'vrydag': [],
          'saterdag': [],
          'sondag': [],
        },
        'geskep': DateTime.now(),
      });
    }
  }

  /////Net vir DA4////////////////////////////////////////////////////////
  ///@override
  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    for (var controller in _scrollTemplateControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void resetForm() {
    formNameController.clear();
    formDescController.clear();
    formDays.updateAll((key, value) => <KositemTemplate>[]); // ✅ belangrik
    for (var c in searchControllers.values) {
      c.clear();
    }
    activeTemplateId = null;
    activeDay = 'maandag';
  }

  void saveTemplate() {
    if (formNameController.text.trim().isEmpty) return;

    final daeData = formDays.map(
      (dag, kosLys) => MapEntry(dag, kosLys.map((k) => k.toMap()).toList()),
    );

    if (activeTemplateId != null) {
      final idx = weekTemplates.indexWhere((t) => t['id'] == activeTemplateId);
      if (idx != -1) {
        final ouGespep = weekTemplates[idx]['geskep']; // ✅ behou
        weekTemplates[idx] = {
          'id': activeTemplateId,
          'naam': formNameController.text.trim(),
          'beskrywing': formDescController.text.trim(),
          'dae': daeData,
          'geskep': ouGespep,
          'gewysig': DateTime.now(), // opsioneel
        };
      }
      successMessage = 'Week templaat suksesvol gewysig';
    } else {
      weekTemplates.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'naam': formNameController.text.trim(),
        'beskrywing': formDescController.text.trim(),
        'dae': daeData,
        'geskep': DateTime.now(),
      });
      successMessage = 'Week templaat suksesvol bygevoeg';
    }

    setState(() {
      showFormModal = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => successMessage = '');
    });
  }

  void deleteTemplate() {
    if (activeTemplateId != null) {
      weekTemplates.removeWhere((t) => t['id'] == activeTemplateId);
      successMessage = 'Week templaat suksesvol verwyder';
    }
    setState(() {
      showDeleteModal = false;
      activeTemplateId = null;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => successMessage = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Week Templates'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Skep Nuwe Templaat'),
            onPressed: () {
              resetForm();
              setState(() => showFormModal = true);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: weekTemplates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('Geen Week Templates'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Skep Eerste Templaat'),
                            onPressed: () {
                              resetForm();
                              setState(() => showFormModal = true);
                            },
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 4 / 3,
                          ),
                      itemCount: weekTemplates.length,
                      itemBuilder: (context, index) {
                        final templaat = weekTemplates[index];

                        // Ensure each item in the list has a unique ScrollController
                        if (_scrollTemplateControllers.length <= index) {
                          _scrollTemplateControllers.add(ScrollController());
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  templaat['naam'],
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if ((templaat['beskrywing'] as String)
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      templaat['beskrywing'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    controller:
                                        _scrollTemplateControllers[index],
                                    child: SingleChildScrollView(
                                      controller:
                                          _scrollTemplateControllers[index],
                                      child: Table(
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.top,
                                        children: daeVanWeek.map((dag) {
                                          final dagKey = dag['key'] as String;
                                          final kosMaps =
                                              (templaat['dae'][dagKey]
                                                      as List<dynamic>)
                                                  .cast<Map<String, dynamic>>();

                                          return TableRow(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: Text(
                                                  dag['label'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  4.0,
                                                ),
                                                child: kosMaps.isEmpty
                                                    ? const Text('-')
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: kosMaps.map((
                                                          map,
                                                        ) {
                                                          final item =
                                                              KositemTemplate.fromMap(
                                                                map,
                                                              );
                                                          return Card(
                                                            margin:
                                                                const EdgeInsets.only(
                                                                  bottom: 6,
                                                                ),
                                                            child: ListTile(
                                                              title: Text(
                                                                item.naam,
                                                              ),
                                                              subtitle: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    "Kategorie: ${item.kategorie}",
                                                                  ),
                                                                  Text(
                                                                    "Prys: R${item.prys.toStringAsFixed(2)}",
                                                                  ),
                                                                  if (item
                                                                      .bestanddele
                                                                      .isNotEmpty)
                                                                    Text(
                                                                      "Bestanddele: ${item.bestanddele.join(', ')}",
                                                                    ),
                                                                  if (item
                                                                      .allergene
                                                                      .isNotEmpty)
                                                                    Text(
                                                                      "Allergene: ${item.allergene.join(', ')}",
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .red,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Wysig'),
                                        onPressed: () {
                                          setState(() {
                                            formNameController.text =
                                                templaat['naam'] as String;
                                            formDescController.text =
                                                templaat['beskrywing']
                                                    as String;

                                            final Map<String, dynamic> daeMap =
                                                Map<String, dynamic>.from(
                                                  templaat['dae'] as Map,
                                                );

                                            formDays = daeMap
                                                .map<
                                                  String,
                                                  List<KositemTemplate>
                                                >((k, v) {
                                                  final list =
                                                      (v as List?) ?? const [];
                                                  final items = list.map((e) {
                                                    return KositemTemplate.fromMap(
                                                      Map<String, dynamic>.from(
                                                        e as Map,
                                                      ),
                                                    );
                                                  }).toList();
                                                  return MapEntry(k, items);
                                                });

                                            activeTemplateId =
                                                templaat['id'] as String;
                                            showFormModal = true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        activeTemplateId = templaat['id'];
                                        setState(() => showDeleteModal = true);
                                      },
                                    ),
                                  ],
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

      floatingActionButton: showFormModal
          ? _buildFormModal(context)
          : showDeleteModal
          ? _buildDeleteModal(context)
          : showLoadModal
          ? _buildLoadModal(context)
          : null,
    );
  }

  Widget _buildFormModal(BuildContext context) {
    return Dialog(
      child: DefaultTabController(
        length: daeVanWeek.length,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                activeTemplateId != null
                    ? 'Wysig Week Templaat'
                    : 'Skep Nuwe Week Templaat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: formNameController,
                decoration: const InputDecoration(
                  labelText: 'Templaat Naam *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: formDescController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Beskrywing',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                // isScrollable: true,
                tabs: daeVanWeek
                    .map((dag) => Tab(text: dag['label'] as String))
                    .toList(),
                onTap: (index) {
                  setState(() {
                    activeDay = daeVanWeek[index]['key'] as String;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: daeVanWeek.map((dag) {
                    final dagKey = dag['key'] as String;
                    int index = daeVanWeek.indexOf(
                      dag,
                    ); // To get the index for each tab
                    return Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            controller:
                                _scrollControllers[index], // Attach controller here
                            thumbVisibility: true,
                            child: ListView(
                              // primary: true,
                              controller:
                                  _scrollControllers[index], // Attach controller here
                              children: formDays[dagKey]!
                                  .map(
                                    (food) => ListTile(
                                      title: Text(food.naam),
                                      subtitle: Text(
                                        "${food.kategorie} • R${food.prys.toStringAsFixed(2)}",
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            formDays[dagKey]!.remove(food);
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        TextField(
                          controller: searchControllers[dagKey],
                          decoration: InputDecoration(
                            hintText: 'Soek kos vir ${dag['label']}',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(
                          height: 150,
                          child: ListView(
                            children: templates
                                .where(
                                  (t) =>
                                      t.naam.toLowerCase().contains(
                                        searchControllers[dagKey]!.text
                                            .toLowerCase(),
                                      ) &&
                                      !formDays[dagKey]!.any(
                                        (f) => f.id == t.id,
                                      ),
                                )
                                .map(
                                  (t) => ListTile(
                                    title: Text(t.naam),
                                    subtitle: Text(
                                      "${t.kategorie} • R${t.prys.toStringAsFixed(2)}",
                                    ),
                                    onTap: () {
                                      setState(() {
                                        formDays[dagKey]!.add(t);
                                        searchControllers[dagKey]!.clear();
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => showFormModal = false),
                      child: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveTemplate,
                      child: Text(
                        activeTemplateId != null
                            ? 'Stoor Wysigings'
                            : 'Skep Templaat',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteModal(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text('Bevestig Verwydering'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => showDeleteModal = false),
                    child: const Text('Kanselleer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: deleteTemplate,
                    child: const Text('Ja, Verwyder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadModal(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Laai Bestaande Templaat'),
            const SizedBox(height: 16),
            if (weekTemplates.isEmpty)
              const Text('Geen templates beskikbaar nie')
            else
              ...weekTemplates.map(
                (t) => ListTile(
                  title: Text(t['naam']),
                  subtitle: Text(t['beskrywing']),
                  onTap: () {
                    formNameController.text = t['naam'];
                    formDescController.text = t['beskrywing'];

                    formDays = t['dae'].map<String, List<KositemTemplate>>(
                      (k, v) => MapEntry(
                        k,
                        (v as List<dynamic>)
                            .map(
                              (map) => KositemTemplate.fromMap(
                                map as Map<String, dynamic>,
                              ),
                            )
                            .toList(),
                      ),
                    );

                    activeTemplateId = t['id'];
                    setState(() {
                      showLoadModal = false;
                      showFormModal = true;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
