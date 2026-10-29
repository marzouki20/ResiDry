import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_status_change.dart';
import '../../data/models/laundry_details.dart';
import 'laundry_design.dart';

/// A bounded, scrollable dialog works with a small phone, large text and RTL.
class LaundryHistorySheet extends StatelessWidget {
  const LaundryHistorySheet({super.key, required this.details});
  final Future<LaundryDetails> details;
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [LaundryPalette.peach, LaundryPalette.lilac],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: LaundryPalette.plum,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.localize('Historique des statuts'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: FutureBuilder<LaundryDetails>(
              future: details,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.localize('Impossible de charger l’historique.'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  );
                }
                final data = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LaundryStatusPill(status: data.item.status),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          fr: 'Votre linge, étape par étape',
                          en: 'Your laundry, step by step',
                          ar: 'غسيلك، خطوة بخطوة',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        '#${data.item.id}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LaundryProgress(status: data.item.status),
                      const SizedBox(height: 24),
                      Text(
                        context.tr(
                          fr: '${data.history.length} événement(s) enregistré(s)',
                          en: '${data.history.length} recorded event(s)',
                          ar: '${data.history.length} أحداث مسجلة',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data.history.isEmpty)
                        Text(context.localize('Aucun changement enregistré.')),
                      for (var index = 0; index < data.history.length; index++)
                        _HistoryEvent(
                          change: data.history[index],
                          name: data
                              .actorNames[data.history[index].changedByUserId],
                          last: index == data.history.length - 1,
                        ),
                      if (data.lines.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          context.tr(
                            fr: 'Le contenu de votre demande',
                            en: 'Request contents',
                            ar: 'محتوى الطلب',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final line in data.lines)
                          _ArticleSummary(line: line),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(context.localize('Fermer')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryEvent extends StatelessWidget {
  const _HistoryEvent({required this.change, required this.last, this.name});
  final LaundryStatusChange change;
  final String? name;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final color = laundryStatusColor(change.newStatus);
    final date = change.changedAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    laundryStatusIcon(change.newStatus),
                    size: 19,
                    color: Colors.white,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: color.withValues(alpha: .22),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: .14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          change.oldStatus == null
                              ? context.localize('Création')
                              : laundryStatusText(context, change.oldStatus!),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: color,
                        ),
                        Text(laundryStatusText(context, change.newStatus)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.formatMediumDate(date)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (name != null)
                    Text(
                      name!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    context.localize(
                      change.changedByUserId == null
                          ? 'Auteur historique non associé'
                          : 'Utilisateur : ${change.changedByUserId}',
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleSummary extends StatelessWidget {
  const _ArticleSummary({required this.line});
  final LaundryLine line;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: LaundryPalette.mint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${line.quantity} × ${line.garment}',
          style: const TextStyle(
            color: LaundryPalette.teal,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.localize(switch (line.serviceId) {
            'washing' => 'Lavage',
            'ironing' => 'Repassage',
            'dry_cleaning' => 'Nettoyage à sec',
            _ => line.serviceId,
          }),
        ),
        if (line.weightGrams != null)
          Text('${(line.weightGrams! / 1000).toStringAsFixed(3)} kg'),
        if (line.instructions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(line.instructions),
          ),
        if (line.totalMillimes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${(line.totalMillimes! / 1000).toStringAsFixed(3)} DT',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: LaundryPalette.teal,
              ),
            ),
          ),
      ],
    ),
  );
}
