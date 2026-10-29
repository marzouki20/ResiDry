import 'support/laundry_rows.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/models/laundry_role.dart';
import 'package:ttttttteee/models/user.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_user_directory.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

LaundryItem request({
  String id = 'LD1',
  int? residentId = 1,
  LaundryStatus status = LaundryStatus.deposited,
  double price = 15,
}) => LaundryItem(
  id: id,
  residentId: residentId,
  residentName: 'Untrusted name',
  serviceType: 'Lavage',
  status: status,
  price: price,
);

void main() {
  late Database db;
  late LaundryRepository admin;
  late LaundryRepository resident;
  late LaundryRepository pressing;
  late LaundryRepository driver;
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
    resident = admin.forUser(testResident);
    pressing = admin.forUser(testPressing);
    driver = admin.forUser(testDriver);
  });
  tearDown(() async => db.close());

  test('uses exact stored roles and rejects unknown labels', () {
    expect(laundryRoleFromUserRole('Résident'), LaundryRole.resident);
    expect(laundryRoleFromUserRole('Livreur'), LaundryRole.driver);
    expect(laundryRoleFromUserRole('Société de lavage'), LaundryRole.pressing);
    expect(laundryRoleFromUserRole('Administrateur'), LaundryRole.admin);
    expect(laundryRoleFromUserRole('Société de pressing'), isNull);
    expect(laundryRoleFromUserRole('admin'), isNull);
  });
  test(
    'reads existing central users and resident selector excludes staff',
    () async {
      final directory = LaundryUserDirectory(databaseProvider: () async => db);
      expect((await directory.getUserById(1))!.name, 'Ahmed');
      expect(await directory.getUserById(123456), isNull);
      expect((await admin.getResidents()).map((u) => u.id), [1, 2]);
      expect(await admin.getAll(), isEmpty);
      await expectLater(
        resident.getResidents(),
        throwsA(isA<LaundryException>()),
      );
    },
  );
  test('all entry points require an authenticated account', () async {
    final anonymous = LaundryRepository(databaseProvider: () async => db);
    for (final action in <Future<Object?> Function()>[
      anonymous.getAll,
      () => anonymous.getById('LD1'),
      () => anonymous.add(request()),
      () => anonymous.getByResidentId(1),
      () => anonymous.delete('LD1'),
      () => anonymous.getStatusHistory('LD1'),
    ]) {
      await expectLater(action(), throwsA(isA<LaundryException>()));
    }
  });
  test(
    'rejects missing and unknown accounts and ignores a forged role',
    () async {
      for (final user in [
        const User(
          id: 1234,
          name: 'Fake',
          email: '',
          password: '',
          role: 'Administrateur',
        ),
        testUnknown,
      ]) {
        await expectLater(
          admin.forUser(user).getAll(),
          throwsA(isA<LaundryException>()),
        );
      }
      const forged = User(
        id: 1,
        name: 'Fake admin',
        email: '',
        password: '',
        role: 'Administrateur',
      );
      await expectLater(
        admin.forUser(forged).add(request()),
        throwsA(isA<LaundryException>()),
      );
    },
  );
  test(
    'admin requires a real resident account, never a profile ID or staff ID',
    () async {
      for (final id in [null, -1, 501, testDriver.id]) {
        await expectLater(
          admin.add(request(residentId: id)),
          throwsA(isA<LaundryException>()),
        );
      }
      expect(await admin.getAll(), isEmpty);
    },
  );
  test(
    'resident creation derives name, owner, zero quote and history author',
    () async {
      await resident.addForResident(
        request(price: 999).copyWith(priceConfirmed: true),
        residentId: 1,
      );
      final saved = (await admin.getById('LD1'))!;
      expect(saved.residentId, 1);
      expect(saved.residentName, 'Ahmed');
      expect(saved.price, 0);
      expect(saved.priceConfirmed, isFalse);
      expect((await admin.getStatusHistory('LD1')).single.changedByUserId, 1);
      expect(
        (await db.query('laundry_items')).single.keys,
        isNot(contains('password')),
      );
    },
  );
  test(
    'resident cannot create for another account or create a later status',
    () async {
      await expectLater(
        resident.addForResident(request(residentId: 2), residentId: 2),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        resident.addForResident(
          request(status: LaundryStatus.ready),
          residentId: 1,
        ),
        throwsA(isA<LaundryException>()),
      );
    },
  );
  test(
    'ownership applies to lists, single reads, history, edits and deletion',
    () async {
      await admin.add(request(residentId: 2));
      expect(await resident.getByResidentId(1), isEmpty);
      for (final action in <Future<Object?> Function()>[
        () => resident.getByResidentId(2),
        () => resident.getById('LD1'),
        () => resident.getStatusHistory('LD1'),
        () => resident.updateForResident(request(), residentId: 1),
        () => resident.deleteForResident('LD1', residentId: 1),
        resident.getAll,
      ]) {
        await expectLater(action(), throwsA(isA<LaundryException>()));
      }
    },
  );
  test('resident CRUD is persistent across repository instances and preserves staff quote', () async {
    await admin.add(request().copyWith(priceConfirmed: true));
    final another = LaundryRepository(
      currentUser: testResident,
      databaseProvider: () async => db,
    );
    expect((await another.getByResidentId(1)).single.price, 0);
    await another.updateForResident(
      request().copyWith(
        residentId: 2,
        residentName: 'Fake',
        serviceType: 'Repassage',
        status: LaundryStatus.delivered,
        price: -999,
      ),
      residentId: 1,
    );
    final saved = (await admin.getById('LD1'))!;
    expect(saved.serviceType, 'Repassage');
    expect(saved.residentId, 1);
    expect(saved.residentName, 'Ahmed');
    expect(saved.status, LaundryStatus.deposited);
    expect(saved.price, 15);
    expect(saved.priceConfirmed, isFalse);
    await another.deleteForResident('LD1', residentId: 1);
    expect(await admin.getAll(), isEmpty);
    expect(await readLaundryRows(db, 'laundry_status_history'), isEmpty);
  });
  test('complete workflow records real actors in order', () async {
    await resident.addForResident(request(), residentId: 1);
    await pressing.transitionStatus(
      'LD1',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    await pressing.transitionStatus(
      'LD1',
      expectedStatus: LaundryStatus.processing,
      newStatus: LaundryStatus.ready,
    );
    await driver.transitionStatus(
      'LD1',
      expectedStatus: LaundryStatus.ready,
      newStatus: LaundryStatus.delivered,
    );
    final history = await admin.getStatusHistory('LD1');
    expect(history.map((h) => h.changedByUserId), [1, 7, 7, 8]);
    expect(history.map((h) => h.newStatus), LaundryStatus.values);
    expect(history.first.oldStatus, isNull);
    expect((await admin.getById('LD1'))!.status, LaundryStatus.delivered);
  });
  test(
    'wrong roles, forged authors, skipped, backward and stale transitions fail',
    () async {
      await admin.add(request());
      await expectLater(
        driver.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
          role: LaundryRole.pressing,
        ),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        pressing.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
          changedByUserId: 8,
        ),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        resident.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
        ),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        pressing.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.ready,
        ),
        throwsA(isA<LaundryException>()),
      );
      await pressing.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
      );
      await expectLater(
        pressing.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
        ),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        pressing.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.processing,
          newStatus: LaundryStatus.deposited,
        ),
        throwsA(isA<LaundryException>()),
      );
      expect((await admin.getStatusHistory('LD1')).length, 2);
    },
  );
  test('pressing and driver cannot use administrator CRUD', () async {
    await admin.add(request());
    for (final staff in [pressing, driver, resident]) {
      await expectLater(
        staff.add(request(id: 'OTHER')),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        staff.update(request()),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(staff.delete('LD1'), throwsA(isA<LaundryException>()));
    }
    expect(await driver.getAll(), isEmpty);
    await expectLater(driver.getById('LD1'), throwsA(isA<LaundryException>()));
  });
  test(
    'stored role changes and deleted accounts revoke access immediately',
    () async {
      await admin.add(request());
      await db.update(
        'users',
        {'role': 'unknown'},
        where: 'id = ?',
        whereArgs: [7],
      );
      await expectLater(
        pressing.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
        ),
        throwsA(isA<LaundryException>()),
      );
      await db.delete('users', where: 'id = ?', whereArgs: [8]);
      await expectLater(driver.getAll(), throwsA(isA<LaundryException>()));
    },
  );
  test(
    'old resident form cannot edit or delete after pressing starts',
    () async {
      await admin.add(request());
      await pressing.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
      );
      await expectLater(
        resident.updateForResident(request(), residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        resident.deleteForResident('LD1', residentId: 1),
        throwsA(isA<LaundryException>()),
      );
    },
  );
  test(
    'live account names resolve without overwriting historical snapshots',
    () async {
      await admin.add(request());
      await db.update(
        'users',
        {'name': 'Ahmed Nouveau'},
        where: 'id = ?',
        whereArgs: [1],
      );
      final item = (await admin.getById('LD1'))!;
      expect(item.residentName, 'Ahmed Nouveau');
      expect(item.residentNameSnapshot, 'Ahmed');
      await admin.update(item.copyWith(serviceType: 'Repassage'));
      expect(
        (await db.query('laundry_items')).single['resident_name'],
        'Ahmed',
      );
      expect(
        (await resident.getByResidentId(1)).single.residentName,
        'Ahmed Nouveau',
      );
    },
  );
  test('admin can explicitly associate an unassigned legacy request', () async {
    await db.insert('laundry_items', request(residentId: null).toMap());
    expect(await resident.getByResidentId(1), isEmpty);
    await expectLater(
      resident.getStatusHistory('LD1'),
      throwsA(isA<LaundryException>()),
    );
    final legacy = (await admin.getById('LD1'))!;
    await admin.update(legacy.copyWith(residentId: 1));
    expect((await resident.getByResidentId(1)).single.residentName, 'Ahmed');
    expect(
      (await admin.getById('LD1'))!.residentNameSnapshot,
      'Untrusted name',
    );
  });
  test('history insertion failures roll back both creation and transition in real SQLite', () async {
    await admin.add(request());
    await db.execute(
      "CREATE TRIGGER reject_history BEFORE INSERT ON laundry_events WHEN NEW.event_type = 'laundry_status' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      admin.add(request(id: 'FAILED')),
      throwsA(isA<DatabaseException>()),
    );
    expect(await admin.getById('FAILED'), isNull);
    await expectLater(
      pressing.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect((await admin.getById('LD1'))!.status, LaundryStatus.deposited);
    expect((await admin.getStatusHistory('LD1')).length, 1);
  });
  test('admin CRUD preserves creation dates, records status author, validates prices and cascades history', () async {
    final item = request();
    await admin.add(item);
    await admin.update(
      item.copyWith(
        price: 0,
        priceConfirmed: true,
        status: LaundryStatus.ready,
      ),
    );
    final saved = (await admin.getById(item.id))!;
    expect(saved.createdAt, item.createdAt);
    expect(saved.priceConfirmed, isTrue);
    expect(saved.price, 0);
    expect((await admin.getStatusHistory(item.id)).last.changedByUserId, 9);
    for (final price in [-1.0, double.nan, double.infinity]) {
      await expectLater(
        admin.update(saved.copyWith(price: price)),
        throwsA(isA<LaundryException>()),
      );
    }
    await admin.delete(item.id);
    expect(await readLaundryRows(db, 'laundry_status_history'), isEmpty);
  });
  test(
    'same-database foreign keys protect users and reject missing references',
    () async {
      await admin.add(request());
      await expectLater(
        db.delete('users', where: 'id = ?', whereArgs: [1]),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert(
          'laundry_items',
          request(id: 'BAD', residentId: 8888).toMap(),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  for (final version in [1, 2, 3]) {
    test(
      'imports legacy v$version without guessing owners or authors and keeps archive unchanged',
      () async {
        databaseFactory = databaseFactoryFfi;
        final directory = await Directory.systemTemp.createTemp(
          'residry-legacy-test-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = paths.join(directory.path, 'laundry.db');
        final legacy = await databaseFactoryFfi.openDatabase(file);
        await legacy.execute(
          'CREATE TABLE laundry_items(id TEXT PRIMARY KEY,resident_id INTEGER,resident_name TEXT,service_type TEXT,status TEXT,price REAL,created_at TEXT${version >= 2 ? ',price_confirmed INTEGER' : ''}${version >= 3 ? ',resident_link_verified INTEGER' : ''})',
        );
        await legacy.execute(
          'CREATE TABLE laundry_status_history(id INTEGER PRIMARY KEY, laundry_id TEXT, old_status TEXT, new_status TEXT, changed_by_user_id INTEGER, changed_at TEXT${version >= 3 ? ',actor_verified INTEGER' : ''})',
        );
        await legacy.insert('laundry_items', {
          'id': 'OLD',
          'resident_id': 1,
          'resident_name': 'Someone else',
          'service_type': 'Lavage',
          'status': 'processing',
          'price': 27.5,
          'created_at': '2026-10-15T00:00:00Z',
          if (version >= 2) 'price_confirmed': 1,
          if (version >= 3) 'resident_link_verified': 1,
        });
        await legacy.insert('laundry_status_history', {
          'id': 12,
          'laundry_id': 'OLD',
          'old_status': 'deposited',
          'new_status': 'processing',
          'changed_by_user_id': 9,
          'changed_at': '2026-10-15T00:00:00Z',
          if (version >= 3) 'actor_verified': 1,
        });
        await legacy.close();
        final original = await File(file).readAsBytes();
        await db.transaction(
          (txn) => AppDatabase.importLegacyLaundry(txn, file),
        );
        final item = (await admin.getById('OLD'))!;
        expect(item.residentId, isNull);
        expect(item.residentName, 'Someone else');
        expect(item.price, 27.5);
        expect(item.priceConfirmed, version >= 2);
        expect(
          (await admin.getStatusHistory('OLD')).single.changedByUserId,
          isNull,
        );
        expect((await admin.getStatusHistory('OLD')).single.id, 12);
        expect(await resident.getByResidentId(1), isEmpty);
        expect(await File(file).readAsBytes(), original);
        final archive = await databaseFactoryFfi.openDatabase(
          file,
          options: OpenDatabaseOptions(readOnly: true),
        );
        expect((await archive.query('laundry_items')).single['resident_id'], 1);
        expect(
          (await archive.query('laundry_status_history'))
              .single['changed_by_user_id'],
          9,
        );
        await archive.close();
      },
    );
  }
}
