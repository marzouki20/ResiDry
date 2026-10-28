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
import '../widgets/laundry_request_editor.dart';
import '../widgets/laundry_timing.dart';

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
      warning: laundryHasTimingWarning(report, item.id),
      notice: [
        if (!canModify)
          context.localize(
            'Cette demande a été prise en charge et ne peut plus être modifiée.',
          ),
        if (laundryTimingText(context, report, item.id) != null)
          laundryTimingText(context, report, item.id)!,
      ].join('\n'),
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => LaundryRequestEditor(repository: _repository, item: item),
    );
    if (saved == true && mounted) await reload();
  }

  @override
  Future<List<LaundryItem>> fetchItems() async {
    final account = await _repository.getCurrentUser();
    if (laundryRoleFromUserRole(account.role) != LaundryRole.resident) {
      throw const LaundryException('Cet espace est réservé aux résidents.');
    }
    _account = account;
    report = await _repository.getReport();
    return report!.workloads.map((w) => w.item).toList();
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
