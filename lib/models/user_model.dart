class UserModel {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String password;
  final List<String> address;
  final String profilePicture;
  final String role;
  final String? cashierType;
  final List<String> claimedVouchers;
  final int loyaltyPoints;
  final String? loyaltyLevel;
  final List<String> favorites;
  final List<String> outlet;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.password,
    required this.address,
    required this.profilePicture,
    required this.role,
    this.cashierType,
    required this.claimedVouchers,
    required this.loyaltyPoints,
    this.loyaltyLevel,
    required this.favorites,
    required this.outlet,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter untuk mengetahui apakah user login dengan Google
  bool get isGoogleUser => password == '-' || password.isEmpty;

  // Getter untuk mengetahui apakah user bisa mengubah email
  bool get canEditEmail => !isGoogleUser;

  // Getter untuk mengetahui apakah user bisa mengubah password
  bool get canEditPassword => !isGoogleUser;

  // Factory constructor untuk membuat UserModel dari JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      password: json['password'] ?? '-',
      address: List<String>.from(json['address'] ?? []),
      profilePicture: json['profilePicture'] ?? 'https://img.freepik.com/premium-vector/man-avatar-profile-picture-vector-illustration_268834-538.jpg',
      role: json['role'] ?? 'customer',
      cashierType: json['cashierType'],
      claimedVouchers: List<String>.from(json['claimedVouchers'] ?? []),
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
      loyaltyLevel: json['loyaltyLevel'],
      favorites: List<String>.from(json['favorites'] ?? []),
      outlet: List<String>.from(json['outlet']?.map((o) => o['outletId'].toString()) ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Method untuk mengubah UserModel menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'address': address,
      'profilePicture': profilePicture,
      'role': role,
      'cashierType': cashierType,
      'claimedVouchers': claimedVouchers,
      'loyaltyPoints': loyaltyPoints,
      'loyaltyLevel': loyaltyLevel,
      'favorites': favorites,
      'outlet': outlet,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Method untuk membuat copy UserModel dengan perubahan tertentu
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? password,
    List<String>? address,
    String? profilePicture,
    String? role,
    String? cashierType,
    List<String>? claimedVouchers,
    int? loyaltyPoints,
    String? loyaltyLevel,
    List<String>? favorites,
    List<String>? outlet,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      cashierType: cashierType ?? this.cashierType,
      claimedVouchers: claimedVouchers ?? this.claimedVouchers,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyLevel: loyaltyLevel ?? this.loyaltyLevel,
      favorites: favorites ?? this.favorites,
      outlet: outlet ?? this.outlet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Method untuk mendapatkan nama lengkap role
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'customer':
        return 'Pelanggan';
      case 'waiter':
        return 'Pelayan';
      case 'kitchen':
        return 'Dapur';
      case 'cashier junior':
        return 'Kasir Junior';
      case 'cashier senior':
        return 'Kasir Senior';
      case 'akuntan':
        return 'Akuntan';
      case 'inventory':
        return 'Inventory';
      case 'marketing':
        return 'Marketing';
      case 'operational':
        return 'Operasional';
      default:
        return role;
    }
  }

  // Method untuk mendapatkan nama lengkap cashier type
  String? get cashierTypeDisplayName {
    if (cashierType == null) return null;

    switch (cashierType) {
      case 'bar-1-amphi':
        return 'Bar 1 Amphi';
      case 'bar-2-amphi':
        return 'Bar 2 Amphi';
      case 'bar-3-amphi':
        return 'Bar 3 Amphi';
      case 'bar-tp':
        return 'Bar TP';
      case 'bar-dp':
        return 'Bar DP';
      case 'drive-thru':
        return 'Drive Thru';
      default:
        return cashierType;
    }
  }

  @override
  String toString() {
    return 'UserModel{id: $id, username: $username, email: $email, role: $role}';
  }
}