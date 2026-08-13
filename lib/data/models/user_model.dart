class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String username;
  final int? shopId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.username,
    this.shopId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'seller',
      username: json['username'] ?? '',
      shopId: json['employee']?['shop_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'username': username,
    'employee': shopId == null ? null : {'shop_id': shopId},
  };
}
