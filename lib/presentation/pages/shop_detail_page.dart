import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../business_logic/cubits/shop/shop_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/shop_model.dart';
import '../../data/models/employee_model.dart';

class ShopDetailPage extends StatefulWidget {
  final int shopId;
  const ShopDetailPage({super.key, required this.shopId});
  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  bool cashSheetOpen = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
    context.read<ShopCubit>().loadShopDetail(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final isAdmin = auth is AuthSuccess && auth.user.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point de vente'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Ajouter un vendeur',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: _showAddEmployeeDialog,
            ),
          if (isAdmin)
            IconButton(
              tooltip: 'Déposer ou retirer de la caisse',
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: _adjustCash,
            ),
        ],
        bottom: TabBar(
          controller: tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: 'Services & opérations',
            ),
            Tab(icon: Icon(Icons.people_outline), text: 'Équipe'),
          ],
        ),
      ),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShopError) {
            return _ErrorView(
              message: state.message,
              retry: () =>
                  context.read<ShopCubit>().loadShopDetail(widget.shopId),
            );
          }
          if (state is! ShopDetailLoaded) return const SizedBox.shrink();
          return TabBarView(
            controller: tabs,
            children: [
              _services(state, isAdmin),
              _employees(state.shop, isAdmin),
            ],
          );
        },
      ),
    );
  }

  Widget _services(ShopDetailLoaded state, bool isAdmin) {
    final services = const [
      ('other', 'Autres', Icons.category_outlined, AppColors.success),
      ('moov_credit', 'Moov crédit', Icons.phone_android, AppColors.primary),
      ('flooz', 'Flooz', Icons.bolt, AppColors.accent),
      ('momo', 'MoMo', Icons.account_balance_wallet, AppColors.cyan),
      ('mtn_credit', 'MTN crédit', Icons.sim_card, Color(0xFFE8B800)),
      ('celtiis', 'Celtiis', Icons.cell_tower, AppColors.secondary),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .25),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.shop.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Montant actuel de la caisse',
                style: TextStyle(color: Colors.white70),
              ),
              FittedBox(
                child: Text(
                  '${state.cashBalance.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _mini('Encaissements', state.totalIn)),
                  const SizedBox(width: 10),
                  Expanded(child: _mini('Sorties', state.totalOut)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Total du jour : ${state.dayBalance >= 0 ? '+' : ''}${state.dayBalance.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Services suivis', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
            mainAxisExtent: 118,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: services.length,
          itemBuilder: (_, index) {
            final service = services[index];
            final rawValues = state.serviceSummary[service.$1];
            final values = rawValues is Map
                ? Map<String, dynamic>.from(rawValues)
                : <String, dynamic>{};
            final entries = double.tryParse('${values['entries']}') ?? 0;
            final outputs = double.tryParse('${values['outputs']}') ?? 0;
            return Material(
              color: service.$4.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () =>
                    Navigator.pushNamed(
                      context,
                      '/operations',
                      arguments: {
                        'shopId': widget.shopId,
                        'service': service.$1,
                      },
                    ).then((_) {
                      if (mounted) {
                        context.read<ShopCubit>().loadShopDetail(widget.shopId);
                      }
                    }),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      Icon(service.$3, color: service.$4),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              service.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                '${(entries - outputs).toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  color: service.$4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '+${entries.toStringAsFixed(0)} / -${outputs.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        if (!isAdmin)
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/daily-closure',
              arguments: widget.shopId,
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Vérifier et envoyer le rapport du jour'),
          ),
      ],
    );
  }

  Widget _mini(String label, double amount) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        FittedBox(
          child: Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _employees(Shop shop, bool isAdmin) => FutureBuilder(
    future: context.read<ShopCubit>().shopRepository.getShopEmployees(shop.id),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
      final employees = snapshot.data ?? const [];
      if (employees.isEmpty) {
        return const Center(
          child: Text('Aucun employé dans ce point de vente'),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        itemCount: employees.length,
        itemBuilder: (_, index) {
          final employee = employees[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(13),
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: .14),
                child: Text(
                  employee.name.isEmpty ? '?' : employee.name[0],
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                employee.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(employee.role),
              trailing: isAdmin
                  ? PopupMenuButton<String>(
                      onSelected: (value) => value == 'edit'
                          ? _editEmployee(employee)
                          : _deleteEmployee(employee),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Supprimer',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.success,
                    ),
            ),
          );
        },
      );
    },
  );

  Future<void> _showAddEmployeeDialog() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EmployeeFormSheet(),
    );
    if (data != null && mounted) {
      try {
        final response = await context
            .read<ShopCubit>()
            .shopRepository
            .addEmployee(widget.shopId, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Compte créé : ${response['credentials']['login']} / ${response['credentials']['password']}',
              ),
              backgroundColor: AppColors.notification,
            ),
          );
        }
        if (mounted) setState(() {});
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

  Future<void> _adjustCash() async {
    if (cashSheetOpen) return;
    cashSheetOpen = true;
    final amount = TextEditingController();
    final motif = TextEditingController();
    var direction = 'in';
    Map<String, dynamic>? data;
    try {
      data = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              22,
              22,
              MediaQuery.viewInsetsOf(context).bottom +
                  MediaQuery.viewPaddingOf(context).bottom +
                  24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mouvement de caisse',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'in', label: Text('Déposer')),
                    ButtonSegment(value: 'out', label: Text('Retirer')),
                  ],
                  selected: {direction},
                  onSelectionChanged: (value) =>
                      setSheetState(() => direction = value.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motif,
                  decoration: const InputDecoration(labelText: 'Motif'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final value = double.tryParse(amount.text);
                      if (value == null ||
                          value <= 0 ||
                          motif.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(context, {
                        'direction': direction,
                        'amount': value,
                        'description': motif.text.trim(),
                      });
                    },
                    child: const Text('Valider le mouvement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      cashSheetOpen = false;
    }
    if (data == null || !mounted) return;
    try {
      await context.read<ShopCubit>().shopRepository.adjustCash(
        widget.shopId,
        data,
      );
      if (mounted) {
        _snack('La caisse a été mise à jour.', true);
        context.read<ShopCubit>().loadShopDetail(widget.shopId);
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _editEmployee(Employee employee) async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeeFormSheet(employee: employee),
    );
    if (data == null || !mounted) return;
    try {
      await context.read<ShopCubit>().shopRepository.updateEmployee(
        widget.shopId,
        employee.id,
        data,
      );
      if (mounted) {
        _snack('Membre modifié avec succès.', true);
        setState(() {});
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce membre ?'),
        content: Text(
          'Le compte de ${employee.name} sera supprimé. Cette action doit être confirmée.',
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
      await context.read<ShopCubit>().shopRepository.deleteEmployee(
        widget.shopId,
        employee.id,
      );
      if (mounted) {
        _snack('Membre supprimé.', true);
        setState(() {});
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
    tabs.dispose();
    super.dispose();
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorView({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 52, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}

class _EmployeeFormSheet extends StatefulWidget {
  final Employee? employee;
  const _EmployeeFormSheet({this.employee});
  @override
  State<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<_EmployeeFormSheet> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.employee?.name ?? '');
  final username = TextEditingController();
  late final email = TextEditingController(text: widget.employee?.email ?? '');
  late final phone = TextEditingController(text: widget.employee?.phone ?? '');
  final password = TextEditingController(text: 'password');
  late String role = widget.employee?.role == 'Responsable'
      ? 'manager'
      : 'seller';
  bool visible = false;

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
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajouter un membre',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Tous les champs sont obligatoires',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _field(
              name,
              'Nom complet *',
              Icons.person_outline,
              validator: _required,
            ),
            const SizedBox(height: 11),
            if (widget.employee == null) ...[
              _field(
                username,
                'Nom d’utilisateur *',
                Icons.alternate_email,
                validator: _required,
              ),
              const SizedBox(height: 11),
            ],
            _field(
              email,
              'Adresse email *',
              Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: (value) {
                if (_required(value) != null) return _required(value);
                return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!)
                    ? null
                    : 'Saisis une adresse email valide.';
              },
            ),
            const SizedBox(height: 11),
            _field(
              phone,
              'Téléphone *',
              Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (value) {
                if (_required(value) != null) return _required(value);
                return RegExp(r'^\d{10}$').hasMatch(value!.trim())
                    ? null
                    : 'Le numéro doit contenir exactement 10 chiffres.';
              },
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(
                labelText: 'Rôle *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'seller',
                  child: Text('Vendeur / agent'),
                ),
                DropdownMenuItem(value: 'manager', child: Text('Responsable')),
              ],
              onChanged: (value) => setState(() => role = value!),
            ),
            if (widget.employee == null) ...[
              const SizedBox(height: 11),
              TextFormField(
                controller: password,
                obscureText: !visible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe par défaut *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => visible = !visible),
                    icon: Icon(
                      visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) => (value ?? '').length < 6
                    ? 'Le mot de passe doit contenir au moins 6 caractères.'
                    : null,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Créer le compte'),
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
    String? Function(String?)? validator,
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
    validator: validator,
  );
  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Ce champ est obligatoire.' : null;
  void _submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': name.text.trim(),
      'email': email.text.trim(),
      'phone': phone.text.trim(),
      'role': role,
      if (widget.employee == null) 'username': username.text.trim(),
      if (widget.employee == null) 'password': password.text,
    });
  }

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }
}
