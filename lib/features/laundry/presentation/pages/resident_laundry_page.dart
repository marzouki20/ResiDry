import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_role.dart';
import '../../../../models/user.dart';
import '../../data/repositories/laundry_repository.dart';
import '../widgets/laundry_async_state.dart';
import '../widgets/laundry_history_dialog.dart';
import '../widgets/laundry_insights.dart';

// Laundry requests belonging to one resident.
class ResidentLaundryPage extends StatefulWidget {
  const ResidentLaundryPage({
    super.key,
    this.residentId,
    this.residentName,
    this.currentUser,
    this.repository,
    this.embedded = false,
  });

  final int? residentId;
  final String? residentName;
  final User? currentUser;
  final LaundryRepository? repository;
  final bool embedded;

  @override
  State<ResidentLaundryPage> createState() => _ResidentLaundryPageState();
}

class _ResidentLaundryPageState extends State<ResidentLaundryPage>
    with LaundryAsyncState<ResidentLaundryPage> {
  bool _showDelivered = false;
  User? _account;

  int get _residentId => _account?.id ?? 0;
  String get _residentName => _account?.name ?? '';
  LaundryRepository get _repository =>
      (widget.repository ?? LaundryRepository()).forUser(widget.currentUser);

  @override
  Widget build(BuildContext context) {
    // Read only this resident's requests.

    final body = requestBody(
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenue, $_residentName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),

          const SizedBox(height: 16),

          LaundryOverview(items: items, role: LaundryRole.resident),

          // CREATE
          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle demande'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('En cours'),
                selected: !_showDelivered,
                onSelected: (_) => setState(() => _showDelivered = false),
              ),
              ChoiceChip(
                label: const Text('Livrées'),
                selected: _showDelivered,
                onSelected: (_) => setState(() => _showDelivered = true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Vous n’avez aucune demande de linge.'),
              ),
            ),

          // READ
          if (items.isNotEmpty &&
              !items.any(
                (item) =>
                    (item.status == LaundryStatus.delivered) == _showDelivered,
              ))
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune demande dans cette catégorie.'),
            ),
          for (final item in items.where(
            (item) =>
                (item.status == LaundryStatus.delivered) == _showDelivered,
          ))
            _buildItemCard(item),
        ],
      ),
    );
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mes demandes de linge'),
        backgroundColor: AppColors.cream,
      ),
      body: body,
    );
  }

  // Display one laundry request.
  Widget _buildItemCard(LaundryItem item) {
    final canModify = item.status == LaundryStatus.deposited;

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
            Text(
              '#${item.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),

            const SizedBox(height: 8),

            Text('Service : ${item.serviceType}'),
            Text('Statut : ${_statusLabel(item.status)}'),
            Text('Créée le ${laundryDate(item.createdAt)}'),
            const SizedBox(height: 8),
            Text(
              laundryNextStep(item.status),
              style: const TextStyle(color: AppColors.muted),
            ),
            if (!canModify)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Cette demande a été prise en charge et ne peut plus être modifiée.',
                ),
              ),

            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: () => showLaundryHistory(
                context,
                _repository,
                item,
                residentId: _residentId,
              ),
              icon: const Icon(Icons.history),
              label: const Text('Historique'),
            ),
            if (canModify)
              Wrap(
                spacing: 8,
                children: [
                  // UPDATE
                  TextButton.icon(
                    onPressed: () => _openForm(item: item),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),

                  // DELETE
                  TextButton.icon(
                    onPressed: () => _confirmDelete(item),
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

  // Convert the laundry status to French.
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

  // Open the create/edit dialog and handle the result.
  Future<void> _openForm({LaundryItem? item}) async {
    final service = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _LaundryRequestDialog(item: item);
      },
    );

    // Stop if the user cancelled or the page was removed.
    if (service == null || !mounted) return;

    await perform(() async {
      if (item == null) {
        await _repository.addForResident(
          LaundryItem(
            id: 'LD${DateTime.now().microsecondsSinceEpoch}',
            residentId: _residentId,
            residentName: _residentName,
            serviceType: service,
            price: 0,
            status: LaundryStatus.deposited,
          ),
          residentId: _residentId,
        );
      } else {
        await _repository.updateForResident(
          item.copyWith(serviceType: service),
          residentId: _residentId,
        );
      }
    });
  }

  @override
  Future<List<LaundryItem>> fetchItems() async {
    final account = await _repository.getCurrentUser();
    if (laundryRoleFromUserRole(account.role) != LaundryRole.resident) {
      throw const LaundryException('Cet espace est réservé aux résidents.');
    }
    _account = account;
    return _repository.getByResidentId(account.id!);
  }

  @override
  void didUpdateWidget(covariant ResidentLaundryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.residentId != widget.residentId ||
        oldWidget.currentUser != widget.currentUser ||
        oldWidget.repository != widget.repository) {
      items = [];
      _account = null;
      reload();
    }
  }

  // Ask for confirmation before deleting.
  Future<void> _confirmDelete(LaundryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la demande ?'),
          content: Text('Voulez-vous supprimer la demande ${item.id} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE45858),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await perform(() async {
      await _repository.deleteForResident(item.id, residentId: _residentId);
    });
  }
}

// Separate dialog that owns its TextEditingControllers.
class _LaundryRequestDialog extends StatefulWidget {
  const _LaundryRequestDialog({this.item});

  final LaundryItem? item;

  @override
  State<_LaundryRequestDialog> createState() => _LaundryRequestDialogState();
}

class _LaundryRequestDialogState extends State<_LaundryRequestDialog> {
  late final TextEditingController _serviceController;

  // Runs when the dialog is created.
  @override
  void initState() {
    super.initState();

    _serviceController = TextEditingController(
      text: widget.item?.serviceType ?? '',
    );
  }

  // Runs when Flutter permanently removes the dialog.
  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  // Validate the form and return the entered values.
  void _save() {
    final service = _serviceController.text.trim();

    if (service.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez préciser le service souhaité.')),
      );
      return;
    }

    Navigator.pop(context, service);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Nouvelle demande' : 'Modifier la demande',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Type de service',
                prefixIcon: Icon(Icons.local_laundry_service_outlined),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final service in [
                  'Lavage',
                  'Repassage',
                  'Nettoyage à sec',
                ])
                  ActionChip(
                    label: Text(service),
                    onPressed: () => _serviceController.text = service,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Choisissez un service ou décrivez votre besoin. Vous pourrez modifier votre demande avant sa prise en charge.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
