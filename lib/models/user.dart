class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'student', 'staff', 'admin'
  final double walletBalance;
  final List<String> addresses;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.walletBalance = 0.0,
    this.addresses = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: json['userType'],
      walletBalance: json['walletBalance']?.toDouble() ?? 0.0,
      addresses: List<String>.from(json['addresses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'walletBalance': walletBalance,
      'addresses': addresses,
    };
  }
} 