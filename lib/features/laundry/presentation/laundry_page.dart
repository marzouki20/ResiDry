import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_locale.dart';
import '../../../models/laundry_item.dart';
import '../../../models/laundry_role.dart';
import '../../../models/user.dart';
import '../data/repositories/laundry_repository.dart';
import 'widgets/laundry_request_editor.dart';
import 'pages/laundry_tariffs_page.dart';
import 'pages/laundry_dashboard_page.dart';
import 'widgets/laundry_async_state.dart';
import 'widgets/laundry_history_dialog.dart';
import 'widgets/laundry_insights.dart';
import 'widgets/laundry_design.dart';
import 'widgets/laundry_timing.dart';

class LaundryPage extends StatefulWidget {
  const LaundryPage({
    super.key,
    this.role = LaundryRole.admin,
    this.userName = '',
    this.currentUser,
    this.repository,
    this.showAppBar = true,
  });

  final LaundryRole role;
  final String userName;
  final User? currentUser;
  final LaundryRepository? repository;
  final bool showAppBar;

  @override
  State<LaundryPage> createState() => _LaundryPageState();
}

class _LaundryPageState extends State<LaundryPage>
    with LaundryAsyncState<LaundryPage> {
  late final LaundryRepository _repository =
      (widget.repository ?? LaundryRepository()).forUser(widget.currentUser);

  LaundryStatus? _selectedStatus;
  bool _onlyUnpriced = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = items
        .where(
          (item) =>
              (_selectedStatus == null || item.status == _selectedStatus) &&
              (!_onlyUnpriced || !item.priceConfirmed) &&
              matchesLaundrySearch(item, _search),
        )
        .toList();
    final confirmedTotal = items
        .where((item) => item.priceConfirmed)
        .fold<double>(0, (total, item) => total + item.price);

    final body = requestBody(
      CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LaundrySectionHeader(
                    accent: LaundryPalette.plum,
                    title: context.tr(
                      fr: 'Gestion du linge',
                      en: 'Laundry management',
                      ar: 'إدارة الغسيل',
                    ),
                    subtitle: context.tr(
                      fr: 'Toutes les demandes, un suivi clair.',
                      en: 'Every request, clearly tracked.',
                      ar: 'جميع الطلبات مع متابعة واضحة.',
                    ),
                    icon: Icons.local_laundry_service_outlined,
                    action: widget.showAppBar
                        ? null
                        : FilledButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(context.localize('Ajouter')),
                          ),
                  ),
                  Wrap(
                    children: [
                      LaundryDashboardButton(repository: _repository),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                LaundryTariffsPage(repository: _repository),
                          ),
                        ),
                        icon: const Icon(Icons.price_change_outlined),
                        label: Text(
                          context.tr(
                            fr: 'Tarifs',
                            en: 'Tariffs',
                            ar: '\u0627\u0644\u062a\u0639\u0631\u064a\u0641\u0627\u062a',
                          ),
                        ),
                      ),
                    ],
                  ),
                  LaundryOverview(items: items, role: LaundryRole.admin),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      context.tr(
                        fr: 'Total des tarifs validés : ${confirmedTotal.toStringAsFixed(3)} DT',
                        en: 'Confirmed prices total: ${confirmedTotal.toStringAsFixed(3)} DT',
                        ar: 'إجمالي الأسعار المؤكدة: ${confirmedTotal.toStringAsFixed(3)} DT',
                      ),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LaundrySearchField(
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFilters()),
          if (filteredItems.isEmpty)
            SliverToBoxAdapter(
              child: LaundryEmptyState(
                title: context.localize('Aucun élément trouvé'),
                description: context.tr(
                  fr: 'Ajoutez une demande ou ajustez vos filtres.',
                  en: 'Add a request or adjust your filters.',
                  ar: 'أضف طلبًا أو عدّل المرشحات.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) =>
                    _buildLaundryCard(filteredItems[index]),
              ),
            ),
        ],
      ),
    );
    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: Text(context.localize('Gestion du linge'))),
      body: body,
      floatingActionButton: loadError != null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'laundry-create',
              onPressed: busy || loading || loadError != null
                  ? null
                  : _showAddDialog,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(context.localize('Ajouter')),
            ),
    );
  }

  // ------------------------------------------------------------
  // FILTRES
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              label: Text(
                context.tr(
                  fr: 'Tarifs à valider',
                  en: 'Prices to confirm',
                  ar: 'أسعار بانتظار التأكيد',
                ),
              ),
              selected: _onlyUnpriced,
              onSelected: (value) => setState(() => _onlyUnpriced = value),
            ),
          ),
          _buildFilterChip(label: 'Toutes', status: null),
          _buildFilterChip(label: 'Déposé', status: LaundryStatus.deposited),
          _buildFilterChip(
            label: 'En traitement',
            status: LaundryStatus.processing,
          ),
          _buildFilterChip(label: 'Prêt', status: LaundryStatus.ready),
          _buildFilterChip(label: 'Livré', status: LaundryStatus.delivered),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required LaundryStatus? status,
  }) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(context.localize(label)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        selectedColor: AppColors.cyan.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.navy : AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: isSelected ? AppColors.cyan : AppColors.line),
      ),
    );
  }

  // ------------------------------------------------------------
  // LAUNDRY CARD
  // ------------------------------------------------------------

  Widget _buildLaundryCard(LaundryItem item) => LaundryRequestCard(
    item: item,
    showPrice: true,
    warning: laundryHasTimingWarning(report, item.id),
    notice: item.residentId == null
        ? context.localize('Aucun compte résident associé.')
        : laundryTimingText(context, report, item.id),
    actions: [
      TextButton.icon(
        onPressed: () => showLaundryHistory(context, _repository, item),
        icon: const Icon(Icons.history),
        label: Text(context.localize('Détails')),
      ),
      TextButton.icon(
        onPressed: () => _showEditDialog(item),
        icon: const Icon(Icons.edit_outlined),
        label: Text(context.localize('Modifier')),
      ),
      TextButton.icon(
        onPressed: () => _deleteItem(item),
        icon: const Icon(Icons.delete_outline),
        label: Text(context.localize('Supprimer')),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFB44242)),
      ),
    ],
  );

  @override
  Future<List<LaundryItem>> fetchItems() async {
    final account = await _repository.getCurrentUser();
    if (laundryRoleFromUserRole(account.role) != LaundryRole.admin) {
      throw const LaundryException(
        'Cet espace est réservé aux administrateurs.',
      );
    }
    report = await _repository.getReport();
    return report!.workloads.map((w) => w.item).toList();
  }

  void _showAddDialog() => _openAdminForm();
  void _showEditDialog(LaundryItem item) => _openAdminForm(item);

  Future<void> _openAdminForm([LaundryItem? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => LaundryRequestEditor(repository: _repository, item: item),
    );
    if (saved == true && mounted) await reload();
  }

  Future<void> _deleteItem(LaundryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.localize('Supprimer la commande')),
        content: Text('Supprimer la commande #${item.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.localize('Annuler')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.localize('Supprimer')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await perform(() async {
      await _repository.delete(item.id);
    });
  }
}
