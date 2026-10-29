import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../data/models/laundry_report.dart';
import '../../domain/models/laundry_workload.dart';
import '../../domain/services/tracking_service.dart';

bool laundryHasTimingWarning(LaundryReport? report, String id) {
  final details = report?.details[id];
  if (details == null) return false;
  final workload = details.workload(report!.evaluatedAt);
  if (!workload.needsTreatment) return false;
  final assessment = const TrackingService().assess(
    workload,
    now: report.evaluatedAt,
  );
  return assessment.isOverdue ||
      assessment.isAtRisk == true ||
      (details.estimatedMinutes != null &&
          details.processingStart != null &&
          report.evaluatedAt.isAfter(
            details.processingStart!.add(
              Duration(minutes: details.estimatedMinutes!),
            ),
          ));
}

/// Explains the exact same assessment used by the dashboard and sorting.
String? laundryTimingText(
  BuildContext context,
  LaundryReport? report,
  String id, {
  bool showPriority = false,
}) {
  final details = report?.details[id];
  if (details == null) return null;
  final workload = details.workload(report!.evaluatedAt);
  if (!workload.needsTreatment) return null;
  final timing = const TrackingService().assess(
    workload,
    now: report.evaluatedAt,
  );
  final messages = <String>[];
  if (showPriority) {
    final rank = report.priorities.indexWhere((p) => p.workload.item.id == id);
    if (rank >= 0) {
      messages.add(
        context.tr(
          fr: 'Ordre de traitement : ${rank + 1}',
          en: 'Treatment order: ${rank + 1}',
          ar: 'ترتيب المعالجة: ${rank + 1}',
        ),
      );
    }
  }
  if (timing.isOverdue) {
    messages.add(
      context.tr(
        fr: 'En retard : échéance dépassée.',
        en: 'Overdue: deadline passed.',
        ar: 'متأخر: تجاوز الموعد النهائي.',
      ),
    );
  } else if (timing.isAtRisk == true) {
    messages.add(
      context.tr(
        fr: 'À risque : le temps estimé dépasse le délai disponible.',
        en: 'At risk: estimated work exceeds the time available.',
        ar: 'معرّض للتأخير: المدة المقدرة تتجاوز الوقت المتاح.',
      ),
    );
  }
  if (details.dueAt != null) {
    final local = details.dueAt!.toLocal();
    final material = MaterialLocalizations.of(context);
    messages.add(
      '${material.formatMediumDate(local)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
    );
  } else {
    messages.add(
      context.tr(
        fr: 'Échéance non renseignée : retard non évaluable.',
        en: 'No deadline: delay cannot be assessed.',
        ar: 'لا موعد نهائي: لا يمكن تقييم التأخير.',
      ),
    );
  }
  if (details.estimatedMinutes != null &&
      details.processingStart != null &&
      report.evaluatedAt.isAfter(
        details.processingStart!.add(
          Duration(minutes: details.estimatedMinutes!),
        ),
      )) {
    messages.add(
      context.tr(
        fr: 'Durée indicative dépassée : reste à réévaluer.',
        en: 'Estimated duration exceeded: remaining work needs review.',
        ar: 'تم تجاوز المدة التقديرية: يجب إعادة تقييم العمل المتبقي.',
      ),
    );
  }
  if (details.urgency == LaundryUrgency.urgent) {
    messages.add(
      context.tr(fr: 'Demande urgente', en: 'Urgent request', ar: 'طلب عاجل'),
    );
  }
  if (showPriority) {
    messages.add(
      context.tr(
        fr: 'Tri : retard, risque, échéance, urgence, puis ancienneté du dépôt.',
        en: 'Order: overdue, risk, deadline, urgency, then deposit age.',
        ar: 'الترتيب: التأخير، الخطر، الموعد، الاستعجال، ثم أقدمية الإيداع.',
      ),
    );
  }
  return messages.join('\n');
}
