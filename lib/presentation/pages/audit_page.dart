import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';

class AuditPage extends StatefulWidget {
  final int initialTab;
  final bool todayOnly;
  const AuditPage({super.key, this.initialTab = 0, this.todayOnly = false});
  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage>
    with SingleTickerProviderStateMixin {
  final api = ApiProvider();
  final storage = StorageProvider();
  List<Map<String, dynamic>> logs = const [];
  List<Map<String, dynamic>> attendances = const [];
  bool loading = true;
  Timer? refreshTimer;
  late final TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _load();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _load(silent: true),
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    try {
      final token = await storage.getToken();
      final response = await api.get('/audit?per_page=100', token: token);
      final attendanceResponse = await api.get(
        '/attendance${widget.todayOnly ? '?date=today' : ''}',
        token: token,
      );
      if (mounted) {
        setState(
          () => logs = (response['logs'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
        attendances = (attendanceResponse['attendances'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (error) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Suivi & audit'),
      bottom: TabBar(
        controller: tabs,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.accent,
        indicatorWeight: 4,
        tabs: const [
          Tab(icon: Icon(Icons.history_rounded), text: 'Activités'),
          Tab(icon: Icon(Icons.schedule_rounded), text: 'Présences'),
        ],
      ),
    ),
    body: SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: tabs,
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: logs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 180),
                            Center(child: Text('Aucune action enregistrée.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 105),
                          itemCount: logs.length,
                          itemBuilder: (_, index) {
                            final log = logs[index];
                            final action = '${log['action'] ?? ''}';
                            final user = log['user'] is Map
                                ? '${log['user']['name'] ?? 'Utilisateur'}'
                                : 'Système';
                            final date = DateTime.tryParse(
                              '${log['created_at']}',
                            )?.toLocal();
                            final style = _style(action);
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(13),
                                leading: CircleAvatar(
                                  backgroundColor: style.$2.withValues(
                                    alpha: .12,
                                  ),
                                  child: Icon(style.$1, color: style.$2),
                                ),
                                title: Text(
                                  _message(action, user),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  date == null
                                      ? ''
                                      : DateFormat(
                                          'dd/MM/yyyy à HH:mm',
                                        ).format(date),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: attendances.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 180),
                            Center(child: Text('Aucun pointage enregistré.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 105),
                          itemCount: attendances.length,
                          itemBuilder: (_, index) =>
                              _attendanceCard(attendances[index]),
                        ),
                ),
              ],
            ),
    ),
  );
  (IconData, Color) _style(String action) {
    if (action.contains('deleted')) {
      return (Icons.delete_outline, AppColors.danger);
    }
    if (action.contains('updated')) {
      return (Icons.edit_outlined, AppColors.accent);
    }
    if (action.contains('check_in')) return (Icons.login, AppColors.success);
    if (action.contains('check_out')) return (Icons.logout, AppColors.cyan);
    if (action.contains('report')) {
      return (Icons.description_outlined, AppColors.primary);
    }
    return (Icons.notifications_none, AppColors.secondary);
  }

  String _message(String action, String user) => switch (action) {
    'check_in' => '$user a enregistré son arrivée',
    'check_out' => '$user a enregistré son départ',
    'operation_created' => '$user a ajouté une opération',
    'operation_updated' => '$user a modifié une opération',
    'operation_deleted' => '$user a supprimé une opération',
    'report_sent' => '$user a envoyé un rapport',
    'report_deleted' => '$user a supprimé un rapport',
    'reports_cleared' => '$user a vidé une liste de rapports',
    'reports_deleted' => '$user a supprimé plusieurs rapports',
    'created' => '$user a effectué un ajout',
    'updated' => '$user a effectué une modification',
    'login' => '$user s’est connecté',
    'logout' => '$user s’est déconnecté',
    'employee_updated' => '$user a modifié un membre',
    'employee_deleted' => '$user a supprimé un membre',
    'shop_deleted' => '$user a supprimé un point de vente',
    'cash_adjusted' => '$user a effectué un mouvement de caisse',
    'profile_updated' => '$user a modifié son profil',
    _ => '$user • ${action.replaceAll('_', ' ')}',
  };

  Widget _attendanceCard(Map<String, dynamic> item) {
    final employee = item['employee'] is Map
        ? item['employee'] as Map
        : const {};
    final shop = item['shop'] is Map ? item['shop'] as Map : const {};
    final arrival = DateTime.tryParse('${item['arrival_at'] ?? ''}')?.toLocal();
    final departure = DateTime.tryParse(
      '${item['departure_at'] ?? ''}',
    )?.toLocal();
    final date = DateTime.tryParse('${item['date'] ?? ''}');
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE9E4FF),
                  child: Icon(Icons.person_pin_circle_outlined),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${employee['name'] ?? 'Membre'}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text('${shop['name'] ?? ''}'),
                    ],
                  ),
                ),
                Text(
                  date == null ? '' : DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _time('Arrivée', arrival, AppColors.success)),
                Expanded(child: _time('Départ', departure, AppColors.cyan)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _time(String label, DateTime? value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Text(
        value == null ? 'Non enregistré' : DateFormat('HH:mm').format(value),
        style: TextStyle(fontWeight: FontWeight.w900, color: color),
      ),
    ],
  );

  @override
  void dispose() {
    refreshTimer?.cancel();
    tabs.dispose();
    super.dispose();
  }
}
