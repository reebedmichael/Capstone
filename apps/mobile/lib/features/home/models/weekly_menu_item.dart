
class WeeklyMenuItem {
  final DateTime date; // local date for the menu item (YYYY-MM-DD)
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String dayName;
  bool orderable; // computed dynamically
  final String? weekDagNaam;

  WeeklyMenuItem({
    required this.date,
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.dayName,
    required this.orderable,
    this.weekDagNaam,
  });

  // Helper method to compute if this menu item is orderable
  static bool isOrderableForMenuDate(DateTime menuDate, DateTime nowInSAST) {
    final menuDay = DateTime(menuDate.year, menuDate.month, menuDate.day);
    final dayBefore = menuDay.subtract(const Duration(days: 1));
    final cutoff = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 17, 0);
    // if nowInSAST is before cutoff, the menuDate item is still orderable
    return nowInSAST.isBefore(cutoff);
  }

  // Update orderable status based on current time
  void updateOrderableStatus(DateTime nowInSAST) {
    orderable = isOrderableForMenuDate(date, nowInSAST);
  }

  WeeklyMenuItem copyWith({
    DateTime? date,
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? dayName,
    bool? orderable,
    String? weekDagNaam,
  }) {
    return WeeklyMenuItem(
      date: date ?? this.date,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      dayName: dayName ?? this.dayName,
      orderable: orderable ?? this.orderable,
      weekDagNaam: weekDagNaam ?? this.weekDagNaam,
    );
  }
}

class CartItem {
  final String id;
  final String menuItemId;
  final DateTime menuDate;
  final int quantity;
  final String itemName;
  final String dayName;
  bool expired; // true if removed due to cutoff

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.menuDate,
    required this.quantity,
    required this.itemName,
    required this.dayName,
    this.expired = false,
  });

  CartItem copyWith({
    String? id,
    String? menuItemId,
    DateTime? menuDate,
    int? quantity,
    String? itemName,
    String? dayName,
    bool? expired,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      menuDate: menuDate ?? this.menuDate,
      quantity: quantity ?? this.quantity,
      itemName: itemName ?? this.itemName,
      dayName: dayName ?? this.dayName,
      expired: expired ?? this.expired,
    );
  }
}
