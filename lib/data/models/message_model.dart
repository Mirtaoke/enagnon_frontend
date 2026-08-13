class Message {
  final int id;
  final int chatId;
  final String senderName;
  final String receiverName;
  final String body;
  final String createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderName,
    required this.receiverName,
    required this.body,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      chatId: json['chat_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
