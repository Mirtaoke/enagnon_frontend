import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../business_logic/cubits/chat/chat_cubit.dart';
import '../../business_logic/cubits/chat/chat_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/chat_model.dart';

class ChatPage extends StatefulWidget {
  final int shopId;
  const ChatPage({super.key, required this.shopId});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final messageController = TextEditingController();
  Chat? selectedChat;

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadChats(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final userName = auth is AuthSuccess ? auth.user.name : 'Utilisateur';
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forum de la boutique'),
            Text(
              'Équipe en ligne',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.groups_2_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0EBFF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatError) {
              return Center(
                child: Text(state.message, textAlign: TextAlign.center),
              );
            }
            if (state is ChatsLoaded) {
              if (state.chats.isEmpty) {
                return const Center(child: Text('Aucun forum disponible'));
              }
              selectedChat = state.chats.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && selectedChat != null) {
                  context.read<ChatCubit>().loadMessages(
                    selectedChat!.id,
                    selectedChat,
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatMessagesLoaded) {
              selectedChat = state.chat;
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.campaign_outlined, color: AppColors.accent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Les rapports journaliers sont publiés automatiquement ici.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final mine = message.senderName == userName;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .78,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: mine
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    )
                                  : null,
                              color: mine ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(mine ? 18 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    message.senderName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                Text(
                                  message.body,
                                  style: TextStyle(
                                    color: mine ? Colors.white : AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Écrire au groupe...',
                                prefixIcon: Icon(Icons.chat_bubble_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () {
                              final text = messageController.text.trim();
                              if (text.isEmpty || selectedChat == null) return;
                              context.read<ChatCubit>().sendMessage(
                                selectedChat!.id,
                                userName,
                                text,
                                chat: selectedChat,
                              );
                              messageController.clear();
                            },
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
