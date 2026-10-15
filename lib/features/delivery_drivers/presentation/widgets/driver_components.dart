import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/delivery_order.dart';

class MissionStatusPill extends StatelessWidget {
  const MissionStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'À récupérer' => (
          const Color(0xFFE77B32),
          context.tr(en: 'To collect', fr: 'À récupérer')
        ),
      'En transit' => (
          AppColors.navy,
          context.tr(en: 'In transit', fr: 'En transit')
        ),
      'En lavage' => (
          const Color(0xFF7457E8),
          context.tr(en: 'At laundry', fr: 'En lavage')
        ),
      'En transit retour' => (
          AppColors.navy,
          context.tr(en: 'Return transit', fr: 'Transit retour')
        ),
      'Déposé au casier' => (
          AppColors.cyan,
          context.tr(en: 'In locker', fr: 'Déposé casier')
        ),
      'Livré' => (AppColors.cyan, context.tr(en: 'Delivered', fr: 'Livré')),
      _ => (AppColors.muted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          LocalizedText(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryOrderCard extends StatelessWidget {
  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.onAdvanceStatus,
    required this.onOpenLocker,
  });

  final DeliveryOrder order;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onOpenLocker;

  @override
  Widget build(BuildContext context) {
    final isCollect = order.type == 'Collecte';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCollect
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCollect ? Icons.upload_outlined : Icons.download_outlined,
                    color: isCollect ? const Color(0xFFE77B32) : AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          LocalizedText(
                            '· ${order.type == 'Collecte' ? context.tr(en: 'Collection', fr: 'Collecte') : context.tr(en: 'Delivery', fr: 'Livraison')}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      LocalizedText(
                        '${order.residentName} (${order.apartment})',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                MissionStatusPill(order.status),
              ],
            ),
            const Divider(height: 20, color: AppColors.line),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    Icons.door_front_door_outlined,
                    context.tr(en: 'Locker', fr: 'Casier'),
                    order.lockerId,
                  ),
                ),
                Expanded(
                  child: _infoTile(
                    Icons.local_laundry_service_outlined,
                    context.tr(en: 'Partner', fr: 'Partenaire'),
                    order.laundryCompany,
                  ),
                ),
                Expanded(
                  child: _infoTile(
                    Icons.scale_outlined,
                    context.tr(en: 'Weight', fr: 'Poids'),
                    '${order.weight} kg',
                  ),
                ),
              ],
            ),
            if (order.notes != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LocalizedText(order.notes!,
                          style: const TextStyle(
                              color: AppColors.navy, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenLocker,
                    icon: const Icon(Icons.key_rounded, size: 18),
                    label: LocalizedText(
                      '${context.tr(en: 'Access', fr: 'Accès')} ${order.lockerId}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAdvanceStatus,
                    icon: Icon(_actionIcon(order.status), size: 18),
                    label: LocalizedText(_actionLabel(context, order.status)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                LocalizedText(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );

  IconData _actionIcon(String status) => switch (status) {
        'À récupérer' => Icons.directions_run_rounded,
        'En transit' => Icons.local_laundry_service_rounded,
        'En lavage' => Icons.local_shipping_rounded,
        'En transit retour' => Icons.lock_open_rounded,
        _ => Icons.check_circle_outline_rounded,
      };

  String _actionLabel(BuildContext context, String status) => switch (status) {
        'À récupérer' => context.tr(en: 'Collect', fr: 'Récupérer'),
        'En transit' => context.tr(en: 'Laundry drop-off', fr: 'Dépôt Lavage'),
        'En lavage' => context.tr(en: 'Pick up', fr: 'Prise en charge'),
        'En transit retour' =>
          context.tr(en: 'Deposit in locker', fr: 'Déposer casier'),
        'Déposé au casier' => context.tr(en: 'Complete', fr: 'Finaliser'),
        _ => context.tr(en: 'Completed', fr: 'Terminé'),
      };
}

class DriverMetricCard extends StatelessWidget {
  const DriverMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.navy,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 10),
            LocalizedText(
              value,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            LocalizedText(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              LocalizedText(caption!,
                  style: TextStyle(color: color, fontSize: 10)),
            ],
          ],
        ),
      );
}
