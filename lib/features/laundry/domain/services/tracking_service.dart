import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_status_change.dart';
import '../models/laundry_workload.dart';

class TrackingService {
  const TrackingService();

  LaundryTimingAssessment assess(
    LaundryWorkload workload, {
    required DateTime now,
  }) {
    final instant = now.toUtc();
    if (workload.item.createdAt.isAfter(instant)) {
      throw ArgumentError('A request cannot be created in the future.');
    }
    final due = workload.treatmentDueAt;
    final remaining = workload.estimatedRemainingTreatment;
    final expected = workload.needsTreatment && remaining != null
        ? instant.add(remaining)
        : null;
    return LaundryTimingAssessment(
      workload: workload,
      evaluatedAt: instant,
      isOverdue: workload.needsTreatment && due != null && instant.isAfter(due),
      isAtRisk: !workload.needsTreatment
          ? false
          : due == null || expected == null
          ? null
          : expected.isAfter(due),
      expectedReadyAt: expected,
      slack: due != null && expected != null ? due.difference(expected) : null,
    );
  }

  /// Only a complete, coherent processing -> ready interval is measurable.
  /// Missing/legacy or contradictory history returns null, never a fake zero.
  Duration? processingDuration(
    LaundryItem item,
    Iterable<LaundryStatusChange> history, {
    required DateTime now,
  }) {
    if (item.status != LaundryStatus.ready &&
        item.status != LaundryStatus.delivered) {
      return null;
    }
    final events = history.toList()
      ..sort((a, b) {
        final time = a.changedAt.compareTo(b.changedAt);
        return time != 0 ? time : a.id.compareTo(b.id);
      });
    if (events.isEmpty ||
        events.map((e) => e.id).toSet().length != events.length) {
      return null;
    }
    DateTime? startedAt;
    DateTime? readyAt;
    LaundryStatus? previous;
    for (final event in events) {
      if (event.laundryId != item.id ||
          event.changedAt.isBefore(item.createdAt) ||
          event.changedAt.isAfter(now) ||
          event.oldStatus != previous) {
        return null;
      }
      if (previous == null) {
        if (event.newStatus != LaundryStatus.deposited) return null;
      } else if (event.newStatus.index != previous.index + 1) {
        return null;
      }
      if (event.newStatus == LaundryStatus.processing) {
        startedAt = event.changedAt;
      }
      if (event.newStatus == LaundryStatus.ready) {
        readyAt = event.changedAt;
      }
      previous = event.newStatus;
    }
    if (previous != item.status || startedAt == null || readyAt == null) {
      return null;
    }
    return readyAt.difference(startedAt);
  }
}
