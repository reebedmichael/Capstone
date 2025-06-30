class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final List<String> ingredients;
  final Map<String, dynamic> nutritionalInfo;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.isAvailable = true,
    this.ingredients = const [],
    this.nutritionalInfo = const {},
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
      nutritionalInfo: Map<String, dynamic>.from(json['nutritionalInfo'] ?? {}),
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
      'nutritionalInfo': nutritionalInfo,
    };
  }
} 