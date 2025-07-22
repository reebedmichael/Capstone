class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'student', 'staff', 'lecturer', 'external', 'admin', 'superadmin'
  final double walletBalance;
  final List<String> addresses;
  final List<String> allergies;
  final bool termsAccepted;
  final bool isActive;
  final DateTime? lastLogin;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.walletBalance = 0.0,
    this.addresses = const [],
    this.allergies = const [],
    this.termsAccepted = false,
    this.isActive = true,
    this.lastLogin,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      userType: json['userType'],
      walletBalance: json['walletBalance']?.toDouble() ?? 0.0,
      addresses: List<String>.from(json['addresses'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      termsAccepted: json['termsAccepted'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      profileImageUrl: json['profileImageUrl'],
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
      'allergies': allergies,
      'termsAccepted': termsAccepted,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userType,
    double? walletBalance,
    List<String>? addresses,
    List<String>? allergies,
    bool? termsAccepted,
    bool? isActive,
    DateTime? lastLogin,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      walletBalance: walletBalance ?? this.walletBalance,
      addresses: addresses ?? this.addresses,
      allergies: allergies ?? this.allergies,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
} 