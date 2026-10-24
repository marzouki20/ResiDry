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
import 'laundry_dashboard_page.dart';

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
          LaundrySectionHeader(
            title: context.tr(
              fr: 'Bienvenue, $_residentName',
              en: 'Welcome, $_residentName',
              ar: 'مرحبًا، $_residentName',
            ),
            subtitle: context.tr(
              fr: 'Confiez votre linge, suivez chaque étape.',
              en: 'Send your laundry and follow every step.',
              ar: 'أرسل غسيلك وتابع كل مرحلة.',
            ),
            icon: Icons.local_laundry_service_outlined,
            action: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.localize('Nouvelle demande')),
            ),
          ),
          LaundryDashboardButton(repository: _repository),
          LaundryOverview(items: items, role: LaundryRole.resident),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.localize('En cours')),
                selected: !_showDelivered,
                onSelected: (_) => setState(() => _showDelivered = false),
              ),
              ChoiceChip(
                label: Text(context.localize('Livrées')),
                selected: _showDelivered,
                onSelected: (_) => setState(() => _showDelivered = true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (items.isEmpty)
            LaundryEmptyState(
              title: context.localize('Vous n’avez aucune demande de linge.'),
              description: context.tr(
                fr: 'Votre première demande commence ici.',
                en: 'Your first request starts here.',
                ar: 'ابدأ طلبك الأول هنا.',
              ),
            ),
          if (items.isNotEmpty &&
              !items.any(
                (item) =>
                    (item.status == LaundryStatus.delivered) == _showDelivered,
              ))
            LaundryEmptyState(
              title: context.localize('Aucune demande dans cette catégorie.'),
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
        title: Text(context.localize('Mes demandes de linge')),
        backgroundColor: AppColors.cream,
      ),
      body: body,
    );
  }

  // Display one laundry request.
  Widget _buildItemCard(LaundryItem item) {
    final canModify = item.status == LaundryStatus.deposited;
    return LaundryRequestCard(
      item: item,
      showResident: false,
      showProgress: true,
      notice: !canModify
          ? context.localize(
              'Cette demande a été prise en charge et ne peut plus être modifiée.',
            )
          : null,
      actions: [
        TextButton.icon(
          onPressed: () => showLaundryHistory(
            context,
            _repository,
            item,
            residentId: _residentId,
          ),
          icon: const Icon(Icons.history),
          label: Text(context.localize('Historique')),
        ),
        if (canModify) ...[
          TextButton.icon(
            onPressed: () => _openForm(item: item),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.localize('Modifier')),
          ),
          TextButton.icon(
            onPressed: () => _confirmDelete(item),
            icon: const Icon(Icons.delete_outline),
            label: Text(context.localize('Supprimer')),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB44242),
            ),
          ),
        ],
      ],
    );
  }

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
          title: Text(context.localize('Supprimer la demande ?')),
          content: Text('Voulez-vous supprimer la demande ${item.id} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.localize('Annuler')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE45858),
              ),
              child: Text(context.localize('Supprimer')),
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
        SnackBar(
          content: Text(
            context.localize('Veuillez préciser le service souhaité.'),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, service);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(
        Icons.local_laundry_service_outlined,
        color: AppColors.navy,
      ),
      title: Text(
        context.localize(
          widget.item == null ? 'Nouvelle demande' : 'Modifier la demande',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _serviceController,
              decoration: laundryFieldDecoration(
                label: context.tr(
                  fr: 'Type de service',
                  en: 'Service type',
                  ar: 'نوع الخدمة',
                ),
                icon: Icons.local_laundry_service_outlined,
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
                    label: Text(context.localize(service)),
                    onPressed: () => _serviceController.text = service,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.localize(
                'Choisissez un service ou décrivez votre besoin. Vous pourrez modifier votre demande avant sa prise en charge.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.localize('Annuler')),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
          ),
          child: Text(context.localize('Enregistrer')),
        ),
      ],
    );
  }
}
