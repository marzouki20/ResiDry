import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/models/user.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin;
  final now = DateTime.utc(2026, 10, 24, 12);
  LaundryItem request(
    String id, {
    int resident = 1,
    LaundryStatus status = LaundryStatus.deposited,
    bool confirmed = true,
    double price = 15,
    String service = 'Lavage',
    int ageDays = 1,
  }) => LaundryItem(
    id: id,
    residentId: resident,
    residentName: 'Untrusted name',
    serviceType: service,
    status: status,
    price: price,
    priceConfirmed: confirmed,
    createdAt: now.subtract(Duration(days: ageDays)),
  );
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
  });
  tearDown(() async => db.close());

  test('advanced schema exists but seeds no tariffs or measurements', () async {
    final columns = (await db.rawQuery('PRAGMA table_info(laundry_items)'))
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['treatment_due_at', 'urgency', 'revision']));
    expect(await db.query('laundry_pricing_rules'), isEmpty);
    expect(await db.query('laundry_request_lines'), isEmpty);
    expect((await db.query('laundry_service_types')).length, 3);
  });
  test(
    'empty database produces empty statistics, not a sample average',
    () async {
      final report = await admin.getReport(evaluatedAt: now);
      expect(report.statistics.totalRequests, 0);
      expect(report.statistics.averageProcessingTime, isNull);
      expect(report.statistics.popularServices, isEmpty);
      expect(report.priorities, isEmpty);
    },
  );
  test(
    'report uses real scoped requests and resolves current central names',
    () async {
      await admin.add(request('OWN'));
      await admin.add(request('OTHER', resident: 2));
      await db.update(
        'users',
        {'name': 'Updated account'},
        where: 'id = ?',
        whereArgs: [1],
      );
      final report = await admin
          .forUser(testResident)
          .getReport(evaluatedAt: now);
      expect(report.workloads.map((w) => w.item.id), ['OWN']);
      expect(report.workloads.single.item.residentName, 'Updated account');
      expect(report.workloads.single.item.priceConfirmed, isFalse);
      expect(report.workloads.single.item.price, 0);
      expect(report.statistics.confirmedDeliveredValueMillimes, isNull);
      expect(report.history.keys, ['OWN']);
    },
  );
  test(
    'priorities come from saved creation dates; delays remain unknown',
    () async {
      await admin.add(request('RECENT', ageDays: 1));
      await admin.add(request('OLDER', ageDays: 3));
      await admin.add(
        request('READY', ageDays: 5, status: LaundryStatus.ready),
      );
      final report = await admin
          .forUser(testPressing)
          .getReport(evaluatedAt: now);
      expect(report.priorities.map((p) => p.workload.item.id), [
        'OLDER',
        'RECENT',
      ]);
      expect(report.priorities.every((p) => p.timing.isAtRisk == null), isTrue);
      expect(report.statistics.missingDeadlineRequests, 2);
      expect(report.statistics.missingEstimateRequests, 2);
      expect(report.statistics.averageProcessingTime, isNull);
      expect(report.statistics.unmeasuredCompletedRequests, 1);
    },
  );
  test('financial total includes only delivered confirmed value', () async {
    await admin.add(
      request('CONFIRMED', status: LaundryStatus.delivered, price: 15.125),
    );
    await admin.add(
      request(
        'UNCONFIRMED',
        status: LaundryStatus.delivered,
        confirmed: false,
        price: 999,
      ),
    );
    await admin.add(request('NOTDELIVERED', price: 500));
    final report = await admin.getReport(evaluatedAt: now);
    expect(report.statistics.confirmedDeliveredValueMillimes, 15125);
    expect(report.statistics.unconfirmedDeliveredRequests, 1);
    expect(report.statistics.popularServices.single.requests, 3);
    for (final user in [testDriver, testPressing, testResident]) {
      expect(
        (await admin.forUser(user).getReport(evaluatedAt: now))
            .statistics
            .confirmedDeliveredValueMillimes,
        isNull,
      );
    }
    final driver = await admin.forUser(testDriver).getReport(evaluatedAt: now);
    expect(
      driver.workloads.map((w) => w.item.id),
      isNot(contains('NOTDELIVERED')),
    );
    expect(
      driver.workloads.every(
        (w) => w.item.price == 0 && !w.item.priceConfirmed,
      ),
      isTrue,
    );
  });
  test('average uses coherent SQLite histories and excludes incomplete legacy history', () async {
    await admin.add(request('MEASURED', status: LaundryStatus.delivered));
    await admin.add(request('LEGACY', status: LaundryStatus.ready));
    await db.delete(
      'laundry_status_history',
      where: 'laundry_id = ?',
      whereArgs: ['MEASURED'],
    );
    for (var index = 0; index < LaundryStatus.values.length; index++) {
      await db.insert('laundry_status_history', {
        'laundry_id': 'MEASURED',
        'old_status': index == 0 ? null : LaundryStatus.values[index - 1].name,
        'new_status': LaundryStatus.values[index].name,
        'changed_by_user_id': index == 3 ? testDriver.id : testPressing.id,
        'changed_at': now
            .subtract(Duration(hours: 4 - index))
            .toIso8601String(),
      });
    }
    final report = await admin.getReport(evaluatedAt: now);
    expect(report.statistics.averageProcessingTime, const Duration(hours: 1));
    expect(report.statistics.measurableProcessingRequests, 1);
    expect(report.statistics.unmeasuredCompletedRequests, 1);
  });
  test('real workflow immediately updates report and preserves authenticated authors', () async {
    await admin.add(request('FLOW'));
    final pressing = admin.forUser(testPressing);
    final driver = admin.forUser(testDriver);
    await pressing.transitionStatus(
      'FLOW',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    await pressing.transitionStatus(
      'FLOW',
      expectedStatus: LaundryStatus.processing,
      newStatus: LaundryStatus.ready,
    );
    expect((await pressing.getReport()).statistics.awaitingDeliveryRequests, 1);
    await driver.transitionStatus(
      'FLOW',
      expectedStatus: LaundryStatus.ready,
      newStatus: LaundryStatus.delivered,
    );
    final report = await admin.getReport();
    expect(report.statistics.deliveredRequests, 1);
    expect(report.statistics.awaitingDeliveryRequests, 0);
    expect(report.priorities, isEmpty);
    expect(report.history['FLOW']!.map((h) => h.changedByUserId), [9, 7, 7, 8]);
    expect(report.statistics.measurableProcessingRequests, 1);
  });
  test('report revalidates authentication and stored roles', () async {
    final forged = User(
      id: testResident.id,
      name: 'Fake',
      email: '',
      password: '',
      role: testAdmin.role,
    );
    final report = await admin.forUser(forged).getReport(evaluatedAt: now);
    expect(report.statistics.confirmedDeliveredValueMillimes, isNull);
    await db.update(
      'users',
      {'role': 'unknown'},
      where: 'id = ?',
      whereArgs: [testResident.id],
    );
    await expectLater(
      admin.forUser(forged).getReport(),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      admin.forUser(testUnknown).getReport(),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      LaundryRepository(databaseProvider: () async => db).getReport(),
      throwsA(isA<LaundryException>()),
    );
  });
}
