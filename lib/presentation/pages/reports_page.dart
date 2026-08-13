import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../business_logic/cubits/report/report_cubit.dart';
import '../../business_logic/cubits/report/report_state.dart';
import '../../business_logic/cubits/shop/shop_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/report_model.dart';
import '../../data/models/shop_model.dart';
import '../../services/report_export_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Shop> shops = const [];
  int? shopId;
  String period = 'daily';
  bool initializing = true;
  final Set<int> selectedIds = {};
  bool exportOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final values = await context
          .read<ShopCubit>()
          .shopRepository
          .getAllShops();
      if (!mounted) return;
      setState(() {
        shops = values;
        shopId = null;
        initializing = false;
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => initializing = false);
        _snack('$error', false);
      }
    }
  }

  void _load() {
    if (shopId != null) {
      context.read<ReportCubit>().loadReports(shopId!, period: period);
    } else if (shops.isNotEmpty) {
      context.read<ReportCubit>().loadAllReports(
        shops.map((shop) => shop.id).toList(),
        period: period,
      );
    }
  }

  bool get isAdmin {
    final state = context.read<AuthCubit>().state;
    return state is AuthSuccess && state.user.role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final reportState = context.watch<ReportCubit>().state;
    final hasReports =
        reportState is ReportLoaded && reportState.reports.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIds.isEmpty
              ? 'Rapports'
              : '${selectedIds.length} sélectionné${selectedIds.length > 1 ? 's' : ''}',
        ),
        actions: [
          Tooltip(
            message: 'Exporter',
            child: FilledButton.tonalIcon(
              onPressed: !hasReports ? null : _export,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exporter'),
            ),
          ),
          if (hasReports)
            IconButton(
              tooltip: selectedIds.isEmpty
                  ? 'Tout sélectionner'
                  : 'Tout désélectionner',
              onPressed: () {
                final state = context.read<ReportCubit>().state;
                if (state is ReportLoaded) {
                  final all = state.reports.expand(_ids).toSet();
                  setState(() {
                    if (all.isNotEmpty && all.every(selectedIds.contains)) {
                      selectedIds.clear();
                    } else {
                      selectedIds
                        ..clear()
                        ..addAll(all);
                    }
                  });
                }
              },
              icon: Icon(
                selectedIds.isEmpty
                    ? Icons.select_all_rounded
                    : Icons.deselect_rounded,
              ),
            ),
          if (isAdmin)
            IconButton(
              tooltip: selectedIds.isEmpty
                  ? 'Supprimer tous les rapports'
                  : 'Supprimer la sélection',
              onPressed: !hasReports
                  ? null
                  : selectedIds.isEmpty
                  ? _deleteAll
                  : _deleteSelection,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: initializing
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 105),
                  children: [
                    if (shops.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(50),
                        child: Center(
                          child: Text('Aucun point de vente disponible.'),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: shopId,
                        decoration: const InputDecoration(
                          labelText: 'Point de vente',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Tous les points de vente'),
                          ),
                          ...shops.map(
                            (shop) => DropdownMenuItem(
                              value: shop.id,
                              child: Text(shop.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => shopId = value);
                          _load();
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(
                          () => searchQuery = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un rapport…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer la recherche',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'daily', label: Text('Jour')),
                          ButtonSegment(
                            value: 'weekly',
                            label: Text('Semaine'),
                          ),
                          ButtonSegment(value: 'monthly', label: Text('Mois')),
                        ],
                        selected: {period},
                        onSelectionChanged: (value) {
                          setState(() => period = value.first);
                          _load();
                        },
                      ),
                      const SizedBox(height: 18),
                      BlocBuilder<ReportCubit, ReportState>(
                        builder: (context, state) {
                          if (state is ReportLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (state is ReportError) {
                            return _Message(
                              icon: Icons.cloud_off,
                              text: state.message,
                            );
                          }
                          if (state is ReportLoaded) {
                            final reports = state.reports
                                .where(_matchesSearch)
                                .toList();
                            if (state.reports.isEmpty) {
                              return const _Message(
                                icon: Icons.description_outlined,
                                text:
                                    'Aucun rapport envoyé pour cette période.',
                              );
                            }
                            if (reports.isEmpty) {
                              return const _Message(
                                icon: Icons.search_off_rounded,
                                text:
                                    'Aucun rapport ne correspond à la recherche.',
                              );
                            }
                            return Column(
                              children: reports.map(_reportCard).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _reportCard(Report report) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onLongPress: () => setState(() => selectedIds.addAll(_ids(report))),
      onTap: selectedIds.isNotEmpty
          ? () => setState(() {
              final ids = _ids(report);
              ids.every(selectedIds.contains)
                  ? selectedIds.removeAll(ids)
                  : selectedIds.addAll(ids);
            })
          : report.id == 0
          ? null
          : () => Navigator.pushNamed(
              context,
              '/report-detail',
              arguments: {'shopId': report.shopId, 'reportId': report.id},
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (selectedIds.isNotEmpty)
                  Checkbox(
                    value: _ids(report).every(selectedIds.contains),
                    onChanged: (_) => setState(() {
                      final ids = _ids(report);
                      ids.every(selectedIds.contains)
                          ? selectedIds.removeAll(ids)
                          : selectedIds.addAll(ids);
                    }),
                  ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateLabel(report.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        report.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (isAdmin && selectedIds.isEmpty)
                  IconButton(
                    tooltip: 'Supprimer',
                    onPressed: () => report.id == 0
                        ? _deleteAggregate(report)
                        : _delete(report),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                  )
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _amount('Entrées', report.totalIn, AppColors.success),
                ),
                Expanded(
                  child: _amount('Sorties', report.totalOut, AppColors.danger),
                ),
                Expanded(
                  child: _amount(
                    'Solde',
                    report.cashBalance,
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  bool _matchesSearch(Report report) {
    if (searchQuery.isEmpty) return true;
    final shopName = shops
        .where((shop) => shop.id == report.shopId)
        .map((shop) => shop.name)
        .join(' ');
    final date = DateTime.tryParse(report.date);
    final searchableDate = date == null
        ? report.date
        : '${DateFormat('dd/MM/yyyy').format(date)} ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date)}';
    return '$shopName $searchableDate ${report.note}'.toLowerCase().contains(
      searchQuery,
    );
  }

  Widget _amount(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      FittedBox(
        child: Text(
          '${value.toStringAsFixed(0)} FCFA',
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ),
    ],
  );
  String _dateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return period == 'monthly'
        ? DateFormat('MMMM yyyy', 'fr_FR').format(date)
        : DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
  }

  Future<void> _export() async {
    if (exportOpen) return;
    exportOpen = true;
    try {
      final state = context.read<ReportCubit>().state;
      if (state is! ReportLoaded || state.reports.isEmpty) {
        _snack('Aucun rapport à exporter pour cette période.', false);
        return;
      }
      if (shopId == null) {
        _snack(
          'Choisis d’abord un point de vente pour exporter sa liste.',
          false,
        );
        return;
      }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir le format',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 14),
              _format(
                context,
                'pdf',
                'Document PDF',
                Icons.picture_as_pdf_outlined,
                AppColors.danger,
              ),
              _format(
                context,
                'xls',
                'Classeur Excel',
                Icons.table_chart_outlined,
                AppColors.success,
              ),
            ],
          ),
        ),
      );
      if (format == null || shopId == null) return;
      final service = ReportExportService();
      final export = await service.prepare(shopId!, format);
      if (!mounted) return;
      final download = await showModalBottomSheet<bool>(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre rapport est prêt',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                '${export.name}.${export.extension}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => OpenFilex.open(export.path),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ouvrir un aperçu'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger'),
                ),
              ),
            ],
          ),
        ),
      );
      if (download == true) {
        final path = await service.download(export);
        if (mounted) {
          _snack('Rapport enregistré : $path', true);
        }
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    } finally {
      exportOpen = false;
    }
  }

  Widget _format(
    BuildContext context,
    String value,
    String title,
    IconData icon,
    Color color,
  ) => ListTile(
    onTap: () => Navigator.pop(context, value),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      child: Icon(icon, color: color),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    trailing: const Icon(Icons.chevron_right),
  );

  Future<void> _delete(Report report) async {
    final repository = context.read<ShopCubit>().shopRepository;
    final confirmed = await _confirm(
      'Supprimer ce rapport ?',
      'Le vendeur pourra modifier ses opérations puis envoyer un nouveau rapport.',
    );
    if (!confirmed) return;
    try {
      await repository.deleteReport(report.shopId, report.id);
      _snack('Rapport supprimé. Il peut maintenant être renvoyé.', true);
      _load();
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _deleteAggregate(Report report) async {
    if (report.reportIds.isEmpty) return;
    final confirmed = await _confirm(
      'Supprimer ce rapport ${period == 'weekly' ? 'hebdomadaire' : 'mensuel'} ?',
      'Les ${report.reportIds.length} rapports journaliers inclus seront supprimés.',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<ShopCubit>().shopRepository.deleteSelectedReports(
        report.shopId,
        report.reportIds,
      );
      if (mounted) {
        _snack('Rapport supprimé.', true);
        _load();
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<void> _deleteAll() async {
    final repository = context.read<ShopCubit>().shopRepository;
    final confirmed = await _confirm(
      'Supprimer tous les rapports ?',
      'Tous les rapports de ce point seront retirés. Les opérations restent conservées.',
    );
    if (!confirmed) return;
    try {
      if (shopId == null) {
        await Future.wait(
          shops.map((shop) => repository.deleteAllReports(shop.id)),
        );
      } else {
        await repository.deleteAllReports(shopId!);
      }
      _snack('La liste des rapports a été supprimée.', true);
      _load();
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  List<int> _ids(Report report) => report.reportIds.isNotEmpty
      ? report.reportIds
      : report.id == 0
      ? const []
      : [report.id];

  Future<void> _deleteSelection() async {
    final confirmed = await _confirm(
      'Supprimer la sélection ?',
      '${selectedIds.length} rapport(s) journalier(s) inclus dans la sélection seront supprimés.',
    );
    if (!confirmed) return;
    if (!mounted) return;
    final state = context.read<ReportCubit>().state;
    if (state is! ReportLoaded) return;
    try {
      final byShop = <int, Set<int>>{};
      for (final report in state.reports) {
        final ids = _ids(report).where(selectedIds.contains);
        byShop.putIfAbsent(report.shopId, () => <int>{}).addAll(ids);
      }
      await Future.wait(
        byShop.entries.map(
          (entry) => context
              .read<ShopCubit>()
              .shopRepository
              .deleteSelectedReports(entry.key, entry.value.toList()),
        ),
      );
      if (mounted) {
        setState(selectedIds.clear);
        _snack('Rapports sélectionnés supprimés.', true);
        _load();
      }
    } catch (error) {
      if (mounted) _snack('$error', false);
    }
  }

  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ) ??
      false;
  void _snack(String text, bool success) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: success ? AppColors.notification : AppColors.danger,
        ),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 50),
    child: Column(
      children: [
        Icon(icon, size: 58, color: Colors.black26),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}
