class Shop {
  final int id;
  final String name;
  final String description;
  final String currency;
  final int employeesCount;
  final String code;
  final String address;
  final String managerName;
  final String phone;
  final bool isActive;

  Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.currency,
    required this.employeesCount,
    required this.code,
    required this.address,
    required this.managerName,
    required this.phone,
    required this.isActive,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      currency: json['currency'] ?? 'FCFA',
      employeesCount: json['employees_count'] ?? 0,
      code: json['code'] ?? '',
      address: json['address'] ?? '',
      managerName: json['manager_name'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
