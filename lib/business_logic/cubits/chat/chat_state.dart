import 'package:equatable/equatable.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatsLoaded extends ChatState {
  final List<Chat> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object?> get props => [chats];
}

class ChatMessagesLoaded extends ChatState {
  final List<Message> messages;
  final Chat chat;

  const ChatMessagesLoaded({required this.messages, required this.chat});

  @override
  List<Object?> get props => [messages, chat];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
