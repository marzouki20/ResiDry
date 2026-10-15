import 'laundry_item.dart';

class LaundryStatusChange {
  const LaundryStatusChange({
    required this.id,
    required this.laundryId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedByUserId,
    required this.changedAt,
  });

  final int id;
  final String laundryId;
  final LaundryStatus? oldStatus;
  final LaundryStatus newStatus;
  final int? changedByUserId;
  final DateTime changedAt;

  factory LaundryStatusChange.fromMap(Map<String, Object?> map) =>
      LaundryStatusChange(
        id: map['id'] as int,
        laundryId: map['laundry_id'] as String,
        oldStatus: map['old_status'] == null
            ? null
            : LaundryStatus.values.byName(map['old_status'] as String),
        newStatus: LaundryStatus.values.byName(map['new_status'] as String),
        changedByUserId: map['changed_by_user_id'] as int?,
        changedAt: DateTime.parse(map['changed_at'] as String),
      );
}
