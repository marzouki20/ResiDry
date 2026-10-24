import '../models/laundry_workload.dart';
import 'tracking_service.dart';

/// Treatment priorities only. No driver dispatch or machine assignment.
class PlanningService {
  const PlanningService();

  List<LaundryPriority> prioritize(
    Iterable<LaundryWorkload> workloads, {
    required DateTime now,
  }) {
    final inputs = workloads.toList();
    if (inputs.map((w) => w.item.id).toSet().length != inputs.length) {
      throw ArgumentError('Each request must occur only once in a plan.');
    }
    final ranked = <LaundryPriority>[];
    for (final workload in inputs) {
      final timing = const TrackingService().assess(workload, now: now);
      if (!workload.needsTreatment) continue;
      ranked.add(
        LaundryPriority(
          timing: timing,
          reasons: [
            if (timing.isOverdue) LaundryPriorityReason.overdue,
            if (timing.isAtRisk == true)
              LaundryPriorityReason.estimatedDeadlineMiss,
            if (workload.treatmentDueAt != null)
              LaundryPriorityReason.deadlineKnown
            else
              LaundryPriorityReason.noDeadline,
            if (workload.urgency == LaundryUrgency.urgent)
              LaundryPriorityReason.urgent,
            if (workload.estimatedRemainingTreatment == null)
              LaundryPriorityReason.remainingDurationUnknown,
          ],
        ),
      );
    }
    ranked.sort((a, b) {
      // Overdue, then estimated deadline misses, then earliest known deadline.
      var comparison = _trueFirst(a.timing.isOverdue, b.timing.isOverdue);
      if (comparison != 0) return comparison;
      comparison = _trueFirst(
        a.timing.isAtRisk == true,
        b.timing.isAtRisk == true,
      );
      if (comparison != 0) return comparison;
      final aDue = a.workload.treatmentDueAt;
      final bDue = b.workload.treatmentDueAt;
      if (aDue != null && bDue != null) {
        comparison = aDue.compareTo(bDue);
        if (comparison != 0) return comparison;
      } else if (aDue != null || bDue != null) {
        return aDue != null ? -1 : 1;
      }
      comparison = _trueFirst(
        a.workload.urgency == LaundryUrgency.urgent,
        b.workload.urgency == LaundryUrgency.urgent,
      );
      if (comparison != 0) return comparison;
      comparison = a.workload.item.createdAt.compareTo(
        b.workload.item.createdAt,
      );
      return comparison != 0
          ? comparison
          : a.workload.item.id.compareTo(b.workload.item.id);
    });
    return List.unmodifiable(ranked);
  }

  static int _trueFirst(bool a, bool b) => a == b
      ? 0
      : a
      ? -1
      : 1;
}
