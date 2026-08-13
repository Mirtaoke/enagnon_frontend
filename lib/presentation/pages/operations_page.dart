import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/operation_model.dart';
import '../../data/repositories/operation_repository.dart';

class OperationsPage extends StatefulWidget {
  final int shopId;
  final String? initialService;
  const OperationsPage({super.key, required this.shopId, this.initialService});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final repository = OperationRepository();
  late String? service = widget.initialService;
  DateTime? date = DateTime.now();
  List<OperationModel> operations = const [];
  bool loading = true;
  bool modalOpen = false;

  static const labels = {
    'other': 'Autres',
    'moov_credit': 'Moov crédit',
    'flooz': 'Flooz',
    'momo': 'MoMo',
    'mtn_credit': 'MTN crédit',
    'celtiis': 'Celtiis',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      operations = await repository.list(
        widget.shopId,
        service: service,
        date: _date,
      );
    } catch (error) {
      if (mounted) _snack('$error', false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? get _date =>
      date == null ? null : DateFormat('yyyy-MM-dd').format(date!);
  double get entries => operations
      .where((item) => item.direction == 'in')
      .fold(0, (sum, item) => sum + item.amount);
  double get outputs => operations
      .where((item) => item.direction == 'out')
      .fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final isAdmin = auth is AuthSuccess && auth.user.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(service == null ? 'Opérations' : labels[service]!),
      ),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Ajouter'),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: service,
                      decoration: const InputDecoration(
                        labelText: 'Service',
                        prefixIcon: Icon(Icons.hub_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tout'),
                        ),
                        ...labels.entries.map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => service = value);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final value = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 350,
                                maxHeight: 540,
                              ),
                              child: child!,
                            ),
                          ),
                        );
                        if (value != null) {
                          setState(() => date = value);
                          _load();
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.fromLTRB(12, 9, 7, 9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: .10),
                              AppColors.secondary.withValues(alpha: .06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    date == null
                                        ? 'Toutes'
                                        : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(date!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (date != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Afficher toutes les dates',
                                onPressed: () {
                                  setState(() => date = null);
                                  _load();
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Summary(
                entries: entries,
                outputs: outputs,
                count: operations.length,
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (operations.isEmpty)
                const _EmptyOperations()
              else
                ...operations.map(_tile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(OperationModel operation) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: () => _details(operation),
      leading: CircleAvatar(
        backgroundColor:
            (operation.direction == 'in' ? AppColors.success : AppColors.danger)
                .withValues(alpha: .12),
        child: Icon(
          operation.direction == 'in' ? Icons.south_west : Icons.north_east,
          color: operation.direction == 'in'
              ? AppColors.success
              : AppColors.danger,
        ),
      ),
      title: Text(
        operation.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${labels[operation.service]} • ${DateFormat('HH:mm').format(operation.occurredAt.toLocal())}${operation.phone.isEmpty ? '' : ' • ${operation.phone}'}',
      ),
      trailing: Text(
        '${operation.direction == 'in' ? '+' : '-'}${operation.amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: operation.direction == 'in'
              ? AppColors.success
              : AppColors.danger,
        ),
      ),
    ),
  );

  Future<void> _add() async {
    if (modalOpen) return;
    modalOpen = true;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OperationForm(initialService: service),
    );
    modalOpen = false;
    if (data == null) return;
    try {
      final queued = await repository.create(widget.shopId, data);
      if (mounted) {
        _snack(
          queued
              ? 'Opération enregistrée hors connexion. Elle sera synchronisée automatiquement.'
              : 'Opération ajoutée avec succès.',
          !queued,
        );
      }
      await _load();
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _details(OperationModel operation) async {
    if (modalOpen) return;
    modalOpen = true;
    final auth = context.read<AuthCubit>().state;
    final canManage =
        auth is AuthSuccess &&
        auth.user.role != 'admin' &&
        auth.user.id == operation.userId;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          22 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    operation.description,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${operation.amount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detail('Service', labels[operation.service] ?? operation.service),
            _detail(
              'Mouvement',
              operation.direction == 'in' ? 'Entrée' : 'Sortie',
            ),
            _detail('Type', _typeLabel(operation.type)),
            _detail(
              'Numéro',
              operation.phone.isEmpty ? 'Non concerné' : operation.phone,
            ),
            if (operation.network.isNotEmpty)
              _detail('Réseau', operation.network),
            _detail('Effectuée par', operation.userName),
            _detail(
              'Date',
              DateFormat(
                'dd/MM/yyyy à HH:mm',
              ).format(operation.occurredAt.toLocal()),
            ),
            if (canManage) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
    modalOpen = false;
    if (action == 'edit' && mounted) await _edit(operation);
    if (action == 'delete' && mounted) await _delete(operation);
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Future<void> _edit(OperationModel operation) async {
    if (modalOpen) return;
    modalOpen = true;
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OperationForm(operation: operation),
    );
    modalOpen = false;
    if (data == null) return;
    data.remove('client_uuid');
    try {
      await repository.update(widget.shopId, operation.id, data);
      if (mounted) _snack('Opération modifiée avec succès.', true);
      await _load();
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _delete(OperationModel operation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette opération ?'),
        content: const Text(
          'Cette action modifiera automatiquement les totaux de la journée.',
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
    if (confirmed != true) return;
    try {
      await repository.delete(widget.shopId, operation.id);
      if (mounted) _snack('Opération supprimée.', true);
      await _load();
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
}

class OperationForm extends StatefulWidget {
  final String? initialService;
  final OperationModel? operation;
  const OperationForm({super.key, this.initialService, this.operation});
  @override
  State<OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<OperationForm> {
  final form = GlobalKey<FormState>();
  late final amount = TextEditingController(
    text: widget.operation == null
        ? ''
        : widget.operation!.amount.toStringAsFixed(0),
  );
  late final phone = TextEditingController(text: widget.operation?.phone ?? '');
  late final description = TextEditingController(
    text: widget.operation?.description ?? '',
  );
  late String service;
  late String direction;
  late String type;
  late String? network;
  late DateTime occurredAt;

  @override
  void initState() {
    super.initState();
    service = widget.operation?.service ?? widget.initialService ?? 'momo';
    direction = service == 'other'
        ? 'out'
        : widget.operation?.direction ?? 'in';
    if (service == 'mtn_credit' || service == 'moov_credit') direction = 'in';
    type =
        widget.operation?.type ?? (service == 'other' ? 'expense' : 'deposit');
    network = widget.operation?.network.isEmpty == false
        ? widget.operation!.network
        : null;
    occurredAt = widget.operation?.occurredAt.toLocal() ?? DateTime.now();
  }

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
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: .12),
                  child: const Icon(Icons.add_card, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.operation == null
                        ? 'Nouvelle opération'
                        : 'Modifier l’opération',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: service,
              decoration: const InputDecoration(
                labelText: 'Service *',
                prefixIcon: Icon(Icons.hub_outlined),
              ),
              items: _OperationsPageState.labels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                service = value!;
                if (service == 'other') {
                  direction = 'out';
                  type = 'expense';
                  phone.clear();
                } else if (service == 'mtn_credit' ||
                    service == 'moov_credit') {
                  direction = 'in';
                  type = 'deposit';
                  network = null;
                } else if ([
                  'expense',
                  'virtual_credit_purchase',
                  'debt',
                  'debt_repayment',
                ].contains(type)) {
                  direction = 'in';
                  type = 'deposit';
                  network = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            if (service != 'other' &&
                service != 'mtn_credit' &&
                service != 'moov_credit') ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'in',
                    icon: Icon(Icons.south_west),
                    label: Text('Entrée'),
                  ),
                  ButtonSegment(
                    value: 'out',
                    icon: Icon(Icons.north_east),
                    label: Text('Sortie'),
                  ),
                ],
                selected: {direction},
                onSelectionChanged: (value) => setState(() {
                  direction = value.first;
                  if (direction == 'in' &&
                      !['deposit', 'other'].contains(type)) {
                    type = 'deposit';
                  }
                  if (direction == 'out' && type == 'deposit') {
                    type = 'withdrawal';
                  }
                }),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(
                labelText: 'Nature de l’opération *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items:
                  (service == 'other'
                          ? [
                              'virtual_credit_purchase',
                              'expense',
                              'debt',
                              'debt_repayment',
                            ]
                          : direction == 'in'
                          ? ['deposit', 'other']
                          : ['withdrawal', 'other'])
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_typeLabel(value)),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() {
                type = value!;
                if (service == 'other') {
                  direction = type == 'debt_repayment' ? 'in' : 'out';
                }
                if (type != 'virtual_credit_purchase') network = null;
              }),
            ),
            const SizedBox(height: 12),
            if (service == 'other' && type == 'virtual_credit_purchase') ...[
              DropdownButtonFormField<String>(
                initialValue: network,
                decoration: const InputDecoration(
                  labelText: 'Réseau *',
                  prefixIcon: Icon(Icons.cell_tower_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'MTN', child: Text('MTN')),
                  DropdownMenuItem(value: 'MOOV', child: Text('MOOV')),
                  DropdownMenuItem(value: 'CELTIIS', child: Text('CELTIIS')),
                ],
                onChanged: (value) => setState(() => network = value),
                validator: (value) =>
                    value == null ? 'Choisis le réseau concerné.' : null,
              ),
              const SizedBox(height: 12),
            ],
            if (service != 'other') ...[
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Numéro concerné (10 chiffres) *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) =>
                    RegExp(r'^\d{10}$').hasMatch((value ?? '').trim())
                    ? null
                    : 'Le numéro doit contenir exactement 10 chiffres.',
              ),
              const SizedBox(height: 12),
            ],
            if (service != 'other' ||
                type == 'expense' ||
                type == 'debt' ||
                type == 'debt_repayment') ...[
              TextFormField(
                controller: description,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: type == 'expense'
                      ? 'Raison de la dépense *'
                      : type == 'debt'
                      ? 'Motif de la dette *'
                      : type == 'debt_repayment'
                      ? 'Motif du remboursement *'
                      : 'Détail / motif *',
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? (type == 'expense'
                          ? 'La raison de la dépense est obligatoire.'
                          : type == 'debt'
                          ? 'Le motif de la dette est obligatoire.'
                          : type == 'debt_repayment'
                          ? 'Le motif du remboursement est obligatoire.'
                          : 'Décris l’opération.')
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA) *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final number = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                return number == null || number <= 0
                    ? 'Saisis un montant supérieur à zéro.'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  widget.operation == null
                      ? 'Enregistrer l’opération'
                      : 'Enregistrer les modifications',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(context, {
      'client_uuid': widget.operation?.clientUuid ?? _uuid(),
      'service': service,
      'direction': direction,
      'type': type,
      'amount': double.parse(amount.text.replaceAll(',', '.')),
      'phone': service == 'other' ? null : phone.text.trim(),
      'network': type == 'virtual_credit_purchase' ? network : null,
      'description': switch (type) {
        'virtual_credit_purchase' => 'Achat de crédit / virtuel - $network',
        'debt' => description.text.trim(),
        'debt_repayment' => description.text.trim(),
        _ => description.text.trim(),
      },
      'occurred_at': occurredAt.toUtc().toIso8601String(),
    });
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
  }

  @override
  void dispose() {
    amount.dispose();
    phone.dispose();
    description.dispose();
    super.dispose();
  }
}

String _typeLabel(String value) =>
    const {
      'deposit': 'Dépôt / encaissement',
      'withdrawal': 'Retrait / décaissement',
      'expense': 'Dépense',
      'virtual_credit_purchase': 'Achat de crédit / virtuel',
      'debt': 'Dette',
      'debt_repayment': 'Remboursement de dette',
      'other': 'Autre opération',
      'admin_cash_deposit': 'Dépôt / encaissement',
      'admin_cash_withdrawal': 'Retrait / décaissement',
    }[value] ??
    value;

class _Summary extends StatelessWidget {
  final double entries, outputs;
  final int count;
  const _Summary({
    required this.entries,
    required this.outputs,
    required this.count,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(child: _value('Entrées', entries, Icons.south_west)),
        Expanded(child: _value('Sorties', outputs, Icons.north_east)),
        Expanded(
          child: _value(
            'Solde',
            entries - outputs,
            Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    ),
  );
  Widget _value(String label, double amount, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white70, size: 19),
      const SizedBox(height: 4),
      FittedBox(
        child: Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _EmptyOperations extends StatelessWidget {
  const _EmptyOperations();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 50),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.black26),
        SizedBox(height: 12),
        Text('Aucune opération pour cette date.'),
        SizedBox(height: 4),
        Text(
          'Utilise le bouton Ajouter pour commencer.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}
