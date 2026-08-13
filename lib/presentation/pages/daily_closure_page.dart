import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../business_logic/cubits/closure/closure_cubit.dart';
import '../../business_logic/cubits/closure/closure_state.dart';
import '../../core/constants/app_colors.dart';

class DailyClosurePage extends StatefulWidget {
  final int shopId;
  const DailyClosurePage({super.key, required this.shopId});
  @override
  State<DailyClosurePage> createState() => _DailyClosurePageState();
}

class _DailyClosurePageState extends State<DailyClosurePage> {
  final date = DateTime.now();
  Map<String, dynamic> closure = const {};

  static const services = {
    'other': ('Autres', Icons.more_horiz_rounded, AppColors.success),
    'moov_credit': ('Moov crédit', Icons.phone_android, AppColors.primary),
    'flooz': ('Flooz', Icons.bolt, AppColors.accent),
    'momo': ('MoMo', Icons.account_balance_wallet, AppColors.cyan),
    'mtn_credit': ('MTN crédit', Icons.sim_card, Color(0xFFE8B800)),
    'celtiis': ('Celtiis', Icons.cell_tower, AppColors.secondary),
  };

  String get dateValue => DateFormat('yyyy-MM-dd').format(date);
  double number(dynamic value) => double.tryParse('$value') ?? 0;
  double get balance => number(closure['balance']);

  @override
  void initState() {
    super.initState();
    context.read<ClosureCubit>().loadDraft(widget.shopId, dateValue);
  }

  void _load(Map<String, dynamic> data) {
    closure = data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rapport journalier')),
    body: SafeArea(
      child: BlocConsumer<ClosureCubit, ClosureState>(
        listener: (context, state) {
          if (state is ClosureDraftLoaded) setState(() => _load(state.closure));
          if (state is ClosureSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.queued
                      ? 'Rapport conservé hors connexion. Les opérations seront synchronisées avant son envoi.'
                      : 'Rapport envoyé avec succès.',
                ),
                backgroundColor: state.queued
                    ? AppColors.accent
                    : AppColors.notification,
              ),
            );
            if (!state.queued) Navigator.pop(context, true);
          }
          if (state is ClosureError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ClosureLoading && closure.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = closure['services'] is Map
              ? Map<String, dynamic>.from(closure['services'] as Map)
              : <String, dynamic>{};
          final validated = closure['status'] == 'validated';
          final count = int.tryParse('${closure['count']}') ?? 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _Header(date: date, count: count),
              if (validated) ...[
                const SizedBox(height: 12),
                const _Notice(
                  text:
                      'Ce rapport a déjà été envoyé. Seul l’administrateur peut le rouvrir depuis la liste des rapports.',
                  color: AppColors.success,
                  icon: Icons.verified,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Totaux par service',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650
                      ? 3
                      : 2,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: services.length,
                itemBuilder: (_, index) {
                  final entry = services.entries.elementAt(index);
                  final rawValues = summary[entry.key];
                  final values = rawValues is Map
                      ? Map<String, dynamic>.from(rawValues)
                      : <String, dynamic>{};
                  final info = entry.value;
                  return Material(
                    color: info.$3.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openOperations(entry.key),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(info.$2, color: info.$3),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    info.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                            const Spacer(),
                            FittedBox(
                              child: Text(
                                '${number(values['balance']).toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: info.$3,
                                ),
                              ),
                            ),
                            Text(
                              'Entrées ${number(values['entries']).toStringAsFixed(0)} • Sorties ${number(values['outputs']).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _Totals(
                totalIn: number(closure['total_in']),
                totalOut: number(closure['total_out']),
                balance: balance,
              ),
              const SizedBox(height: 20),
              if (count == 0)
                OutlinedButton.icon(
                  onPressed: () => _openOperations(null),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Ajouter une opération'),
                ),
              if (count > 0)
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: state is ClosureLoading || validated
                        ? null
                        : _confirm,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Envoyer'),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Envoyer le rapport ?'),
        content: const Text(
          'Les totaux sont calculés à partir de toutes les opérations de la journée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Relire'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ClosureCubit>().submit(widget.shopId, {'date': dateValue});
    }
  }

  Future<void> _openOperations(String? service) async {
    await Navigator.pushNamed(
      context,
      '/operations',
      arguments: {'shopId': widget.shopId, 'service': service},
    );
    if (mounted) {
      context.read<ClosureCubit>().loadDraft(widget.shopId, dateValue);
    }
  }
}

class _Header extends StatelessWidget {
  final DateTime date;
  final int count;
  const _Header({required this.date, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.fact_check_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rapport calculé depuis les opérations',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'opération' : 'opérations'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Totals extends StatelessWidget {
  final double totalIn, totalOut, balance;
  const _Totals({
    required this.totalIn,
    required this.totalOut,
    required this.balance,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(child: _value('Entrées', totalIn, AppColors.success)),
        Expanded(child: _value('Sorties', totalOut, AppColors.danger)),
        Expanded(child: _value('Solde', balance, AppColors.primary)),
      ],
    ),
  );
  Widget _value(String label, double value, Color color) => Column(
    children: [
      FittedBox(
        child: Text(
          '${value.toStringAsFixed(0)} FCFA',
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ],
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _Notice({required this.text, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
