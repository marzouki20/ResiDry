import 'package:flutter/material.dart';

import 'laundry_async_state.dart';
import 'laundry_history_dialog.dart';
import 'laundry_insights.dart';
import '../data/models/laundry_role.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/laundry_item.dart';
import '../data/repositories/laundry_repository.dart';

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
          final byStatus = first.status.index.compareTo(second.status.index);
          return byStatus != 0
              ? byStatus
              : first.createdAt.compareTo(second.createdAt);
        });

    return requestBody(
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role == LaundryRole.driver
                      ? 'Livraison du linge'
                      : 'Gestion du pressing',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  widget.role == LaundryRole.driver
                      ? 'Livrez les demandes prêtes, puis consultez les livraisons effectuées.'
                      : 'Prenez en charge les dépôts et terminez les traitements en cours.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: LaundryOverview(items: items, role: widget.role),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: LaundrySearchField(
              onChanged: (value) => setState(() => _search = value),
            ),
          ),

          // Filters
          SingleChildScrollView(
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

          const SizedBox(height: 12),

          // Laundry requests
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('Aucune demande trouvée.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _laundryCard(filteredItems[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Filter by laundry status
  Widget _filterChip(String label, LaundryStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
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
  Widget _laundryCard(LaundryItem item) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                const Icon(
                  Icons.local_laundry_service_outlined,
                  color: AppColors.navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Commande #${item.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text('Résident : ${item.residentName}'),
            Text('Service : ${item.serviceType}'),
            if (widget.role == LaundryRole.pressing)
              Text(
                item.priceConfirmed
                    ? 'Tarif validé : ${item.price.toStringAsFixed(2)} DT'
                    : 'Tarif à valider par l’administrateur',
              ),
            Text('Statut : ${_statusLabel(item.status)}'),
            Text('Créée le ${laundryDate(item.createdAt)}'),
            TextButton.icon(
              onPressed: () =>
                  showLaundryHistory(context, widget.repository, item),
              icon: const Icon(Icons.history),
              label: const Text('Historique'),
            ),

            const SizedBox(height: 16),

            if (widget.role == LaundryRole.driver &&
                item.status == LaundryStatus.ready)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(item, LaundryStatus.delivered),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Marquer comme livré'),
                ),
              ),
            // Start cleaning
            if (widget.role == LaundryRole.pressing &&
                item.status == LaundryStatus.deposited)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _updateStatus(item, LaundryStatus.processing);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Commencer le traitement'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                ),
              ),

            // Finish cleaning
            if (widget.role == LaundryRole.pressing &&
                item.status == LaundryStatus.processing)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _updateStatus(item, LaundryStatus.ready);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marquer comme prêt'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Future<List<LaundryItem>> fetchItems() async {
    final all = await widget.repository.getAll();
    return widget.role == LaundryRole.driver
        ? all
              .where(
                (item) =>
                    item.status == LaundryStatus.ready ||
                    item.status == LaundryStatus.delivered,
              )
              .toList()
        : all;
  }

  Future<void> _updateStatus(LaundryItem item, LaundryStatus newStatus) async {
    if (widget.role == LaundryRole.driver) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la livraison ?'),
          content: Text(
            'Confirmez que le linge de ${item.residentName} a bien été remis. Cette action termine la demande.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer la livraison'),
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
        role: widget.role,
        changedByUserId: widget.userId,
      );
      if (mounted && widget.role == LaundryRole.driver) {
        setState(() => selectedStatus = LaundryStatus.delivered);
      }
    });
  }

  // Convert enum values into French labels
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
}

/// Public pressing screen retained for existing callers.
class PressingLaundryPage extends StatelessWidget {
  const PressingLaundryPage({super.key, required this.repository, this.userId});
  final LaundryRepository repository;
  final int? userId;

  @override
  Widget build(BuildContext context) => LaundryWorkflowView(
    repository: repository,
    role: LaundryRole.pressing,
    userId: userId,
  );
}
