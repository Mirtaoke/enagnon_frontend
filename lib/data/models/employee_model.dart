class Employee {
  final int id;
  final int shopId;
  final String name;
  final String role;
  final String email;
  final String phone;

  Employee({
    required this.id,
    required this.shopId,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
