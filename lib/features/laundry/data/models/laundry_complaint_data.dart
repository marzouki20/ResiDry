import '../../../../models/laundry_role.dart';
import '../../domain/models/laundry_complaint.dart';

LaundryComplaint readComplaint(Map<String, Object?> row) => LaundryComplaint(
  id: row['id'] as String,
  laundryId: row['laundry_id'] as String,
  residentId: row['resident_id'] as int,
  lineId: row['line_id'] as String?,
  garmentSnapshot: row['garment_snapshot'] as String?,
  reason: ComplaintReason.values.byName(row['reason'] as String),
  description: row['description'] as String,
  status: ComplaintStatus.values.byName(row['status'] as String),
  decisionReason: row['decision_reason'] as String?,
  createdAt: DateTime.parse(row['created_at'] as String),
  updatedAt: DateTime.parse(row['updated_at'] as String),
  revision: row['revision'] as int,
  residentSeenRevision: row['resident_seen_revision'] as int,
);

class ComplaintInbox {
  ComplaintInbox({
    required this.role,
    required Iterable<LaundryComplaint> complaints,
    required Map<int, String> names,
  }) : complaints = List.unmodifiable(complaints),
       names = Map.unmodifiable(names);
  final LaundryRole role;
  final List<LaundryComplaint> complaints;
  final Map<int, String> names;
  int get unreadCount => complaints
      .where(
        (c) => role == LaundryRole.resident
            ? c.hasUnreadResponse
            : c.status == ComplaintStatus.submitted,
      )
      .length;
}

class ComplaintDetails {
  ComplaintDetails({
    required this.complaint,
    required this.role,
    required Iterable<ComplaintEvent> events,
    required Iterable<ComplaintPhoto> photos,
    required Map<int, String> names,
  }) : events = List.unmodifiable(events),
       photos = List.unmodifiable(photos),
       names = Map.unmodifiable(names);
  final LaundryComplaint complaint;
  final LaundryRole role;
  final List<ComplaintEvent> events;
  final List<ComplaintPhoto> photos;
  final Map<int, String> names;
}
