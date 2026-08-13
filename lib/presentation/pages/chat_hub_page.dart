import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/shop_model.dart';

class ChatHubPage extends StatefulWidget {
  const ChatHubPage({super.key});
  @override
  State<ChatHubPage> createState() => _ChatHubPageState();
}

class _ChatHubPageState extends State<ChatHubPage> {
  late Future<List<Shop>> shops;
  @override
  void initState() {
    super.initState();
    shops = context.read<ShopCubit>().shopRepository.getAllShops();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Forums des boutiques')),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0EBFF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: FutureBuilder<List<Shop>>(
        future: shops,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Impossible de charger les forums : ${snapshot.error}',
              ),
            );
          }
          final data = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            itemCount: data.length,
            itemBuilder: (context, i) {
              final shop = data[i];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 280 + i * 90),
                tween: Tween(begin: 0, end: 1),
                builder: (_, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.groups, color: Colors.white),
                    ),
                    title: Text(
                      shop.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Forum général • rapports automatiques',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: shop.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
