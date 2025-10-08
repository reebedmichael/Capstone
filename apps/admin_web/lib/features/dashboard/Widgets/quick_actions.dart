import 'package:capstone_admin/features/dashboard/presentation/dashboard_page.dart';
import 'package:capstone_admin/features/templates/widgets/kositem_form_modal.dart';
import 'package:capstone_admin/features/templates/widgets/week_form_modal.dart';
import 'package:capstone_admin/features/templates/widgets/kos_item_templaat.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class QuickActions extends StatefulWidget {
  const QuickActions({
    super.key,
    required this.isLarge,
    required this.isMedium,
    required this.widget,
  });

  final bool isLarge;
  final bool isMedium;
  final DashboardPage widget;

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  // Controllers for KositemFormModal
  final GlobalKey<FormState> _kositemFormKey = GlobalKey<FormState>();
  final TextEditingController _naamController = TextEditingController();
  final TextEditingController _prysController = TextEditingController();
  final TextEditingController _bestanddeleController = TextEditingController();
  final TextEditingController _allergeneController = TextEditingController();
  final TextEditingController _beskrywingController = TextEditingController();

  List<String> _selectedCategories = [];
  final List<String> _allCategories = [
    'Ontbyt',
    'Middagete',
    'Aandete',
    'Snacks',
    'Drankies',
    'Nageregte',
  ];

  String? _selectedImage;
  bool _isKositemLoading = false;

  // Controllers for FormModal
  final TextEditingController _templateNameController = TextEditingController();
  final TextEditingController _templateDescController = TextEditingController();
  final Map<String, List<KositemTemplate>> _formDays = {
    'maandag': [],
    'dinsdag': [],
    'woensdag': [],
    'donderdag': [],
    'vrydag': [],
    'saterdag': [],
    'sondag': [],
  };
  final List<Map<String, String>> _daeVanWeek = [
    {'key': 'maandag', 'label': 'Maandag'},
    {'key': 'dinsdag', 'label': 'Dinsdag'},
    {'key': 'woensdag', 'label': 'Woensdag'},
    {'key': 'donderdag', 'label': 'Donderdag'},
    {'key': 'vrydag', 'label': 'Vrydag'},
    {'key': 'saterdag', 'label': 'Saterdag'},
    {'key': 'sondag', 'label': 'Sondag'},
  ];
  List<KositemTemplate> _templates = []; // Empty for now
  final Map<String, TextEditingController> _searchControllers = {};

  // Repositories
  late final KosTemplaatRepository _kosRepo;
  late final WeekTemplaatRepository _weekRepo;

  @override
  void initState() {
    super.initState();
    // Initialize repositories
    final supabaseClient = Supabase.instance.client;
    _kosRepo = KosTemplaatRepository(SupabaseDb(supabaseClient));
    _weekRepo = WeekTemplaatRepository(SupabaseDb(supabaseClient));

    // Load available kos items for template creation
    _loadKosItems();
  }

  @override
  void dispose() {
    _naamController.dispose();
    _prysController.dispose();
    _bestanddeleController.dispose();
    _allergeneController.dispose();
    _beskrywingController.dispose();
    _templateNameController.dispose();
    _templateDescController.dispose();
    super.dispose();
  }

  Future<void> _loadKosItems() async {
    try {
      final items = await _kosRepo.getKosItems();
      setState(() {
        _templates = items
            .map((item) => KositemTemplate.fromMap(item))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading kos items: $e');
    }
  }

  void _showKositemFormModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => KositemFormModal(
        formKey: _kositemFormKey,
        naamController: _naamController,
        prysController: _prysController,
        bestanddeleController: _bestanddeleController,
        allergeneController: _allergeneController,
        beskrywingController: _beskrywingController,
        selectedCategories: _selectedCategories,
        allCategories: _allCategories,
        selectedImage: _selectedImage,
        isLoading: _isKositemLoading,
        onCancel: () {
          Navigator.of(context).pop();
          _clearKositemForm();
        },
        onSave: _saveKositem,
        onPickImage: _pickImage,
        onCategoriesChanged: (categories) {
          setState(() {
            _selectedCategories = categories;
          });
        },
      ),
    );
  }

  void _showWeekFormModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FormModal(
        activeTemplateId: null,
        nameController: _templateNameController,
        descController: _templateDescController,
        formDays: _formDays,
        daeVanWeek: _daeVanWeek,
        templates: _templates,
        searchControllers: _searchControllers,
        onCancel: () {
          Navigator.of(context).pop();
          _clearTemplateForm();
        },
        onSave: _saveTemplate,
      ),
    );
  }

  void _clearKositemForm() {
    _naamController.clear();
    _prysController.clear();
    _bestanddeleController.clear();
    _allergeneController.clear();
    _beskrywingController.clear();
    _selectedCategories.clear();
    _selectedImage = null;
  }

  void _clearTemplateForm() {
    _templateNameController.clear();
    _templateDescController.clear();
    _formDays.forEach((key, value) => value.clear());
  }

  void _saveKositem() async {
    if (_kositemFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isKositemLoading = true;
      });

      try {
        // Prepare kos item data
        final kosItemData = {
          'kos_item_naam': _naamController.text.trim(),
          'kos_item_koste': double.parse(_prysController.text),
          'kos_item_bestanddele': _bestanddeleController.text.trim(),
          'kos_item_allergene': _allergeneController.text.trim(),
          'kos_item_beskrywing': _beskrywingController.text.trim(),
          'kos_item_prent': _selectedImage ?? '',
          'is_aktief': true,
        };

        // Save kos item with categories
        await _kosRepo.addKosItem(kosItemData, _selectedCategories);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kos item suksesvol gestoor!'),
              backgroundColor: Colors.green,
            ),
          );
          _clearKositemForm();
          // Reload kos items for template creation
          _loadKosItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout by stoor: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isKositemLoading = false;
          });
        }
      }
    }
  }

  void _saveTemplate() async {
    try {
      // Prepare template data
      final templateName = _templateNameController.text.trim();
      final templateDesc = _templateDescController.text.trim();

      if (templateName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Templaat naam is verpligtend'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert form days to the format expected by the repository
      final Map<String, List<Map<String, dynamic>>> dae = {};
      _formDays.forEach((dagKey, items) {
        dae[dagKey] = items.map((item) => {'id': item.id}).toList();
      });

      // Save week template
      await _weekRepo.createWeekTemplate(
        naam: templateName,
        beskrywing: templateDesc.isNotEmpty ? templateDesc : null,
        dae: dae,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spyskaart templaat suksesvol gestoor!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearTemplateForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by stoor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pickImage() {
    // TODO: Implement image picker logic
    setState(() {
      _selectedImage = 'https://via.placeholder.com/300x200'; // Placeholder
    });
  }

  void _navigateToOrders() {
    context.go('/bestellings');
  }

  void _navigateToUsers() {
    context.go('/gebruikers');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Vinnige aksies',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gereelde administratiewe take',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: (widget.isLarge) ? 4 : (widget.isMedium ? 4 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3.1, // Make buttons more square
              children: [
                OutlinedButton(
                  onPressed: _showKositemFormModal,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Skep kos item',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _showWeekFormModal,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.article, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Skep spyskaart templaat',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _navigateToOrders,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.settings, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Bestuur Bestellings',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _navigateToUsers,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.group, size: 20),
                      SizedBox(height: 4),
                      Text(
                        'Bestuur Gebruikers',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
