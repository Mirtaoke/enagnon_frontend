import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../services/report_export_service.dart';

class ReportDetailPage extends StatelessWidget {
  final int shopId;
  final int reportId;
  const ReportDetailPage({
    super.key,
    required this.shopId,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rapport'),
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => _export(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exporter'),
        ),
        const SizedBox(width: 10),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: context.read<ShopCubit>().shopRepository.getReportDetail(
        shopId,
        reportId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('${snapshot.error}', textAlign: TextAlign.center),
          );
        }
        final data = snapshot.data!;
        final report = Map<String, dynamic>.from(data['report'] as Map);
        final closure = Map<String, dynamic>.from(data['closure'] as Map);
        final channels = data['channels'] as List? ?? const [];
        final operations = data['operation_details'] as List? ?? const [];
        final validator = closure['validator'] is Map
            ? Map<String, dynamic>.from(closure['validator'] as Map)
            : const <String, dynamic>{};
        final submitted = DateTime.tryParse(
          '${closure['submitted_at'] ?? ''}',
        )?.toLocal();
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            32 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RAPPORT JOURNALIER VALIDÉ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat(
                      'dd MMMM yyyy',
                      'fr_FR',
                    ).format(DateTime.parse('${report['date']}')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${report['note'] ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _moneyRow(
              'CAISSE À L’OUVERTURE',
              _num(data['opening_balance']),
              strong: true,
            ),
            const Divider(height: 22),
            ...channels.map((item) {
              final row = Map<String, dynamic>.from(item as Map);
              return _flowRow(
                row['label'].toString(),
                _num(row['entries']),
                _num(row['outputs']),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'OPÉRATIONS EFFECTUÉES',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...operations.map((item) {
              final row = Map<String, dynamic>.from(item as Map);
              final output = row['direction'] == 'out';
              final extra = [
                if ('${row['phone'] ?? ''}'.isNotEmpty) '${row['phone']}',
                if ('${row['network'] ?? ''}'.isNotEmpty) '${row['network']}',
                if ('${row['time'] ?? ''}'.isNotEmpty) '${row['time']}',
              ].join(' • ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    output ? Icons.north_east : Icons.south_west,
                    color: output ? AppColors.danger : AppColors.success,
                  ),
                  title: Text(
                    '${output ? 'Retrait' : 'Dépôt'} ${row['service_label'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  isThreeLine: true,
                  subtitle: Text(
                    [
                      if ('${row['description'] ?? ''}'.isNotEmpty)
                        '${row['description']}',
                      if (extra.isNotEmpty) extra,
                    ].join('\n'),
                  ),
                  trailing: Text(
                    '${output ? '-' : '+'}${_num(row['amount']).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: output ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
              );
            }),
            const Divider(height: 28),
            _moneyRow(
              'TOTAL ENCAISSEMENTS',
              _num(report['total_in']),
              strong: true,
              color: AppColors.success,
            ),
            _moneyRow(
              'TOTAL DÉCAISSEMENTS',
              _num(report['total_out']),
              strong: true,
              color: AppColors.danger,
            ),
            const Divider(height: 28),
            _moneyRow(
              'TOTAL DU JOUR',
              _num(report['cash_balance']),
              strong: true,
              color: AppColors.primary,
            ),
            _moneyRow(
              'CAISSE APRÈS LA JOURNÉE',
              _num(data['opening_balance']) + _num(report['cash_balance']),
              strong: true,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Validé par ${validator['name'] ?? 'Agent non renseigné'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              submitted == null
                  ? ''
                  : 'Le ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(submitted)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    ),
  );

  Future<void> _export(BuildContext context) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          26 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Exporter ce rapport détaillé',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: AppColors.danger,
              ),
              title: const Text('Document PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.primary),
              title: const Text('Classeur Excel'),
              onTap: () => Navigator.pop(context, 'xls'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !context.mounted) return;
    final service = ReportExportService();
    final file = await service.prepare(shopId, format, reportId: reportId);
    if (!context.mounted) return;
    await OpenFilex.open(file.path);
    await service.download(file);
  }

  static double _num(dynamic value) => double.tryParse('$value') ?? 0;
  static Widget _moneyRow(
    String label,
    double amount, {
    bool strong = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        FittedBox(
          child: Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ],
    ),
  );

  static Widget _flowRow(String label, double entries, double outputs) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (entries != 0)
              Text(
                '+${entries.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if (entries != 0 && outputs != 0) const SizedBox(width: 10),
            if (outputs != 0)
              Text(
                '-${outputs.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      );
}
