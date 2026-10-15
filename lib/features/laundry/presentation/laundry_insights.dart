import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/laundry_item.dart';
import '../data/models/laundry_role.dart';

/// Local workflow guidance, calculated from saved data; no remote AI service.
String laundryNextStep(LaundryStatus status) => switch (status) {
  LaundryStatus.deposited => 'En attente de prise en charge par le pressing.',
  LaundryStatus.processing => 'Votre linge est en cours de traitement.',
  LaundryStatus.ready => 'Votre linge est prêt pour la livraison.',
  LaundryStatus.delivered =>
    'Votre linge a été livré. Consultez son historique.',
};

String laundryDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à ${two(local.hour)}:${two(local.minute)}';
}

bool matchesLaundrySearch(LaundryItem item, String query) {
  final normalized = query.trim().toLowerCase();
  return normalized.isEmpty ||
      '${item.id} ${item.residentName} ${item.serviceType}'
          .toLowerCase()
          .contains(normalized);
}

class LaundryOverview extends StatelessWidget {
  const LaundryOverview({super.key, required this.items, required this.role});
  final List<LaundryItem> items;
  final LaundryRole role;

  @override
  Widget build(BuildContext context) {
    int count(LaundryStatus status) =>
        items.where((item) => item.status == status).length;
    final active = items
        .where((item) => item.status != LaundryStatus.delivered)
        .length;
    final entries = switch (role) {
      LaundryRole.resident => [
        ('En cours', active),
        ('Livrées', count(LaundryStatus.delivered)),
      ],
      LaundryRole.pressing => [
        ('À traiter', count(LaundryStatus.deposited)),
        ('En traitement', count(LaundryStatus.processing)),
      ],
      LaundryRole.driver => [
        ('À livrer', count(LaundryStatus.ready)),
        ('Livrées', count(LaundryStatus.delivered)),
      ],
      LaundryRole.admin => [
        ('Actives', active),
        (
          'Tarifs à valider',
          items.where((item) => !item.priceConfirmed).length,
        ),
      ],
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, value) in entries)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$label : $value',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LaundrySearchField extends StatelessWidget {
  const LaundrySearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: const InputDecoration(
      labelText: 'Rechercher une demande',
      hintText: 'Référence, service ou résident',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
  );
}
