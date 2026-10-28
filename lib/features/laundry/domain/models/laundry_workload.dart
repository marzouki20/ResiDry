import '../../../../models/laundry_item.dart';

enum LaundryUrgency { normal, urgent }

/// Planning inputs around the existing shared LaundryItem. No duplicated user.
/// Additional inputs are supplied by persisted LaundryDetails.
class LaundryWorkload {
  LaundryWorkload({
    required this.item,
    DateTime? treatmentDueAt,
    this.urgency = LaundryUrgency.normal,
    this.estimatedRemainingTreatment,
  }) : treatmentDueAt = treatmentDueAt?.toUtc() {
    if (item.id.trim().isEmpty) {
      throw ArgumentError('A workload needs an existing request ID.');
    }
    if (treatmentDueAt != null && treatmentDueAt.isBefore(item.createdAt)) {
      throw ArgumentError('The deadline cannot precede request creation.');
    }
    if (estimatedRemainingTreatment != null &&
        estimatedRemainingTreatment!.isNegative) {
      throw ArgumentError('Remaining work cannot be negative.');
    }
  }

  final LaundryItem item;
  final DateTime? treatmentDueAt;
  final LaundryUrgency urgency;
  final Duration? estimatedRemainingTreatment;

  bool get needsTreatment =>
      item.status == LaundryStatus.deposited ||
      item.status == LaundryStatus.processing;
}

class LaundryTimingAssessment {
  const LaundryTimingAssessment({
    required this.workload,
    required this.evaluatedAt,
    required this.isOverdue,
    required this.isAtRisk,
    this.expectedReadyAt,
    this.slack,
  });

  final LaundryWorkload workload;
  final DateTime evaluatedAt;
  final bool isOverdue;

  /// Null means no reliable assessment (missing deadline or remaining duration).
  final bool? isAtRisk;
  final DateTime? expectedReadyAt;

  /// Deadline minus estimated completion. Negative means insufficient time.
  final Duration? slack;
}

enum LaundryPriorityReason {
  overdue,
  estimatedDeadlineMiss,
  deadlineKnown,
  urgent,
  noDeadline,
  remainingDurationUnknown,
}

class LaundryPriority {
  LaundryPriority({
    required this.timing,
    required List<LaundryPriorityReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final LaundryTimingAssessment timing;
  final List<LaundryPriorityReason> reasons;
  LaundryWorkload get workload => timing.workload;
}
