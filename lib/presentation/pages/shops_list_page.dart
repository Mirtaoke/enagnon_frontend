import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../business_logic/cubits/shop/shop_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/shop_model.dart';

class ShopsListPage extends StatefulWidget {
  const ShopsListPage({super.key});
  @override
  State<ShopsListPage> createState() => _ShopsListPageState();
}

class _ShopsListPageState extends State<ShopsListPage> {
  final search = TextEditingController();
  bool modalOpen = false;
  @override
  void initState() {
    super.initState();
    context.read<ShopCubit>().loadAllShops();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final isAdmin = auth is AuthSuccess && auth.user.role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Points de vente')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _addShop,
              icon: const Icon(Icons.add_business),
              label: const Text('Ajouter'),
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0EBFF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocBuilder<ShopCubit, ShopState>(
          builder: (context, state) {
            if (state is ShopLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ShopError) return Center(child: Text(state.message));
            if (state is! ShopsLoaded) return const SizedBox.shrink();
            final query = search.text.trim().toLowerCase();
            final shops = state.shops
                .where(
                  (shop) =>
                      query.isEmpty ||
                      shop.name.toLowerCase().contains(query) ||
                      shop.code.toLowerCase().contains(query) ||
                      shop.address.toLowerCase().contains(query),
                )
                .toList();
            return RefreshIndicator(
              onRefresh: () => context.read<ShopCubit>().loadAllShops(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par nom, code ou adresse',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.tune),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (shops.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Aucun point de vente trouvé')),
                    ),
                  for (var i = 0; i < shops.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 250 + i * 70),
                      builder: (_, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            final shopCubit = context.read<ShopCubit>();
                            Navigator.pushNamed(
                              context,
                              '/shop-detail',
                              arguments: shops[i].id,
                            ).then((_) {
                              if (mounted) {
                                shopCubit.loadAllShops();
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              shops[i].name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          _Status(active: shops[i].isActive),
                                        ],
                                      ),
                                      if (shops[i].code.trim().isNotEmpty ||
                                          shops[i].address.trim().isNotEmpty)
                                        Text(
                                          [
                                            if (shops[i].code.trim().isNotEmpty)
                                              shops[i].code,
                                            if (shops[i].address
                                                .trim()
                                                .isNotEmpty)
                                              shops[i].address,
                                          ].join(' • '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${shops[i].employeesCount} ${shops[i].employeesCount == 1 ? 'employé' : 'employés'}',
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin)
                                  PopupMenuButton<String>(
                                    tooltip: 'Gérer le point de vente',
                                    onSelected: (value) => value == 'edit'
                                        ? _editShop(shops[i])
                                        : _deleteShop(shops[i]),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Modifier'),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: AppColors.danger,
                                          ),
                                          title: Text('Supprimer'),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addShop() async {
    if (modalOpen) return;
    modalOpen = true;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ShopFormSheet(),
    );
    modalOpen = false;
    if (data != null && mounted) {
      try {
        await context.read<ShopCubit>().shopRepository.addShop(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Point de vente ajouté avec succès.'),
              backgroundColor: AppColors.notification,
            ),
          );
          context.read<ShopCubit>().loadAllShops();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$error'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _editShop(Shop shop) async {
    if (modalOpen) return;
    modalOpen = true;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopFormSheet(shop: shop),
    );
    modalOpen = false;
    if (data == null || !mounted) return;
    try {
      await context.read<ShopCubit>().shopRepository.updateShop(shop.id, data);
      if (mounted) {
        _snack('Point de vente modifié avec succès.', true);
        context.read<ShopCubit>().loadAllShops();
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _deleteShop(Shop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce point de vente ?'),
        content: Text(
          '« ${shop.name} » sera supprimé uniquement s’il ne contient plus de membres, d’opérations ou de rapports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ShopCubit>().shopRepository.deleteShop(shop.id);
      if (mounted) {
        _snack('Point de vente supprimé.', true);
        context.read<ShopCubit>().loadAllShops();
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  void _snack(String text, bool success) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: success ? AppColors.notification : AppColors.danger,
        ),
      );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}

class _ShopFormSheet extends StatefulWidget {
  final Shop? shop;
  const _ShopFormSheet({this.shop});
  @override
  State<_ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<_ShopFormSheet> {
  final form = GlobalKey<FormState>();
  late final code = TextEditingController(text: widget.shop?.code ?? '');
  late final name = TextEditingController(text: widget.shop?.name ?? '');
  late final address = TextEditingController(text: widget.shop?.address ?? '');
  late final manager = TextEditingController(
    text: widget.shop?.managerName ?? '',
  );
  late final phone = TextEditingController(text: widget.shop?.phone ?? '');

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .88,
    ),
    margin: EdgeInsets.only(
      bottom:
          View.of(context).viewPadding.bottom /
          View.of(context).devicePixelRatio,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 22,
    ),
    child: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add_business, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau point de vente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Renseigne toutes les informations',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _field(code, 'Code / numéro *', Icons.tag),
            const SizedBox(height: 11),
            _field(name, 'Nom du point *', Icons.storefront_outlined),
            const SizedBox(height: 11),
            _field(
              address,
              'Localisation / adresse *',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 11),
            _field(manager, 'Responsable *', Icons.manage_accounts_outlined),
            const SizedBox(height: 11),
            _field(
              phone,
              'Téléphone *',
              Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Créer le point de vente'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  TextFormField _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    inputFormatters: keyboard == TextInputType.phone
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ]
        : null,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: (value) {
      if ((value ?? '').trim().isEmpty) return 'Ce champ est obligatoire.';
      if (keyboard == TextInputType.phone &&
          !RegExp(r'^\d{10}$').hasMatch(value!.trim())) {
        return 'Le numéro doit contenir exactement 10 chiffres.';
      }
      return null;
    },
  );
  void _submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(context, {
      'code': code.text.trim(),
      'name': name.text.trim(),
      'address': address.text.trim(),
      'manager_name': manager.text.trim(),
      'phone': phone.text.trim(),
      'is_active': true,
    });
  }

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    address.dispose();
    manager.dispose();
    phone.dispose();
    super.dispose();
  }
}

class _Status extends StatelessWidget {
  final bool active;
  const _Status({required this.active});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (active ? AppColors.success : Colors.grey).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'Actif' : 'Inactif',
      style: TextStyle(
        color: active ? AppColors.success : Colors.grey,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
