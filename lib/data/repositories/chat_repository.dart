import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class ChatRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;

  ChatRepository({required this.apiProvider, required this.storageProvider});

  Future<List<Chat>> getShopChats(int shopId) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get(
      '/shops/$shopId/chats',
      token: token,
    );
    return (response['chats'] as List).map((e) => Chat.fromJson(e)).toList();
  }

  Future<List<Message>> getChatMessages(int chatId) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get(
      '/chats/$chatId/messages',
      token: token,
    );
    return (response['messages'] as List)
        .map((e) => Message.fromJson(e))
        .toList();
  }

  Future<Message> sendMessage(int chatId, String sender, String body) async {
    final token = await storageProvider.getToken();
    final bodyData = {'sender_name': sender, 'body': body};
    final response = await apiProvider.post(
      '/chats/$chatId/messages',
      bodyData,
      token: token,
    );
    return Message.fromJson(response['message']);
  }
}
