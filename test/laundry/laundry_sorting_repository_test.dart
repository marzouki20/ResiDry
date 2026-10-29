import 'package:flutter_test/flutter_test.dart';

import 'support/laundry_rows.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_sorting.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin, pressing;
  final now = DateTime.utc(2026, 10, 28, 12);
  const care = LaundrySortingProfile(
    color: LaundryColorFamily.white,
    fabric: LaundryFabric.cotton,
    cycle: LaundryWashCycle.normal,
    maxTemperatureC: 40,
    dyeTransferRisk: LaundryDyeTransferRisk.low,
    washSeparately: false,
    verifiedByUserId: 999999,
  );
  LaundryDetails draft({int revision = 0, int quantity = 2}) => LaundryDetails(
    item: LaundryItem(
      id: 'R1',
      residentId: 1,
      residentName: '',
      serviceType: '',
      status: LaundryStatus.deposited,
      price: 0,
    ),
    revision: revision,
    lines: [
      LaundryLine(
        id: 'L1',
        garment: 'Chemise',
        serviceId: 'washing',
        quantity: quantity,
      ),
      const LaundryLine(
        id: 'L2',
        garment: 'Drap',
        serviceId: 'washing',
        quantity: 1,
      ),
    ],
  );
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
      clock: () => now,
    );
    pressing = admin.forUser(testPressing);
    await admin.forUser(testResident).saveRequest(draft());
  });
  tearDown(() async => db.close());
  Future<void> verify(
    String line, {
    LaundrySortingProfile profile = care,
  }) async {
    final data = await pressing.getSortingData();
    await pressing.saveSortingProfile(
      requestId: 'R1',
      lineId: line,
      expectedRevision: data.revisions['R1']!,
      profile: profile,
    );
  }

  test('legacy lots require review; verified stored lots produce a traceable group', () async {
    expect((await pressing.getSortingData()).plan.groups, isEmpty);
    expect((await pressing.getSortingData()).plan.reviews.length, 2);
    final before = await admin.getDetails('R1');
    await verify('L1');
    await verify('L2');
    final data = await pressing.getSortingData();
    expect(data.plan.reviews, isEmpty);
    expect(data.plan.groups.single.lots.map((l) => l.lineId), ['L1', 'L2']);
    expect(data.plan.groups.single.quantity, 3);
    expect(
      data.lots.every((l) => l.profile!.verifiedByUserId == testPressing.id),
      isTrue,
    );
    expect(data.lots.every((l) => l.profile!.verifiedAt == now), isTrue);
    final after = await admin.getDetails('R1');
    expect(after.item.price, before.item.price);
    expect(after.item.status, before.item.status);
    expect(after.history.length, before.history.length);
    expect(after.revision, before.revision + 2);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test(
    'resident driver unknown and missing accounts cannot read or write sorting',
    () async {
      for (final user in [testResident, testDriver, testUnknown, null]) {
        final repo = LaundryRepository(
          currentUser: user,
          databaseProvider: () async => db,
        );
        await expectLater(
          repo.getSortingData(),
          throwsA(isA<LaundryException>()),
        );
        await expectLater(
          repo.saveSortingProfile(
            requestId: 'R1',
            lineId: 'L1',
            expectedRevision: 1,
            profile: care,
          ),
          throwsA(isA<LaundryException>()),
        );
      }
      expect(
        (await pressing.getSortingData()).lots.every(
          (l) => l.profile!.verifiedAt == null,
        ),
        isTrue,
      );
    },
  );

  test('stale revision missing lot and invalid temperature leave records untouched', () async {
    final before = await db.query('laundry_items');
    for (final attempt in [
      () => pressing.saveSortingProfile(
        requestId: 'R1',
        lineId: 'L1',
        expectedRevision: 0,
        profile: care,
      ),
      () => pressing.saveSortingProfile(
        requestId: 'R1',
        lineId: 'OTHER',
        expectedRevision: 1,
        profile: care,
      ),
      () => pressing.saveSortingProfile(
        requestId: 'R1',
        lineId: 'L1',
        expectedRevision: 1,
        profile: const LaundrySortingProfile(maxTemperatureC: -5),
      ),
    ]) {
      await expectLater(attempt(), throwsA(isA<LaundryException>()));
      expect(await db.query('laundry_items'), before);
    }
  });

  test('starting treatment revokes sorting edits and removes its lots from pending plan', () async {
    await verify('L1');
    final data = await pressing.getSortingData();
    await pressing.transitionStatus(
      'R1',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    await expectLater(
      pressing.saveSortingProfile(
        requestId: 'R1',
        lineId: 'L2',
        expectedRevision: data.revisions['R1']!,
        profile: care,
      ),
      throwsA(isA<LaundryException>()),
    );
    expect((await pressing.getSortingData()).lots, isEmpty);
    expect(
      (await readLaundryRows(
        db,
        'laundry_request_lines',
      )).singleWhere((r) => r['id'] == 'L1')['sorting_verified_by_user_id'],
      7,
    );
  });

  test('unchanged article preserves verification; changed quantity requires checking again', () async {
    await verify('L1');
    var details = await admin.getDetails('R1');
    await admin
        .forUser(testResident)
        .saveRequest(draft(revision: details.revision));
    var data = await pressing.getSortingData();
    expect(data.lots.first.profile!.verifiedByUserId, 7);
    details = await admin.getDetails('R1');
    await admin
        .forUser(testResident)
        .saveRequest(draft(revision: details.revision, quantity: 3));
    data = await pressing.getSortingData();
    expect(data.lots.first.profile!.verifiedByUserId, isNull);
    expect(data.lots.first.profile!.color, isNull);
    expect(data.plan.groups, isEmpty);
  });

  test(
    'unknown observations never become compatible through verification alone',
    () async {
      await verify('L1', profile: const LaundrySortingProfile());
      final data = await pressing.getSortingData();
      expect(data.plan.groups, isEmpty);
      expect(data.plan.reviews.length, 2);
      expect(data.lots.first.profile!.verifiedByUserId, 7);
    },
  );

  test('existing central role changes revoke access immediately', () async {
    await db.update(
      'users',
      {'role': 'Résident'},
      where: 'id = ?',
      whereArgs: [7],
    );
    await expectLater(
      pressing.getSortingData(),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(verify('L1'), throwsA(isA<LaundryException>()));
  });

  test(
    'failed care write rolls back the request revision and all observations',
    () async {
      final before = await db.query('laundry_items');
      await db.execute(
        "CREATE TRIGGER fail_care BEFORE UPDATE OF lines_json ON laundry_items BEGIN SELECT RAISE(ABORT, 'test-only failure'); END",
      );
      await expectLater(verify('L1'), throwsA(isA<DatabaseException>()));
      expect(await db.query('laundry_items'), before);
      expect(
        (await pressing.getSortingData()).lots.first.profile!.verifiedAt,
        isNull,
      );
    },
  );
}
