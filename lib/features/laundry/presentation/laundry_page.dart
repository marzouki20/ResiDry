import 'laundry_async_state.dart';
import 'laundry_admin_dialog.dart';
import 'laundry_history_dialog.dart';
import 'laundry_insights.dart';

import 'package:flutter/material.dart';

import '../data/models/laundry_role.dart';

import '../data/repositories/laundry_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../casiers/presentation/widgets/casier_components.dart';
import '../data/models/laundry_item.dart';

class LaundryPage extends StatefulWidget {
  const LaundryPage({
    super.key,
    this.role = LaundryRole.admin,
    this.userName = '',
    this.repository,
    this.showAppBar = true,
  });

  final LaundryRole role;
  final String userName;
  final LaundryRepository? repository;
  final bool showAppBar;

  @override
  State<LaundryPage> createState() => _LaundryPageState();
}

class _LaundryPageState extends State<LaundryPage>
    with LaundryAsyncState<LaundryPage> {
  late final LaundryRepository _repository =
      widget.repository ?? LaundryRepository();

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
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: PageHeading(
              title: 'Gestion du linge',
              subtitle:
                  'Suivez les commandes de linge et leur état de traitement.',
              trailing: FilledButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LaundryOverview(items: items, role: LaundryRole.admin),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total des tarifs validés : ${confirmedTotal.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: LaundrySearchField(
              onChanged: (value) => setState(() => _search = value),
            ),
          ),

          _buildFilters(),

          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun élément trouvé',
                      style: TextStyle(color: AppColors.muted, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return _buildLaundryCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion du linge')),
      body: body,
      floatingActionButton: FloatingActionButton(
        heroTag: 'laundry-create',
        onPressed: busy || loading ? null : _showAddDialog,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tarifs à valider'),
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
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
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

  Widget _buildLaundryCard(LaundryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service_outlined,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.id}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.residentName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildStatusBadge(item.status),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_laundry_service_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.serviceType,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.priceConfirmed
                        ? '${item.price.toStringAsFixed(2)} DT'
                        : 'À tarifer',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Créée le ${laundryDate(item.createdAt)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (item.residentId == null)
              const Text(
                'Aucun compte résident associé.',
                style: TextStyle(color: AppColors.muted),
              ),

            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      showLaundryHistory(context, _repository, item),
                  icon: const Icon(Icons.history),
                  label: const Text('Détails'),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showEditDialog(item);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    _deleteItem(item);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE45858),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS BADGE
  // ------------------------------------------------------------

  Widget _buildStatusBadge(LaundryStatus status) {
    final label = _statusLabel(status);

    Color color;

    switch (status) {
      case LaundryStatus.deposited:
        color = const Color(0xFFE77B32);
        break;

      case LaundryStatus.processing:
        color = const Color(0xFF7457E8);
        break;

      case LaundryStatus.ready:
        color = AppColors.cyan;
        break;

      case LaundryStatus.delivered:
        color = const Color(0xFF4CAF50);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD
  // ------------------------------------------------------------

  @override
  Future<List<LaundryItem>> fetchItems() => _repository.getAll();

  void _showAddDialog() => _openAdminForm();
  void _showEditDialog(LaundryItem item) => _openAdminForm(item);

  Future<void> _openAdminForm([LaundryItem? item]) async {
    final result = await showDialog<LaundryItem>(
      context: context,
      builder: (_) => LaundryAdminDialog(item: item),
    );
    if (result == null || !mounted) return;
    await perform(() async {
      if (item == null) {
        await _repository.add(result);
      } else {
        await _repository.update(result);
      }
    });
  }

  Future<void> _deleteItem(LaundryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la commande'),
        content: Text('Supprimer la commande #${item.id} ?'),
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
    if (confirmed != true || !mounted) return;
    await perform(() async {
      await _repository.delete(item.id);
    });
  }

  String _statusLabel(LaundryStatus status) {
    switch (status) {
      case LaundryStatus.deposited:
        return 'Déposé';

      case LaundryStatus.processing:
        return 'En traitement';

      case LaundryStatus.ready:
        return 'Prêt';

      case LaundryStatus.delivered:
        return 'Livré';
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------
}
