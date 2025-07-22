import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/menu_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/menu_item.dart';
import '../../../models/cart_item.dart';
import '../../../core/utils/color_utils.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _menuService = MenuService();
  final _cartService = CartService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  String _selectedCategory = 'Alles';
  List<MenuItem> _filteredItems = [];
  bool _showVegetarianOnly = false;
  bool _showVeganOnly = false;
  bool _showGlutenFreeOnly = false;
  bool _showAvailableOnly = true;

  @override
  void initState() {
    super.initState();
    _menuService.initialize();
    _loadMenuItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMenuItems() {
    List<MenuItem> items = _menuService.menuItems;
    
    // Apply category filter
    if (_selectedCategory != 'Alles') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }
    
    // Apply dietary filters
    if (_showVegetarianOnly) {
      items = items.where((item) => item.isVegetarian).toList();
    }
    if (_showVeganOnly) {
      items = items.where((item) => item.isVegan).toList();
    }
    if (_showGlutenFreeOnly) {
      items = items.where((item) => item.isGlutenFree).toList();
    }
    if (_showAvailableOnly) {
      items = items.where((item) => item.isAvailable).toList();
    }
    
    // Apply search filter
    final query = _searchController.text;
    if (query.isNotEmpty) {
      items = _menuService.searchItems(query);
    }
    
    // Filter out user allergies
    final user = _authService.currentUser;
    if (user != null && user.allergies.isNotEmpty) {
      items = items.where((item) {
        return !item.allergies.any((allergy) => user.allergies.contains(allergy));
      }).toList();
    }
    
    setState(() {
      _filteredItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spyskaart'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          StreamBuilder<List<CartItem>>(
            stream: _cartService.cartStream,
            builder: (context, snapshot) {
              final itemCount = _cartService.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppConstants.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Soek spyskaart items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadMenuItems();
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => _loadMenuItems(),
            ),
          ),
          
          // Categories
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ['Alles', ..._menuService.categories].length,
              itemBuilder: (context, index) {
                final categories = ['Alles', ..._menuService.categories];
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                
                return Container(
                  margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _loadMenuItems();
                    },
                    selectedColor: AppConstants.primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppConstants.primaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Menu Items
          Expanded(
            child: _filteredItems.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildMenuItemCard(item);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Geen items gevind nie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Probeer \'n ander soektog of filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final user = _authService.currentUser;
    final hasAllergies = user != null && 
        item.allergies.any((allergy) => user.allergies.contains(allergy));

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: setOpacity(AppConstants.primaryColor, 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadiusMedium),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 50,
                    color: AppConstants.primaryColor,
                  ),
                ),
                // Dietary badges
                Positioned(
                  top: 8,
                  right: 8,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      if (item.isVegan) _buildDietaryBadge('Vegan', Colors.green),
                      if (item.isVegetarian && !item.isVegan) _buildDietaryBadge('Vegetaries', Colors.orange),
                      if (item.isGlutenFree) _buildDietaryBadge('Glutenvry', Colors.blue),
                    ],
                  ),
                ),
                // Availability overlay
                if (!item.isAvailable)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: setOpacity(Colors.black, 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'UITVERKOOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'R${item.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                // Allergies warning
                if (hasAllergies) ...[
                  const SizedBox(height: AppConstants.paddingSmall),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: setOpacity(AppConstants.errorColor, 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: AppConstants.errorColor,
                          size: 16,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: Text(
                            'Let op: Bevat allergieë wat jy geïdentifiseer het',
                            style: TextStyle(
                              color: AppConstants.errorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: item.isAvailable && !hasAllergies
                        ? () => _addToCart(item)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      item.isAvailable 
                        ? (hasAllergies ? 'Nie beskikbaar (Allergieë)' : 'Voeg by mandjie')
                        : 'Uitverkoop',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _addToCart(MenuItem item) {
    _cartService.addToCart(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} bygevoeg by mandjie'),
        action: SnackBarAction(
          label: 'Sien Mandjie',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Opsies'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Net Vegetaries'),
                  value: _showVegetarianOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showVegetarianOnly = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Net Vegan'),
                  value: _showVeganOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showVeganOnly = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Net Glutenvry'),
                  value: _showGlutenFreeOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showGlutenFreeOnly = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Net Beskikbaar'),
                  value: _showAvailableOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showAvailableOnly = value ?? false;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showVegetarianOnly = false;
                _showVeganOnly = false;
                _showGlutenFreeOnly = false;
                _showAvailableOnly = true;
              });
              _loadMenuItems();
              Navigator.pop(context);
            },
            child: const Text('Maak Skoon'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              _loadMenuItems();
              Navigator.pop(context);
            },
            child: const Text('Pas Toe'),
          ),
        ],
      ),
    );
  }
} 