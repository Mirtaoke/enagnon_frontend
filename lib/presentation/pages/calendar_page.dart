import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selected = DateTime.now();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Agenda & clôtures')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .25),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.accent,
                onPrimary: Colors.white,
                onSurface: Colors.white,
              ),
            ),
            child: CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime(2024),
              lastDate: DateTime(2035),
              onDateChanged: (date) => setState(() => selected = date),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(selected),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _AgendaTile(
          icon: Icons.lock_clock,
          color: AppColors.secondary,
          title: 'Clôtures journalières',
          subtitle: 'Consultez ou complétez les clôtures du jour',
        ),
        const _AgendaTile(
          icon: Icons.assessment_outlined,
          color: AppColors.accent,
          title: 'Rapports générés',
          subtitle: 'Les rapports apparaissent également dans les forums',
        ),
      ],
    ),
  );
}

class _AgendaTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _AgendaTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .14),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    ),
  );
}
