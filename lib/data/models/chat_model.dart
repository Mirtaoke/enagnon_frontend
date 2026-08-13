class Chat {
  final int id;
  final int shopId;
  final String subject;
  final int messagesCount;

  Chat({
    required this.id,
    required this.shopId,
    required this.subject,
    required this.messagesCount,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      subject: json['subject'] ?? '',
      messagesCount: json['messages_count'] ?? 0,
    );
  }
}
