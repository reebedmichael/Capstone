class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final List<String> ingredients;
  final List<String> allergies;
  final Map<String, dynamic> nutritionalInfo;
  final List<DateTime> availableDates;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.isAvailable = true,
    this.ingredients = const [],
    this.allergies = const [],
    this.nutritionalInfo = const {},
    this.availableDates = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      category: json['category'],
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      nutritionalInfo: Map<String, dynamic>.from(json['nutritionalInfo'] ?? {}),
      availableDates: (json['availableDates'] as List?)
          ?.map((date) => DateTime.parse(date))
          .toList() ?? [],
      isVegetarian: json['isVegetarian'] ?? false,
      isVegan: json['isVegan'] ?? false,
      isGlutenFree: json['isGlutenFree'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'ingredients': ingredients,
      'allergies': allergies,
      'nutritionalInfo': nutritionalInfo,
      'availableDates': availableDates.map((date) => date.toIso8601String()).toList(),
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<String>? ingredients,
    List<String>? allergies,
    Map<String, dynamic>? nutritionalInfo,
    List<DateTime>? availableDates,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      ingredients: ingredients ?? this.ingredients,
      allergies: allergies ?? this.allergies,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      availableDates: availableDates ?? this.availableDates,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
    );
  }
} 