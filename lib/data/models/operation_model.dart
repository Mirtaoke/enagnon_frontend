class OperationModel {
  final int id;
  final String clientUuid;
  final int shopId;
  final int userId;
  final String service;
  final String direction;
  final String type;
  final double amount;
  final String phone;
  final String network;
  final String description;
  final DateTime occurredAt;
  final String userName;

  const OperationModel({
    required this.id,
    required this.clientUuid,
    required this.shopId,
    required this.userId,
    required this.service,
    required this.direction,
    required this.type,
    required this.amount,
    required this.phone,
    required this.network,
    required this.description,
    required this.occurredAt,
    required this.userName,
  });

  factory OperationModel.fromJson(Map<String, dynamic> json) => OperationModel(
    id: _integer(json['id']),
    clientUuid: '${json['client_uuid'] ?? ''}',
    shopId: _integer(json['shop_id']),
    userId: _integer(json['user_id']),
    service: '${json['service'] ?? ''}',
    direction: '${json['direction'] ?? ''}',
    type: '${json['type'] ?? ''}',
    amount: _number(json['amount']),
    phone: '${json['phone'] ?? ''}',
    network: '${json['network'] ?? ''}',
    description: '${json['description'] ?? ''}',
    occurredAt: DateTime.tryParse('${json['occurred_at']}') ?? DateTime.now(),
    userName: json['user'] is Map ? '${json['user']['name'] ?? ''}' : '',
  );

  static int _integer(dynamic value) => int.tryParse('$value') ?? 0;
  static double _number(dynamic value) => double.tryParse('$value') ?? 0;
}
