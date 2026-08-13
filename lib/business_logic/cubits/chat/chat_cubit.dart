import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/chat/chat_state.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/chat_model.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository chatRepository;

  ChatCubit({required this.chatRepository}) : super(const ChatInitial());

  Future<void> loadChats(int shopId) async {
    emit(const ChatLoading());
    try {
      final chats = await chatRepository.getShopChats(shopId);
      emit(ChatsLoaded(chats: chats));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> loadMessages(int chatId, Chat? chat) async {
    emit(const ChatLoading());
    try {
      final messages = await chatRepository.getChatMessages(chatId);
      if (chat != null) {
        emit(ChatMessagesLoaded(messages: messages, chat: chat));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> sendMessage(
    int chatId,
    String sender,
    String body, {
    Chat? chat,
  }) async {
    try {
      await chatRepository.sendMessage(chatId, sender, body);
      // Reload messages after sending
      await loadMessages(chatId, chat);
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }
}
