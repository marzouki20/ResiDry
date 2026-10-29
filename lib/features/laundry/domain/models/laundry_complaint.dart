import 'dart:typed_data';

enum ComplaintReason { damaged, missing, poorCleaning, treatmentDelay, other }

enum ComplaintStatus { submitted, reviewing, resolved, rejected }

class LaundryComplaint {
  const LaundryComplaint({
    required this.id,
    required this.laundryId,
    required this.residentId,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    required this.residentSeenRevision,
    this.lineId,
    this.garmentSnapshot,
    this.decisionReason,
  });
  final String id, laundryId, description;
  final int residentId, revision, residentSeenRevision;
  final String? lineId, garmentSnapshot, decisionReason;
  final ComplaintReason reason;
  final ComplaintStatus status;
  final DateTime createdAt, updatedAt;
  bool get hasUnreadResponse => residentSeenRevision < revision;
}

class ComplaintEvent {
  const ComplaintEvent({
    required this.id,
    required this.newStatus,
    required this.actorId,
    required this.note,
    required this.createdAt,
    this.oldStatus,
  });
  final int id, actorId;
  final ComplaintStatus? oldStatus;
  final ComplaintStatus newStatus;
  final String note;
  final DateTime createdAt;
}

/// Immutable encoded image: no temporary file path and no user-account copy.
class ComplaintPhoto {
  ComplaintPhoto({required List<int> bytes, required this.mimeType})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final Uint8List bytes;
  final String mimeType;
}
