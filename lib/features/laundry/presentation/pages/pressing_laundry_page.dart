import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_role.dart';
import '../../../../models/user.dart';
import '../../data/repositories/laundry_repository.dart';
import '../widgets/laundry_async_state.dart';
import '../widgets/laundry_history_dialog.dart';
import '../widgets/laundry_insights.dart';
import '../widgets/laundry_design.dart';
import '../../data/models/laundry_report.dart';
import 'laundry_dashboard_page.dart';
import '../widgets/laundry_timing.dart';

class LaundryWorkflowView extends StatefulWidget {
  const LaundryWorkflowView({
    super.key,
    required this.repository,
    required this.role,
    this.userId,
  });

  final LaundryRepository repository;
  final LaundryRole role;
  final int? userId;

  @override
  State<LaundryWorkflowView> createState() => _LaundryWorkflowViewState();
}

class _LaundryWorkflowViewState extends State<LaundryWorkflowView>
    with LaundryAsyncState<LaundryWorkflowView> {
  LaundryStatus? selectedStatus;
  String _search = '';
  LaundryReport? _report;
  bool _sortByPriority = true;

  @override
  void initState() {
    selectedStatus = widget.role == LaundryRole.driver
        ? LaundryStatus.ready
        : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems =
        items.where((item) {
          final visible =
              widget.role != LaundryRole.driver ||
              item.status == LaundryStatus.ready ||
              item.status == LaundryStatus.delivered;
          return visible &&
              (selectedStatus == null || item.status == selectedStatus) &&
              matchesLaundrySearch(item, _search);
        }).toList()..sort((first, second) {
          if (widget.role == LaundryRole.pressing && _sortByPriority) {
            final priorities = _report?.priorities ?? [];
            final firstRank = priorities.indexWhere(
              (p) => p.workload.item.id == first.id,
            );
            final secondRank = priorities.indexWhere(
              (p) => p.workload.item.id == second.id,
            );
            final a = firstRank < 0 ? priorities.length : firstRank;
            final b = secondRank < 0 ? priorities.length : secondRank;
            final priority = a.compareTo(b);
            if (priority != 0) return priority;
          }
          final byStatus = first.status.index.compareTo(second.status.index);
          return byStatus != 0
              ? byStatus
              : first.createdAt.compareTo(second.createdAt);
        });

    return requestBody(
      CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  LaundrySectionHeader(
                    accent: widget.role == LaundryRole.driver
                        ? AppColors.cyan
                        : LaundryPalette.teal,
                    title: context.localize(
                      widget.role == LaundryRole.driver
                          ? 'Livraison du linge'
                          : 'Gestion du pressing',
                    ),
                    subtitle: widget.role == LaundryRole.driver
                        ? context.tr(
                            fr: 'Les demandes prêtes, vos prochaines livraisons.',
                            en: 'Ready requests, your next deliveries.',
                            ar: 'الطلبات الجاهزة لتسليمها.',
                          )
                        : context.tr(
                            fr: 'Du dépôt au linge prêt, une étape à la fois.',
                            en: 'From deposited to ready, one step at a time.',
                            ar: 'من الإيداع إلى الجاهزية، خطوة بخطوة.',
                          ),
                    icon: widget.role == LaundryRole.driver
                        ? Icons.local_shipping_outlined
                        : Icons.local_laundry_service_outlined,
                  ),
                  LaundryDashboardButton(repository: widget.repository),
                  LaundryOverview(items: items, role: widget.role),
                  if (widget.role == LaundryRole.pressing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(
                              context.tr(
                                fr: 'Priorité de traitement',
                                en: 'Treatment priority',
                                ar: 'أولوية المعالجة',
                              ),
                            ),
                            selected: _sortByPriority,
                            onSelected: (_) =>
                                setState(() => _sortByPriority = true),
                          ),
                          ChoiceChip(
                            label: Text(
                              context.tr(
                                fr: 'Par statut',
                                en: 'By status',
                                ar: 'حسب الحالة',
                              ),
                            ),
                            selected: !_sortByPriority,
                            onSelected: (_) =>
                                setState(() => _sortByPriority = false),
                          ),
                        ],
                      ),
                    ),
                  LaundrySearchField(
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip('Toutes', null),
                  if (widget.role == LaundryRole.pressing)
                    _filterChip('Déposé', LaundryStatus.deposited),
                  if (widget.role == LaundryRole.pressing)
                    _filterChip('En traitement', LaundryStatus.processing),
                  _filterChip('Prêt', LaundryStatus.ready),
                  _filterChip('Livré', LaundryStatus.delivered),
                ],
              ),
            ),
          ),
          if (filteredItems.isEmpty)
            SliverToBoxAdapter(
              child: LaundryEmptyState(
                title: context.localize('Aucune demande trouvée.'),
                description: context.tr(
                  fr: 'Ajustez vos filtres ou actualisez la liste.',
                  en: 'Adjust your filters or refresh the list.',
                  ar: 'عدّل المرشحات أو حدّث القائمة.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) =>
                    _laundryCard(filteredItems[index]),
              ),
            ),
        ],
      ),
    );
  }

  // Filter by laundry status
  Widget _filterChip(String label, LaundryStatus? status) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(context.localize(label)),
        selected: selectedStatus == status,
        selectedColor: AppColors.cyan.withValues(alpha: 0.18),
        onSelected: (_) {
          setState(() {
            selectedStatus = status;
          });
        },
      ),
    );
  }

  // Display one laundry request
  Widget _laundryCard(LaundryItem item) => LaundryRequestCard(
    item: item,
    title: context.localize('Commande #${item.id}'),
    showPrice: widget.role == LaundryRole.pressing,
    warning: laundryHasTimingWarning(_report, item.id),
    notice: _priorityExplanation(item),
    actions: [
      TextButton.icon(
        onPressed: () => showLaundryHistory(context, widget.repository, item),
        icon: const Icon(Icons.history),
        label: Text(context.localize('Historique')),
      ),
      if (widget.role == LaundryRole.driver &&
          item.status == LaundryStatus.ready)
        FilledButton.icon(
          onPressed: () => _updateStatus(item, LaundryStatus.delivered),
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(context.localize('Marquer comme livré')),
        ),
      if (widget.role == LaundryRole.pressing &&
          item.status == LaundryStatus.deposited)
        FilledButton.icon(
          onPressed: () => _updateStatus(item, LaundryStatus.processing),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.localize('Commencer le traitement')),
        ),
      if (widget.role == LaundryRole.pressing &&
          item.status == LaundryStatus.processing)
        FilledButton.icon(
          onPressed: () => _updateStatus(item, LaundryStatus.ready),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(context.localize('Marquer comme prêt')),
        ),
    ],
  );

  @override
  Future<List<LaundryItem>> fetchItems() async {
    final account = await widget.repository.getCurrentUser();
    if (laundryRoleFromUserRole(account.role) != widget.role) {
      throw const LaundryException(
        'Votre rôle ne permet pas l’accès à cet espace.',
      );
    }
    final report = await widget.repository.getReport();
    _report = report;
    this.report = report;
    return report.workloads.map((workload) => workload.item).toList();
  }

  String? _priorityExplanation(LaundryItem item) {
    if (widget.role != LaundryRole.pressing || _report == null) return null;
    return laundryTimingText(context, _report, item.id, showPriority: true);
  }

  Future<void> _updateStatus(LaundryItem item, LaundryStatus newStatus) async {
    if (widget.role == LaundryRole.driver) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.localize('Confirmer la livraison ?')),
          content: Text(
            'Confirmez que le linge de ${item.residentName} a bien été remis. Cette action termine la demande.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.localize('Annuler')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.localize('Confirmer la livraison')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await perform(() async {
      await widget.repository.transitionStatus(
        item.id,
        expectedStatus: item.status,
        newStatus: newStatus,
      );
      if (mounted && widget.role == LaundryRole.driver) {
        setState(() => selectedStatus = LaundryStatus.delivered);
      }
    });
  }

  // Convert enum values into French labels
}

/// Public pressing screen retained for existing callers.
class PressingLaundryPage extends StatelessWidget {
  const PressingLaundryPage({
    super.key,
    this.repository,
    this.userId,
    this.currentUser,
  });

  final LaundryRepository? repository;
  final int? userId;
  final User? currentUser;

  @override
  Widget build(BuildContext context) => LaundryWorkflowView(
    repository: (repository ?? LaundryRepository()).forUser(currentUser),
    role: LaundryRole.pressing,
    userId: currentUser?.id ?? userId,
  );
}
