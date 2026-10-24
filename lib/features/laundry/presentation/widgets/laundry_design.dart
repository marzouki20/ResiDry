import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_item.dart';

InputDecoration laundryFieldDecoration({
  required String label,
  IconData? icon,
  String? helper,
  String? suffix,
}) => InputDecoration(
  labelText: label,
  prefixIcon: icon == null ? null : Icon(icon, size: 20),
  helperText: helper,
  helperMaxLines: 3,
  errorMaxLines: 3,
  suffixText: suffix,
  filled: true,
  fillColor: AppColors.cream,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.cyan, width: 2),
  ),
);

String laundryStatusText(BuildContext context, LaundryStatus status) =>
    switch (status) {
      LaundryStatus.deposited => context.tr(
        fr: 'Déposé',
        en: 'Deposited',
        ar: 'تم الإيداع',
      ),
      LaundryStatus.processing => context.tr(
        fr: 'En traitement',
        en: 'Processing',
        ar: 'قيد المعالجة',
      ),
      LaundryStatus.ready => context.tr(fr: 'Prêt', en: 'Ready', ar: 'جاهز'),
      LaundryStatus.delivered => context.tr(
        fr: 'Livré',
        en: 'Delivered',
        ar: 'تم التسليم',
      ),
    };

Color laundryStatusColor(LaundryStatus status) => switch (status) {
  LaundryStatus.deposited => AppColors.navy,
  LaundryStatus.processing => const Color(0xFF087C91),
  LaundryStatus.ready => const Color(0xFF17754D),
  LaundryStatus.delivered => AppColors.muted,
};

IconData laundryStatusIcon(LaundryStatus status) => switch (status) {
  LaundryStatus.deposited => Icons.inventory_2_outlined,
  LaundryStatus.processing => Icons.local_laundry_service_outlined,
  LaundryStatus.ready => Icons.task_alt_rounded,
  LaundryStatus.delivered => Icons.check_circle_outline_rounded,
};

/// A single visual vocabulary for all four roles, with no data or permissions.
class LaundrySectionHeader extends StatelessWidget {
  const LaundrySectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [AppColors.navy, Color(0xFF15546F)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'RESIDRY',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2.5,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFE1EEF4), height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: 18),
          FilledButtonTheme(
            data: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            child: action!,
          ),
        ],
      ],
    ),
  );
}

class LaundryStatusPill extends StatelessWidget {
  const LaundryStatusPill({super.key, required this.status});
  final LaundryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = laundryStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(laundryStatusIcon(status), size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              laundryStatusText(context, status),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LaundryProgress extends StatelessWidget {
  const LaundryProgress({super.key, required this.status});
  final LaundryStatus status;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final step in LaundryStatus.values)
        Expanded(
          child: Semantics(
            selected: step == status,
            child: Column(
              children: [
                SizedBox(
                  height: 28,
                  child: Stack(
                    children: [
                      Center(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                color: step.index == 0
                                    ? Colors.transparent
                                    : step.index <= status.index
                                    ? AppColors.cyan
                                    : AppColors.line,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: step == LaundryStatus.delivered
                                    ? Colors.transparent
                                    : step.index < status.index
                                    ? AppColors.cyan
                                    : AppColors.line,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: ExcludeSemantics(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.index <= status.index
                                  ? AppColors.navy
                                  : AppColors.cream,
                              border: Border.all(
                                color: step.index <= status.index
                                    ? AppColors.navy
                                    : AppColors.line,
                              ),
                            ),
                            child: Icon(
                              step.index < status.index
                                  ? Icons.check_rounded
                                  : laundryStatusIcon(step),
                              size: 14,
                              color: step.index <= status.index
                                  ? Colors.white
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  laundryStatusText(context, step),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: step == status
                        ? FontWeight.w800
                        : FontWeight.w400,
                    color: step == status ? AppColors.navy : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class LaundryRequestCard extends StatelessWidget {
  const LaundryRequestCard({
    super.key,
    required this.item,
    required this.actions,
    this.showPrice = false,
    this.showResident = true,
    this.showProgress = false,
    this.title,
    this.notice,
  });
  final LaundryItem item;
  final List<Widget> actions;
  final bool showPrice;
  final bool showResident;
  final bool showProgress;
  final String? title;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final local = item.createdAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title ?? '#${item.id}',
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                LaundryStatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.serviceType,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (showResident) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.residentName,
                      style: const TextStyle(color: AppColors.ink, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              context.tr(
                fr: 'Créée le $date',
                en: 'Created $date',
                ar: 'أُنشئ في $date',
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (showPrice) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.priceConfirmed
                      ? '${item.price.toStringAsFixed(2)} DT'
                      : context.tr(
                          fr: 'À tarifer',
                          en: 'Awaiting pricing',
                          ar: 'بانتظار التسعير',
                        ),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (showProgress) ...[
              const SizedBox(height: 20),
              LaundryProgress(status: item.status),
            ],
            if (notice != null) ...[
              const SizedBox(height: 14),
              Text(
                notice!,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 6),
                child: Divider(height: 1, color: AppColors.line),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LaundryEmptyState extends StatelessWidget {
  const LaundryEmptyState({
    super.key,
    required this.title,
    this.description,
    this.action,
    this.icon = Icons.local_laundry_service_outlined,
  });
  final String title;
  final String? description;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, size: 32, color: AppColors.navy),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
