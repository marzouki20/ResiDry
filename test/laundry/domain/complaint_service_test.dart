import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_complaint.dart';
import 'package:ttttttteee/features/laundry/domain/services/complaint_service.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/models/laundry_status_change.dart';

void main() {
  const policy = ComplaintService();
  final now = DateTime.utc(2026, 10, 28, 12);
  LaundryItem item(LaundryStatus status) => LaundryItem(
    id: 'R',
    residentName: '',
    serviceType: 'Lavage',
    status: status,
    price: 0,
    createdAt: now.subtract(const Duration(hours: 4)),
  );
  test('only review then reasoned terminal decisions are allowed', () {
    for (final from in ComplaintStatus.values) {
      for (final to in ComplaintStatus.values) {
        expect(
          policy.allows(from, to),
          from == ComplaintStatus.submitted &&
                  to == ComplaintStatus.reviewing ||
              from == ComplaintStatus.reviewing &&
                  [
                    ComplaintStatus.resolved,
                    ComplaintStatus.rejected,
                  ].contains(to),
        );
      }
    }
  });
  test(
    'text validation handles whitespace boundaries and Arabic descriptions',
    () {
      for (final value in ['', '    ', 'a' * 9, 'a' * 2001, '😀' * 5]) {
        expect(policy.validText(value), isFalse);
      }
      for (final value in [
        'a' * 10,
        'a' * 2000,
        '😀' * 10,
        'وجدت قميصًا تالفًا بعد استلام الغسيل',
      ]) {
        expect(policy.validText(value), isTrue);
      }
    },
  );
  test(
    'only an exceeded known deadline establishes a pending treatment delay',
    () {
      for (final status in [
        LaundryStatus.deposited,
        LaundryStatus.processing,
      ]) {
        expect(
          policy.confirmedTreatmentDelay(
            item: item(status),
            dueAt: null,
            history: [],
            now: now,
          ),
          isFalse,
        );
        expect(
          policy.confirmedTreatmentDelay(
            item: item(status),
            dueAt: now,
            history: [],
            now: now,
          ),
          isFalse,
        );
        expect(
          policy.confirmedTreatmentDelay(
            item: item(status),
            dueAt: now.subtract(const Duration(minutes: 1)),
            history: [],
            now: now,
          ),
          isTrue,
        );
      }
    },
  );
  test('completed delay requires coherent history and a late ready event', () {
    final history = [
      LaundryStatusChange(
        id: 1,
        changedByUserId: 1,
        laundryId: 'R',
        oldStatus: null,
        newStatus: LaundryStatus.deposited,
        changedAt: now.subtract(const Duration(hours: 4)),
      ),
      LaundryStatusChange(
        id: 2,
        changedByUserId: 7,
        laundryId: 'R',
        oldStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
        changedAt: now.subtract(const Duration(hours: 3)),
      ),
      LaundryStatusChange(
        id: 3,
        changedByUserId: 7,
        laundryId: 'R',
        oldStatus: LaundryStatus.processing,
        newStatus: LaundryStatus.ready,
        changedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
    expect(
      policy.confirmedTreatmentDelay(
        item: item(LaundryStatus.ready),
        dueAt: now.subtract(const Duration(hours: 2)),
        history: history,
        now: now,
      ),
      isTrue,
    );
    expect(
      policy.confirmedTreatmentDelay(
        item: item(LaundryStatus.ready),
        dueAt: now.subtract(const Duration(minutes: 30)),
        history: history,
        now: now,
      ),
      isFalse,
    );
    expect(
      policy.confirmedTreatmentDelay(
        item: item(LaundryStatus.ready),
        dueAt: now.subtract(const Duration(hours: 2)),
        history: [],
        now: now,
      ),
      isFalse,
    );
  });
}
