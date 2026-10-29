import 'support/laundry_rows.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_quote.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_workload.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin, resident, pressing, driver;
  late DateTime now;
  LaundryDetails draft({
    String id = 'LD1',
    int user = 1,
    DateTime? due,
    LaundryUrgency urgency = LaundryUrgency.normal,
    int revision = 0,
    LaundryStatus status = LaundryStatus.deposited,
    List<LaundryLine>? lines,
  }) => LaundryDetails(
    item: LaundryItem(
      id: id,
      residentId: user,
      residentName: 'Untrusted name',
      serviceType: 'Untrusted service',
      status: status,
      price: 1,
      priceConfirmed: true,
    ),
    lines:
        lines ??
        [
          const LaundryLine(
            id: 'LINE1',
            garment: 'Chemise',
            serviceId: 'washing',
            quantity: 3,
            weightGrams: 3000,
            totalMillimes: 1,
            tariffId: 'forged',
          ),
        ],
    dueAt: due,
    urgency: urgency,
    revision: revision,
  );
  setUp(() async {
    now = DateTime.utc(2026, 10, 24, 10);
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
      clock: () => now,
    );
    resident = admin.forUser(testResident);
    pressing = admin.forUser(testPressing);
    driver = admin.forUser(testDriver);
    await admin.saveTariff(
      serviceId: 'washing',
      basis: LaundryPricingBasis.perKilogram,
      unitPriceMillimes: 5000,
      estimatedMinutes: 90,
    );
  });
  tearDown(() async {
    if (db.isOpen) await db.close();
  });
  test(
    'resident CRUD computes 3kg x 5DT, validates ownership and redacts prices',
    () async {
      await resident.saveRequest(draft());
      final saved = await admin.getDetails('LD1');
      expect(saved.item.price, 15);
      expect(saved.item.priceConfirmed, isTrue);
      expect(saved.item.residentName, 'Ahmed');
      expect(saved.lines.single.totalMillimes, 15000);
      expect(saved.lines.single.tariffId, isNot('forged'));
      expect(
        (await resident.getDetails('LD1')).lines.single.totalMillimes,
        isNull,
      );
      expect((await resident.getDetails('LD1')).item.price, 0);
      expect((await admin.getStatusHistory('LD1')).single.changedByUserId, 1);
      await expectLater(
        admin.forUser(testOtherResident).getDetails('LD1'),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        admin
            .forUser(testOtherResident)
            .saveRequest(draft(revision: saved.revision)),
        throwsA(isA<LaundryException>()),
      );
      await resident.saveRequest(
        draft(
          revision: saved.revision,
          lines: [
            const LaundryLine(
              id: 'LINE1',
              garment: 'Chemise',
              serviceId: 'washing',
              quantity: 3,
              weightGrams: 2000,
            ),
          ],
        ),
      );
      expect((await admin.getDetails('LD1')).item.price, 10);
      await resident.deleteForResident('LD1', residentId: 1);
      expect(await readLaundryRows(db, 'laundry_request_lines'), isEmpty);
      expect(await readLaundryRows(db, 'laundry_status_history'), isEmpty);
      expect((await db.query('users')).length, testAccounts.length);
    },
  );
  test(
    'per-item tariff and multi-service total use integer millimes',
    () async {
      await admin.saveTariff(
        serviceId: 'ironing',
        basis: LaundryPricingBasis.perItem,
        unitPriceMillimes: 1250,
        estimatedMinutes: 20,
      );
      await admin.saveRequest(
        draft(
          lines: [
            const LaundryLine(
              id: 'WASH',
              garment: 'Drap',
              serviceId: 'washing',
              quantity: 1,
              weightGrams: 1500,
            ),
            const LaundryLine(
              id: 'IRON',
              garment: 'Chemise',
              serviceId: 'ironing',
              quantity: 3,
              basis: LaundryPricingBasis.perItem,
            ),
          ],
        ),
      );
      final details = await admin.getDetails('LD1');
      expect(details.item.price, 11.25);
      expect(details.estimatedMinutes, 110);
      final popular = (await admin.getReport()).statistics.popularServices;
      expect(popular.map((s) => s.serviceCode).toSet(), {
        'Lavage',
        'Repassage',
      });
    },
  );
  test(
    'missing weight or tariff remains unconfirmed, never a fake free quote',
    () async {
      await resident.saveRequest(
        draft(
          lines: [
            const LaundryLine(
              id: 'L',
              garment: 'Chemise',
              serviceId: 'washing',
              quantity: 3,
            ),
          ],
        ),
      );
      expect((await admin.getDetails('LD1')).item.priceConfirmed, isFalse);
      expect(
        (await admin.getDetails('LD1')).lines.single.totalMillimes,
        isNull,
      );
      expect((await admin.getDetails('LD1')).estimatedMinutes, 90);
      await resident.saveRequest(
        draft(
          id: 'LD2',
          lines: [
            const LaundryLine(
              id: 'DRY',
              garment: 'Veste',
              serviceId: 'dry_cleaning',
              quantity: 1,
              basis: LaundryPricingBasis.perItem,
            ),
          ],
        ),
      );
      expect((await admin.getDetails('LD2')).item.priceConfirmed, isFalse);
      expect((await admin.getDetails('LD2')).estimatedMinutes, isNull);
    },
  );
  test('new tariffs preserve saved quote snapshots until explicit editable recalculation', () async {
    await resident.saveRequest(draft());
    final old = await admin.getDetails('LD1');
    now = now.add(const Duration(seconds: 1));
    await admin.saveTariff(
      serviceId: 'washing',
      basis: LaundryPricingBasis.perKilogram,
      unitPriceMillimes: 6000,
      estimatedMinutes: 100,
    );
    expect((await admin.getDetails('LD1')).item.price, 15);
    final rates = await admin.getTariffs();
    expect(rates.where((t) => t.rate.appliesAt(now)).length, 1);
    expect(rates.length, 2);
    await resident.saveRequest(draft(revision: old.revision));
    expect((await admin.getDetails('LD1')).item.price, 18);
    expect((await admin.getDetails('LD1')).estimatedMinutes, 100);
  });
  test(
    'pressing and driver transitions preserve snapshots and use actual authors',
    () async {
      await resident.saveRequest(draft(due: now.add(const Duration(hours: 4))));
      final stale = await admin.getDetails('LD1');
      await pressing.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
      );
      await expectLater(
        resident.saveRequest(draft(revision: stale.revision)),
        throwsA(isA<LaundryException>()),
      );
      final processing = await admin.getDetails('LD1');
      await expectLater(
        admin.saveRequest(
          draft(
            revision: processing.revision,
            status: LaundryStatus.processing,
            lines: [
              const LaundryLine(
                id: 'LINE1',
                garment: 'Changed',
                serviceId: 'washing',
                quantity: 3,
                weightGrams: 2000,
              ),
            ],
          ),
        ),
        throwsA(isA<LaundryException>()),
      );
      now = now.add(const Duration(minutes: 45));
      await pressing.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.processing,
        newStatus: LaundryStatus.ready,
      );
      await expectLater(
        driver.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.ready,
          newStatus: LaundryStatus.processing,
        ),
        throwsA(isA<LaundryException>()),
      );
      await driver.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.ready,
        newStatus: LaundryStatus.delivered,
      );
      final report = await admin.getReport();
      expect(
        report.statistics.averageProcessingTime,
        const Duration(minutes: 45),
      );
      expect(report.statistics.confirmedDeliveredValueMillimes, 15000);
      expect(report.history['LD1']!.map((e) => e.changedByUserId), [
        1,
        7,
        7,
        8,
      ]);
    },
  );
  test('priorities and delays use persisted deadlines, urgency and configured durations', () async {
    await resident.saveRequest(
      draft(id: 'LATE', due: now.add(const Duration(minutes: 5))),
    );
    await resident.saveRequest(
      draft(
        id: 'RISK',
        due: now.add(const Duration(minutes: 60)),
        lines: [
          const LaundryLine(
            id: 'R',
            garment: 'Drap',
            serviceId: 'washing',
            quantity: 1,
            weightGrams: 1000,
          ),
        ],
      ),
    );
    await resident.saveRequest(
      draft(
        id: 'SAFE',
        due: now.add(const Duration(hours: 5)),
        urgency: LaundryUrgency.urgent,
        lines: [
          const LaundryLine(
            id: 'S',
            garment: 'Drap',
            serviceId: 'washing',
            quantity: 1,
            weightGrams: 1000,
          ),
        ],
      ),
    );
    now = now.add(const Duration(minutes: 10));
    final report = await pressing.getReport();
    expect(report.priorities.map((p) => p.workload.item.id), [
      'LATE',
      'RISK',
      'SAFE',
    ]);
    expect(report.statistics.overdueTreatmentRequests, 1);
    expect(report.statistics.atRiskTreatmentRequests, 1);
    expect(report.statistics.missingDeadlineRequests, 0);
    await pressing.transitionStatus(
      'LATE',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    await pressing.transitionStatus(
      'LATE',
      expectedStatus: LaundryStatus.processing,
      newStatus: LaundryStatus.ready,
    );
    expect((await pressing.getReport()).statistics.overdueTreatmentRequests, 0);
  });
  test('elapsed processing reduces remaining time, exceeded estimates become unknown', () async {
    await resident.saveRequest(draft(due: now.add(const Duration(hours: 3))));
    await pressing.transitionStatus(
      'LD1',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    now = now.add(const Duration(minutes: 30));
    expect(
      (await admin.getReport()).workloads.single.estimatedRemainingTreatment,
      const Duration(minutes: 60),
    );
    now = now.add(const Duration(minutes: 61));
    expect(
      (await admin.getReport()).workloads.single.estimatedRemainingTreatment,
      isNull,
    );
  });
  test('role validation rejects unknown accounts, driver writes, arbitrary owners and tariffs', () async {
    for (final repository in [driver, pressing, admin.forUser(testUnknown)]) {
      await expectLater(
        repository.saveRequest(draft()),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        repository.saveTariff(
          serviceId: 'washing',
          basis: LaundryPricingBasis.perKilogram,
          unitPriceMillimes: 1,
        ),
        throwsA(isA<LaundryException>()),
      );
    }
    await expectLater(
      admin.saveRequest(draft(user: 999)),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      admin.saveRequest(draft(user: testDriver.id!)),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      resident.saveRequest(draft(user: 2)),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(resident.getTariffs(), throwsA(isA<LaundryException>()));
    expect(await db.query('laundry_items'), isEmpty);
  });
  test('admin preserves unassigned historical ownership and price when updating its status', () async {
    await db.insert('laundry_items', {
      'id': 'LEGACY',
      'resident_id': null,
      'resident_name': 'Historical name',
      'service_type': 'Historical service',
      'status': 'ready',
      'price': 17.125,
      'price_confirmed': 1,
      'created_at': '2026-10-01T00:00:00.000Z',
    });
    await admin.saveRequest(
      LaundryDetails(
        item: LaundryItem(
          id: 'LEGACY',
          residentName: 'Untrusted',
          serviceType: 'Untrusted',
          status: LaundryStatus.delivered,
          price: 0,
        ),
      ),
    );
    final details = await admin.getDetails('LEGACY');
    expect(details.item.residentId, isNull);
    expect(details.item.residentNameSnapshot, 'Historical name');
    expect(details.item.price, 17.125);
    expect(details.lines, isEmpty);
    expect((await resident.getReport()).workloads, isEmpty);
  });
  test('invalid deadlines and quantities roll back without partially saved history', () async {
    await expectLater(
      resident.saveRequest(
        draft(due: now.subtract(const Duration(seconds: 1))),
      ),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      resident.saveRequest(
        draft(
          lines: [
            const LaundryLine(
              id: 'X',
              garment: 'Chemise',
              serviceId: 'washing',
              quantity: 0,
            ),
          ],
        ),
      ),
      throwsA(isA<LaundryException>()),
    );
    expect(await db.query('laundry_items'), isEmpty);
    expect(await readLaundryRows(db, 'laundry_status_history'), isEmpty);
  });
  test(
    'duplicate line from another request rolls back the complete operation',
    () async {
      await resident.saveRequest(draft());
      await expectLater(
        resident.saveRequest(draft(id: 'LD2')),
        throwsA(isA<LaundryException>()),
      );
      expect(await admin.getById('LD2'), isNull);
      expect((await admin.getDetails('LD1')).lines.single.totalMillimes, 15000);
      expect((await readLaundryRows(db, 'laundry_status_history')).length, 1);
    },
  );
  test(
    'optimistic revision prevents overwriting a concurrently saved request',
    () async {
      await resident.saveRequest(draft());
      final current = await resident.getDetails('LD1');
      await resident.saveRequest(
        draft(revision: current.revision, urgency: LaundryUrgency.urgent),
      );
      await expectLater(
        resident.saveRequest(draft(revision: current.revision)),
        throwsA(isA<LaundryException>()),
      );
      expect((await admin.getDetails('LD1')).urgency, LaundryUrgency.urgent);
    },
  );
  test(
    'preview is read-only and canonical; resident output contains no prices',
    () async {
      final preview = await admin.previewRequest(draft());
      expect(preview.item.price, 15);
      expect(preview.lines.single.totalMillimes, 15000);
      expect(
        (await resident.previewRequest(draft())).lines.single.totalMillimes,
        isNull,
      );
      expect(await db.query('laundry_items'), isEmpty);
    },
  );
  test('file-backed SQLite retains lines, prices and planning metadata after reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'residry-laundry-persistence-',
    );
    final path = '${directory.path}/residry.db';
    try {
      await resident.saveRequest(
        draft(
          due: now.add(const Duration(hours: 3)),
          urgency: LaundryUrgency.urgent,
        ),
      );
      await db.execute('VACUUM INTO ?', [path]);
      await db.close();
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
        ),
      );
      final report = await admin.getReport();
      expect(report.details['LD1']!.lines.single.totalMillimes, 15000);
      expect(report.details['LD1']!.urgency, LaundryUrgency.urgent);
      expect(report.details['LD1']!.dueAt, now.add(const Duration(hours: 3)));
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await db.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
