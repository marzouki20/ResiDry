import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_role.dart';
import 'laundry_design.dart';

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
        (
          context.tr(fr: 'À livrer', en: 'To deliver', ar: 'بانتظار التسليم'),
          count(LaundryStatus.ready),
        ),
        ('Livrées', count(LaundryStatus.delivered)),
      ],
      LaundryRole.admin => [
        (
          context.tr(
            fr: 'Total des demandes',
            en: 'Total requests',
            ar: 'إجمالي الطلبات',
          ),
          items.length,
        ),
        (context.tr(fr: 'Actives', en: 'Active', ar: 'النشطة'), active),
        ('Livrées', count(LaundryStatus.delivered)),
        (
          context.tr(
            fr: 'Tarifs à valider',
            en: 'Prices to confirm',
            ar: 'أسعار بانتظار التأكيد',
          ),
          items.where((item) => !item.priceConfirmed).length,
        ),
      ],
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (index, (label, value)) in entries.indexed)
              Container(
                width: constraints.maxWidth > 280
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const [
                    LaundryPalette.mint,
                    LaundryPalette.lilac,
                    LaundryPalette.peach,
                    LaundryPalette.sky,
                  ][index % 4],
                  border: Border.all(color: Colors.white.withValues(alpha: .7)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.localize(label),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    decoration: InputDecoration(
      labelText: context.tr(
        fr: 'Rechercher une demande',
        en: 'Search requests',
        ar: 'البحث عن طلب',
      ),
      hintText: context.tr(
        fr: 'Référence, service ou résident',
        en: 'Reference, service or resident',
        ar: 'المرجع أو الخدمة أو المقيم',
      ),
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
    ),
  );
}
