import 'dart:async';
import '../models/menu_item.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  final List<MenuItem> _menuItems = [];
  final StreamController<List<MenuItem>> _menuController = StreamController<List<MenuItem>>.broadcast();

  Stream<List<MenuItem>> get menuStream => _menuController.stream;
  List<MenuItem> get menuItems => List.unmodifiable(_menuItems);
  List<String> get categories => _menuItems.map((item) => item.category).toSet().toList();

  // Initialize with mock menu data
  void initialize() {
    _menuItems.addAll([
      // Burgers
      MenuItem(
        id: '1',
        name: 'Klassieke Burger',
        description: 'Sappige beefspatty met slaai, tamatie, uie en ons spesiale sous',
        price: 85.00,
        category: 'Burgers',
        imageUrl: 'assets/images/classic_burger.jpg',
        isAvailable: true,
        ingredients: ['Beefspatty', 'Slaai', 'Tamatie', 'Uie', 'Spesiale Sous', 'Broodjie'],
        allergies: ['Gluten', 'Soja'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),
      MenuItem(
        id: '2',
        name: 'Vegetariese Burger',
        description: 'Heerlike plantgebaseerde patty met avokado en vars groente',
        price: 75.00,
        category: 'Burgers',
        imageUrl: 'assets/images/veggie_burger.jpg',
        isAvailable: true,
        ingredients: ['Plantpatty', 'Avokado', 'Slaai', 'Tamatie', 'Komkommer', 'Broodjie'],
        allergies: ['Gluten'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: false,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),
      MenuItem(
        id: '3',
        name: 'Spek & Kaas Burger',
        description: 'Dubbele beefspatty met gerookte spek en gesmelte cheddar kaas',
        price: 95.00,
        category: 'Burgers',
        imageUrl: 'assets/images/bacon_burger.jpg',
        isAvailable: true,
        ingredients: ['Dubbele Beefspatty', 'Spek', 'Cheddar Kaas', 'Slaai', 'Tamatie', 'Broodjie'],
        allergies: ['Gluten', 'Laktose'],
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        availableDates: [DateTime.now()],
      ),

      // Salads
      MenuItem(
        id: '4',
        name: 'Caesar Slaai',
        description: 'Knapperige cos slaai met croutons, parmesan en caesar dressing',
        price: 65.00,
        category: 'Slaaie',
        imageUrl: 'assets/images/caesar_salad.jpg',
        isAvailable: true,
        ingredients: ['Cos Slaai', 'Croutons', 'Parmesan Kaas', 'Caesar Dressing'],
        allergies: ['Gluten', 'Laktose', 'Eiers'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),
      MenuItem(
        id: '5',
        name: 'Griekse Slaai',
        description: 'Vars groente met feta kaas, olywe en mediterreense dressing',
        price: 70.00,
        category: 'Slaaie',
        imageUrl: 'assets/images/greek_salad.jpg',
        isAvailable: true,
        ingredients: ['Slaai', 'Tamaties', 'Komkommer', 'Feta Kaas', 'Olywe', 'Rooi Uie'],
        allergies: ['Laktose'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: true,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),

      // Drinks
      MenuItem(
        id: '6',
        name: 'Vars Appelsap',
        description: 'Koud geperste appelsap - 300ml',
        price: 25.00,
        category: 'Drankies',
        imageUrl: 'assets/images/apple_juice.jpg',
        isAvailable: true,
        ingredients: ['Vars Appels'],
        allergies: [],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: true,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),
      MenuItem(
        id: '7',
        name: 'Cappuccino',
        description: 'Ryk espresso met gestoomde melk en skuim',
        price: 35.00,
        category: 'Drankies',
        imageUrl: 'assets/images/cappuccino.jpg',
        isAvailable: true,
        ingredients: ['Espresso', 'Volle Melk'],
        allergies: ['Laktose'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: true,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),

      // Desserts
      MenuItem(
        id: '8',
        name: 'Sjokolade Brownie',
        description: 'Ryk sjokolade brownie met walnuts, geserveer warm',
        price: 45.00,
        category: 'Nagereg',
        imageUrl: 'assets/images/brownie.jpg',
        isAvailable: true,
        ingredients: ['Donker Sjokolade', 'Boter', 'Eiers', 'Meel', 'Walnuts'],
        allergies: ['Gluten', 'Eiers', 'Laktose', 'Neute'],
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        availableDates: [DateTime.now()],
      ),
      MenuItem(
        id: '9',
        name: 'Vegan Koekies',
        description: 'Heerlike hawerkoekies sonder enige dierlike produkte',
        price: 30.00,
        category: 'Nagereg',
        imageUrl: 'assets/images/vegan_cookies.jpg',
        isAvailable: false, // Out of stock
        ingredients: ['Hawermeel', 'Kokosolie', 'Ahornsiroop', 'Rosyntjies'],
        allergies: ['Gluten'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: false,
        availableDates: [DateTime.now().add(const Duration(days: 1))],
      ),

      // Healthy Options
      MenuItem(
        id: '10',
        name: 'Quinoa Bowl',
        description: 'Proteïnryke quinoa met geroosterde groente en tahini dressing',
        price: 80.00,
        category: 'Gesond',
        imageUrl: 'assets/images/quinoa_bowl.jpg',
        isAvailable: true,
        ingredients: ['Quinoa', 'Geroosterde Groente', 'Tahini', 'Spinasie', 'Cherry Tamaties'],
        allergies: ['Sesamsaad'],
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: true,
        availableDates: [DateTime.now(), DateTime.now().add(const Duration(days: 1))],
      ),
    ]);
    
    _menuController.add(_menuItems);
  }

  List<MenuItem> getItemsByCategory(String category) {
    return _menuItems.where((item) => item.category == category).toList();
  }

  List<MenuItem> getAvailableItems() {
    return _menuItems.where((item) => item.isAvailable).toList();
  }

  List<MenuItem> searchItems(String query) {
    if (query.isEmpty) return _menuItems;
    
    final lowerQuery = query.toLowerCase();
    return _menuItems.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
             item.description.toLowerCase().contains(lowerQuery) ||
             item.ingredients.any((ingredient) => ingredient.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<MenuItem> filterByDietaryRestrictions({
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    List<String>? excludeAllergies,
  }) {
    return _menuItems.where((item) {
      if (isVegetarian == true && !item.isVegetarian) return false;
      if (isVegan == true && !item.isVegan) return false;
      if (isGlutenFree == true && !item.isGlutenFree) return false;
      
      if (excludeAllergies != null) {
        for (final allergy in excludeAllergies) {
          if (item.allergies.contains(allergy)) return false;
        }
      }
      
      return true;
    }).toList();
  }

  MenuItem? getItemById(String id) {
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // TODO: Backend integration methods
  Future<void> fetchMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Replace with actual API call
  }

  Future<bool> updateItemAvailability(String itemId, bool isAvailable) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _menuItems[index] = _menuItems[index].copyWith(isAvailable: isAvailable);
      _menuController.add(_menuItems);
      return true;
    }
    return false;
  }

  void dispose() {
    _menuController.close();
  }
} 