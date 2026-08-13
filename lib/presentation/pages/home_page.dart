import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../business_logic/cubits/shop/shop_state.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const HomePage({super.key, this.onNavigate});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String chartPeriod = 'day';
  bool cashHistoryOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => context.read<ShopCubit>().loadSummary(
    month: DateFormat('yyyy-MM').format(month),
    chartPeriod: chartPeriod,
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth is AuthSuccess ? auth.user : null;
    final isAdmin = user?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Vue d’ensemble' : 'Mon espace'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Historique des mouvements de caisse',
              onPressed: _cashHistory,
              icon: const Icon(Icons.receipt_long_outlined),
            ),
          if (!isAdmin)
            IconButton(
              tooltip: 'Pointer',
              onPressed: () => Navigator.pushNamed(context, '/attendance'),
              icon: const Icon(Icons.fingerprint),
            ),
          IconButton(
            tooltip: 'Mon profil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDE7FF), AppColors.background, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BlocBuilder<ShopCubit, ShopState>(
            builder: (context, state) {
              if (state is ShopLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ShopError) {
                return _Error(message: state.message, retry: _load);
              }
              if (state is! ShopSummaryLoaded) return const SizedBox.shrink();
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 105),
                  children: [
                    _Welcome(name: user?.name ?? '', admin: isAdmin),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                          ? 4
                          : 2,
                      childAspectRatio: MediaQuery.sizeOf(context).width < 380
                          ? 1.13
                          : 1.3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      children: isAdmin
                          ? [
                              DashboardCard(
                                title: state.reportCount == 1
                                    ? 'Rapport'
                                    : 'Rapports',
                                value: '${state.reportCount}',
                                icon: Icons.assessment_outlined,
                                backgroundColor: AppColors.accent,
                                onTap: () => widget.onNavigate?.call(2),
                              ),
                              DashboardCard(
                                title: state.employeeCount == 1
                                    ? 'Employé'
                                    : 'Employés',
                                value: '${state.employeeCount}',
                                icon: Icons.badge_outlined,
                                backgroundColor: AppColors.cyan,
                                onTap: () => widget.onNavigate?.call(1),
                              ),
                              DashboardCard(
                                title: 'Points actifs',
                                value: '${state.activeShopCount}',
                                icon: Icons.storefront,
                                backgroundColor: AppColors.success,
                                onTap: () => widget.onNavigate?.call(1),
                              ),
                              DashboardCard(
                                title: 'Caisse globale',
                                value:
                                    '${state.cashBalance.toStringAsFixed(0)} FCFA',
                                icon: Icons.account_balance_wallet_outlined,
                                backgroundColor: AppColors.primary,
                                onTap: () => widget.onNavigate?.call(1),
                              ),
                            ]
                          : [
                              DashboardCard(
                                title: 'Ma caisse',
                                value:
                                    '${state.cashBalance.toStringAsFixed(0)} FCFA',
                                icon: Icons.account_balance_wallet,
                                backgroundColor: AppColors.success,
                                onTap: () => widget.onNavigate?.call(1),
                              ),
                              DashboardCard(
                                title: 'Nouvelle opération',
                                value: 'Ajouter',
                                icon: Icons.add_card_rounded,
                                backgroundColor: AppColors.primary,
                                onTap: () => widget.onNavigate?.call(2),
                              ),
                              DashboardCard(
                                title: 'Mon pointage',
                                value: 'Arrivée / départ',
                                icon: Icons.fingerprint,
                                backgroundColor: AppColors.cyan,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/attendance'),
                              ),
                              DashboardCard(
                                title: 'Mon profil',
                                value: 'Consulter',
                                icon: Icons.person_outline,
                                backgroundColor: AppColors.accent,
                                onTap: () => widget.onNavigate?.call(3),
                              ),
                            ],
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 24),
                      _AttendanceChart(
                        present: state.presentEmployeeCount,
                        total: state.employeeCount,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/attendance-overview',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ChartCard(
                        points: state.salesChart,
                        period: chartPeriod,
                        month: month,
                        months: chartPeriod == 'month'
                            ? List.generate(
                                5,
                                (index) =>
                                    DateTime(DateTime.now().year - index, 1),
                              )
                            : List.generate(
                                12,
                                (index) => DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month - index,
                                ),
                              ),
                        onMonth: (value) {
                          setState(() => month = value);
                          _load();
                        },
                        onPeriod: (value) {
                          setState(() {
                            chartPeriod = value;
                            if (value != 'month') {
                              month = DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                              );
                            }
                          });
                          _load();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      isAdmin ? 'Points de vente' : 'Mon point de vente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    ...state.shops.map(
                      (shop) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: .12,
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: AppColors.secondary,
                            ),
                          ),
                          title: Text(
                            shop.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [
                              '${shop.employeesCount} ${shop.employeesCount == 1 ? 'membre' : 'membres'}',
                              if (shop.address.trim().isNotEmpty) shop.address,
                            ].join(' • '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Navigator.pushNamed(
                                context,
                                '/shop-detail',
                                arguments: shop.id,
                              ).then((_) {
                                if (mounted) _load();
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _cashHistory() async {
    if (cashHistoryOpen) return;
    cashHistoryOpen = true;
    try {
      final token = await StorageProvider().getToken();
      final response = await ApiProvider().get(
        '/cash-adjustments',
        token: token,
      );
      if (!mounted) return;
      final items = (response['movements'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: .82,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              18 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              children: [
                const Text(
                  'Mouvements de caisse effectués',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Aucun mouvement effectué.'))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, index) {
                            final item = items[index];
                            final deposit = item['direction'] == 'in';
                            final shop = item['shop'] is Map
                                ? item['shop'] as Map
                                : const {};
                            final date = DateTime.tryParse(
                              '${item['occurred_at'] ?? ''}',
                            )?.toLocal();
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (deposit
                                              ? AppColors.success
                                              : AppColors.danger)
                                          .withValues(alpha: .12),
                                  child: Icon(
                                    deposit ? Icons.add : Icons.remove,
                                    color: deposit
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                                title: Text(
                                  '${deposit ? 'Dépôt' : 'Retrait'} • ${shop['name'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item['description'] ?? ''}${date == null ? '' : '\n${DateFormat('dd/MM/yyyy à HH:mm').format(date)}'}',
                                ),
                                trailing: Text(
                                  '${deposit ? '+' : '-'}${item['amount']} FCFA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: deposit
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      cashHistoryOpen = false;
    }
  }
}

class _AttendanceChart extends StatelessWidget {
  final int present;
  final int total;
  final VoidCallback onTap;
  const _AttendanceChart({
    required this.present,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (present / total).clamp(0.0, 1.0);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 11,
                        backgroundColor: AppColors.danger.withValues(
                          alpha: .16,
                        ),
                        color: AppColors.secondary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(ratio * 100).round()} %',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Présence du jour',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text('$present présent${present > 1 ? 's' : ''}'),
                    Text(
                      '${total - present} absent${total - present > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Voir les membres et leurs points de vente',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final String name;
  final bool admin;
  const _Welcome({required this.name, required this.admin});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .25),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: Colors.white24,
          child: Icon(
            admin ? Icons.admin_panel_settings : Icons.storefront,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                admin
                    ? 'Bienvenue Admin'
                    : 'Bienvenue ${name.trim().split(RegExp(r'\s+')).first}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                admin
                    ? 'Suivi global de votre activité'
                    : 'Enregistrez chaque entrée et chaque sortie',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChartCard extends StatefulWidget {
  final List<Map<String, dynamic>> points;
  final String period;
  final DateTime month;
  final List<DateTime> months;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<String> onPeriod;
  const _ChartCard({
    required this.points,
    required this.period,
    required this.month,
    required this.months,
    required this.onMonth,
    required this.onPeriod,
  });

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int? selectedIndex;

  Map<String, dynamic>? get selected =>
      selectedIndex == null || widget.points.isEmpty
      ? null
      : widget.points[selectedIndex!.clamp(0, widget.points.length - 1)];

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution des opérations',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          const Text(
            'Entrées enregistrées pour tous les services',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'day', label: Text('Jour')),
              ButtonSegment(value: 'week', label: Text('Semaine')),
              ButtonSegment(value: 'month', label: Text('Mois')),
            ],
            selected: {widget.period},
            onSelectionChanged: (values) {
              setState(() => selectedIndex = null);
              widget.onPeriod(values.first);
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<DateTime>(
              value: widget.months.firstWhere(
                (value) =>
                    value.year == widget.month.year &&
                    (widget.period == 'month' ||
                        value.month == widget.month.month),
              ),
              underline: const SizedBox(),
              items: widget.months
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        widget.period == 'month'
                            ? DateFormat('yyyy', 'fr_FR').format(value)
                            : DateFormat('MMM yyyy', 'fr_FR').format(value),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedIndex = null);
                  widget.onMonth(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (widget.points.isEmpty) return;
                const left = 34.0;
                final width = constraints.maxWidth - left - 6;
                final ratio = ((details.localPosition.dx - left) / width).clamp(
                  0.0,
                  1.0,
                );
                setState(
                  () => selectedIndex = (ratio * (widget.points.length - 1))
                      .round(),
                );
              },
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SalesChartPainter(
                    widget.points,
                    period: widget.period,
                    selectedIndex: selectedIndex,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: selected == null
                ? const _ChartHint()
                : _DayLegend(
                    key: ValueKey(selectedIndex),
                    data: selected!,
                    period: widget.period,
                  ),
          ),
        ],
      ),
    ),
  );
}

class _SalesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final String period;
  final int? selectedIndex;
  _SalesChartPainter(this.points, {required this.period, this.selectedIndex});
  @override
  void paint(Canvas canvas, Size size) {
    final values = points
        .map((item) => double.tryParse('${item['total']}') ?? 0)
        .toList();
    if (values.isEmpty) return;
    const left = 34.0, bottom = 24.0, top = 10.0;
    final width = size.width - left - 6;
    final height = size.height - top - bottom;
    final grid = Paint()
      ..color = const Color(0xFFE8E3F3)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
    }
    final maxValue = math.max(1.0, values.reduce(math.max));
    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x =
          left + (values.length == 1 ? 0 : width * i / (values.length - 1));
      final y = top + height * (1 - values[i] / maxValue);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, top + height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(left + width, top + height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x556C4DFF), Color(0x056C4DFF)],
        ).createShader(Rect.fromLTWH(left, top, width, height)),
    );
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < values.length) {
      final index = selectedIndex!;
      final x =
          left + (values.length == 1 ? 0 : width * index / (values.length - 1));
      final y = top + height * (1 - values[index] / maxValue);
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        Paint()
          ..color = AppColors.secondary.withValues(alpha: .35)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = AppColors.secondary);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final labelStep = period == 'day' ? 5 : 1;
    for (var i = 0; i < values.length; i += labelStep) {
      final x = left + width * i / math.max(1, values.length - 1);
      final painter = TextPainter(
        text: TextSpan(
          text: _axisLabel(i),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, size.height - bottom + 7),
      );
    }
    final maxText = TextPainter(
      text: TextSpan(
        text: _short(maxValue),
        style: const TextStyle(fontSize: 9, color: Colors.black54),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    maxText.paint(canvas, Offset(0, top - 4));
  }

  String _short(double value) => value >= 1000000
      ? '${(value / 1000000).toStringAsFixed(1)}M'
      : value >= 1000
      ? '${(value / 1000).toStringAsFixed(0)}k'
      : value.toStringAsFixed(0);
  String _axisLabel(int index) {
    final date = DateTime.tryParse('${points[index]['date']}');
    if (date == null) return '${index + 1}';
    if (period == 'month') return DateFormat('MMM', 'fr_FR').format(date);
    if (period == 'week') return 'S${index + 1}';
    return '${date.day}';
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.period != period ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _ChartHint extends StatelessWidget {
  const _ChartHint();
  @override
  Widget build(BuildContext context) => const Row(
    key: ValueKey('hint'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.touch_app_outlined, size: 18, color: Colors.black45),
      SizedBox(width: 7),
      Flexible(
        child: Text(
          'Touchez un point du graphe pour voir les détails',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    ],
  );
}

class _DayLegend extends StatelessWidget {
  final Map<String, dynamic> data;
  final String period;
  const _DayLegend({super.key, required this.data, required this.period});
  double number(String key) => double.tryParse('${data[key]}') ?? 0;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${data['date']}');
    final difference = number('difference');
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            _dateLabel(date),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final values = [
                ('Entrées', number('entries'), AppColors.success),
                ('Sorties', number('outputs'), AppColors.danger),
                (
                  'Écart / veille',
                  difference,
                  difference >= 0 ? AppColors.success : AppColors.danger,
                ),
              ];
              if (constraints.maxWidth < 390) {
                return Column(
                  children: values
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: _valueRow(item.$1, item.$2, item.$3),
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: values
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _value(item.$1, item.$2, item.$3),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '${data['date']}';
    if (period == 'month') {
      return DateFormat('MMMM yyyy', 'fr_FR').format(date);
    }
    if (period == 'week') {
      final end = date.add(const Duration(days: 6));
      return 'Semaine du ${DateFormat('d MMM', 'fr_FR').format(date)} au ${DateFormat('d MMM', 'fr_FR').format(end)}';
    }
    return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
  }

  Widget _value(String label, double value, Color color) => Column(
    children: [
      FittedBox(
        child: Text(
          '${value >= 0 && label.startsWith('Écart') ? '+' : ''}${value.toStringAsFixed(0)} FCFA',
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      ),
    ],
  );

  Widget _valueRow(String label, double value, Color color) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${value >= 0 && label.startsWith('Écart') ? '+' : ''}${value.toStringAsFixed(0)} FCFA',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ),
    ],
  );
}

class _Error extends StatelessWidget {
  final String message;
  final Future<void> Function() retry;
  const _Error({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 55, color: AppColors.danger),
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
