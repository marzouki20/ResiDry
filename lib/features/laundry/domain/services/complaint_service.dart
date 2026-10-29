import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_status_change.dart';
import '../models/laundry_complaint.dart';
import 'tracking_service.dart';

class ComplaintService {
  const ComplaintService();
  static const minDescriptionLength = 10;
  static const maxDescriptionLength = 2000;
  static const maxPhotos = 3;
  static const maxPhotoBytes = 2 * 1024 * 1024;

  bool validText(String value) =>
      value.trim().runes.length >= minDescriptionLength &&
      value.trim().runes.length <= maxDescriptionLength;

  bool allows(ComplaintStatus from, ComplaintStatus to) =>
      from == ComplaintStatus.submitted && to == ComplaintStatus.reviewing ||
      from == ComplaintStatus.reviewing &&
          (to == ComplaintStatus.resolved || to == ComplaintStatus.rejected);

  /// Treatment deadlines only; no invented delivery deadline or responsibility.
  bool confirmedTreatmentDelay({
    required LaundryItem item,
    required DateTime? dueAt,
    required Iterable<LaundryStatusChange> history,
    required DateTime now,
  }) {
    if (dueAt == null ||
        dueAt.isBefore(item.createdAt) ||
        item.createdAt.isAfter(now)) {
      return false;
    }
    if (item.status == LaundryStatus.deposited ||
        item.status == LaundryStatus.processing) {
      return now.isAfter(dueAt);
    }
    final events = history.toList();
    if (const TrackingService().processingDuration(item, events, now: now) ==
        null) {
      return false;
    }
    final ready =
        events
            .where((e) => e.newStatus == LaundryStatus.ready)
            .map((e) => e.changedAt)
            .toList()
          ..sort();
    return ready.isNotEmpty && ready.last.isAfter(dueAt);
  }
}
