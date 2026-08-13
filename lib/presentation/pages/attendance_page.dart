import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/attendance_repository.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final repository = AttendanceRepository();
  Map<String, dynamic>? attendance;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final response = await repository.today();
      if (mounted) {
        setState(
          () => attendance = Map<String, dynamic>.from(
            response['attendance'] as Map,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _action(bool arrival) async {
    setState(() => loading = true);
    try {
      final response = arrival
          ? await repository.checkIn()
          : await repository.checkOut();
      if (mounted) {
        setState(
          () => attendance = Map<String, dynamic>.from(
            response['attendance'] as Map,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrived = attendance?['arrival_at'] != null;
    final left = attendance?['departure_at'] != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon pointage')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECE6FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: loading && attendance == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 54,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat(
                            'EEEE d MMMM yyyy',
                            'fr_FR',
                          ).format(DateTime.now()),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _TimeTile(
                    title: 'Heure d’arrivée',
                    value: _time(attendance?['arrival_at']),
                    icon: Icons.login_rounded,
                    color: AppColors.success,
                  ),
                  _TimeTile(
                    title: 'Heure de départ',
                    value: _time(attendance?['departure_at']),
                    icon: Icons.logout_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 22),
                  if (!arrived)
                    FilledButton.icon(
                      onPressed: loading ? null : () => _action(true),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Enregistrer mon arrivée'),
                    ),
                  if (arrived && !left)
                    FilledButton.icon(
                      onPressed: loading ? null : () => _action(false),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Enregistrer mon départ'),
                    ),
                  if (left)
                    const Center(
                      child: Chip(
                        avatar: Icon(Icons.verified, color: AppColors.success),
                        label: Text('Journée pointée avec succès'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _time(dynamic value) => value == null
      ? '--:--'
      : DateFormat('HH:mm').format(DateTime.parse('$value').toLocal());
}

class _TimeTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _TimeTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .13),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    ),
  );
}
