import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/laundry/data/laundry_compact_schema.dart';
import 'package:ttttttteee/features/laundry/data/laundry_storage.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/complaint_fixtures.dart';
import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

Future<void> seedLegacyLaundry(Database db, {int photoCount = 3}) async {
  await db.insert('laundry_items', {
    'id': 'LEGACY',
    'resident_id': 1,
    'resident_name': 'Historical name',
    'service_type': 'Lavage',
    'status': 'delivered',
    'price': 15.125,
    'price_confirmed': 1,
    'created_at': '2026-10-01T10:00:00.000Z',
    'treatment_due_at': '2026-10-02T10:00:00.000Z',
    'urgency': 'urgent',
    'revision': 5,
    'updated_at': '2026-10-03T10:00:00.000Z',
  });
  await db.insert('laundry_pricing_rules', {
    'id': 'OLD-RATE',
    'service_id': 'washing',
    'pricing_basis': 'per_kg',
    'unit_price_millimes': 5000,
    'estimated_minutes': 60,
    'valid_from': '2026-09-01',
    'valid_until': '2026-10-02',
    'created_by_user_id': 9,
    'created_at': '2026-09-01',
  });
  await db.insert('laundry_pricing_rules', {
    'id': 'NEW-RATE',
    'service_id': 'washing',
    'pricing_basis': 'per_kg',
    'unit_price_millimes': 6000,
    'estimated_minutes': 90,
    'valid_from': '2026-10-02',
    'created_by_user_id': 9,
    'created_at': '2026-10-02',
  });
  await db.insert('laundry_request_lines', {
    'id': 'OLD-LINE',
    'laundry_id': 'LEGACY',
    'garment_type': 'Chemise blanche',
    'service_id': 'washing',
    'quantity': 3,
    'weight_grams': 3025,
    'instructions': 'Ne pas utiliser de javel',
    'pricing_basis': 'per_kg',
    'pricing_rule_id': 'OLD-RATE',
    'unit_price_millimes': 5000,
    'total_millimes': 15125,
    'estimated_minutes': 60,
    'created_at': '2026-10-01T10:00:00.000Z',
    'sorting_color': 'white',
    'sorting_fabric': 'cotton',
    'sorting_cycle': 'normal',
    'sorting_max_temperature_c': 40,
    'sorting_dye_transfer_risk': 'low',
    'sorting_wash_separately': 0,
    'sorting_verified_by_user_id': 7,
    'sorting_verified_at': '2026-10-01T11:00:00.000Z',
  });
  for (var i = 0; i < 4; i++) {
    const statuses = ['deposited', 'processing', 'ready', 'delivered'];
    await db.insert('laundry_status_history', {
      'id': i + 1,
      'laundry_id': 'LEGACY',
      'old_status': i == 0 ? null : statuses[i - 1],
      'new_status': statuses[i],
      'changed_by_user_id': i == 0
          ? null
          : i == 3
          ? 8
          : 7,
      'changed_at': '2026-10-0${i + 1}T10:00:00.000Z',
    });
  }
  await db.insert('laundry_complaints', {
    'id': 'OLD-CLAIM',
    'laundry_id': 'LEGACY',
    'resident_id': 1,
    'line_id': 'OLD-LINE',
    'garment_snapshot': 'Chemise blanche',
    'reason': 'damaged',
    'description': 'Une chemise est déchirée après livraison.',
    'status': 'resolved',
    'decision_reason': 'La chemise a été réparée après examen.',
    'revision': 3,
    'resident_seen_revision': 2,
    'created_at': '2026-10-04T12:00:00.000Z',
    'updated_at': '2026-10-05T12:00:00.000Z',
  });
  for (var i = 0; i < 3; i++) {
    const states = ['submitted', 'reviewing', 'resolved'];
    await db.insert('laundry_complaint_events', {
      'id': i + 1,
      'complaint_id': 'OLD-CLAIM',
      'old_status': i == 0 ? null : states[i - 1],
      'new_status': states[i],
      'actor_id': i == 0 ? 1 : 9,
      'note': i == 2 ? 'La chemise a été réparée après examen.' : '',
      'revision': i + 1,
      'created_at': '2026-10-0${i + 4}T12:00:00.000Z',
    });
  }
  final photo = await complaintTestPhoto();
  for (var i = 0; i < photoCount; i++) {
    await db.insert('laundry_complaint_attachments', {
      'id': i + 20,
      'complaint_id': 'OLD-CLAIM',
      'mime_type': photo.mimeType,
      'content': photo.bytes,
      'created_at': '2026-10-04T12:0$i:00.000Z',
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('event identifiers exceed legacy IDs and are never reused after request deletion', () async {
    final db = await openLaundryTestDatabase(compact: false);
    try {
      await seedLegacyLaundry(db);
      await db.update(
        'laundry_status_history',
        {'id': 9000},
        where: 'id = ?',
        whereArgs: [4],
      );
      await db.transaction(LaundryCompactSchema.upgradeV14);
      expect((await LaundryStorage.history(db, 'LEGACY')).last['id'], 9000);
      final repo = LaundryRepository(
        currentUser: testAdmin,
        databaseProvider: () async => db,
      );
      LaundryItem item(String id) => LaundryItem(
        id: id,
        residentId: 1,
        residentName: '',
        serviceType: 'Lavage',
        status: LaundryStatus.deposited,
        price: 0,
      );
      await repo.add(item('FIRST'));
      final first = (await repo.getStatusHistory('FIRST')).single.id;
      expect(first, greaterThan(9000));
      await repo.delete('FIRST');
      await repo.add(item('SECOND'));
      expect(
        (await repo.getStatusHistory('SECOND')).single.id,
        greaterThan(first),
      );
    } finally {
      await db.close();
    }
  });

  test('an error after dropping source tables restores the original schema and photos', () async {
    final db = await openLaundryTestDatabase(compact: false);
    try {
      await seedLegacyLaundry(db);
      final before = await db.query('sqlite_master');
      final photos = await db.query('laundry_complaint_attachments');
      await expectLater(
        db.transaction(
          (txn) => LaundryCompactSchema.upgradeV14(_FailFinalIndex(txn)),
        ),
        throwsStateError,
      );
      expect(await db.query('sqlite_master'), before);
      expect(await db.query('laundry_complaint_attachments'), photos);
      expect((await db.query('laundry_status_history')).length, 4);
    } finally {
      await db.close();
    }
  });

  test(
    'external SQL views are preserved by cancelling an incompatible conversion',
    () async {
      final db = await openLaundryTestDatabase(compact: false);
      try {
        await seedLegacyLaundry(db);
        await db.execute(
          'CREATE VIEW teammate_view AS SELECT id FROM laundry_request_lines',
        );
        await expectLater(
          db.transaction(LaundryCompactSchema.upgradeV14),
          throwsStateError,
        );
        expect(await db.query('teammate_view'), [
          {'id': 'OLD-LINE'},
        ]);
      } finally {
        await db.close();
      }
    },
  );
  test('v13 conversion retains all content IDs prices care history photos and unread state in four tables', () async {
    final db = await openLaundryTestDatabase(compact: false);
    try {
      await seedLegacyLaundry(db);
      final lines = await db.query('laundry_request_lines');
      final rates = await db.query(
        'laundry_pricing_rules',
        orderBy: 'valid_from DESC',
      );
      final photos = await db.query(
        'laundry_complaint_attachments',
        orderBy: 'id ASC',
      );
      final users = await db.query('users');
      await db.transaction(LaundryCompactSchema.upgradeV14);
      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'laundry_%'",
      )).map((r) => r['name']).toSet();
      expect(tables, LaundryCompactSchema.tables);
      expect(await LaundryStorage.lines(db, 'LEGACY'), lines);
      expect(await LaundryStorage.tariffs(db), rates);
      expect(await LaundryStorage.photos(db, 'OLD-CLAIM'), photos);
      expect((await LaundryStorage.history(db, 'LEGACY')).map((e) => e['id']), [
        1,
        2,
        3,
        4,
      ]);
      expect(
        (await LaundryStorage.complaintEvents(
          db,
          'OLD-CLAIM',
        )).map((e) => e['id']),
        [1, 2, 3],
      );
      expect(
        (await LaundryStorage.history(
          db,
          'LEGACY',
        )).first['changed_by_user_id'],
        isNull,
      );
      expect(await db.query('users'), users);
      final repo = LaundryRepository(
        currentUser: testAdmin,
        databaseProvider: () async => db,
      );
      expect((await repo.getDetails('LEGACY')).item.price, 15.125);
      expect(
        (await repo.forUser(testResident).getComplaintInbox()).unreadCount,
        1,
      );
      expect((await repo.getComplaintDetails('OLD-CLAIM')).photos.length, 3);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await db.transaction(LaundryCompactSchema.upgradeV14);
      expect(await LaundryStorage.photos(db, 'OLD-CLAIM'), photos);
    } finally {
      await db.close();
    }
  });

  test('more than three historical photos aborts without deleting or changing any old rows or schema', () async {
    final db = await openLaundryTestDatabase(compact: false);
    try {
      await seedLegacyLaundry(db, photoCount: 4);
      final before = await db.query('sqlite_master');
      final photos = await db.query('laundry_complaint_attachments');
      await expectLater(
        db.transaction(LaundryCompactSchema.upgradeV14),
        throwsStateError,
      );
      expect(await db.query('sqlite_master'), before);
      expect(await db.query('laundry_complaint_attachments'), photos);
      expect(
        (await db.query('laundry_items')).single.containsKey('lines_json'),
        isFalse,
      );
    } finally {
      await db.close();
    }
  });

  test('external foreign key prevents conversion rather than changing teammate data', () async {
    final db = await openLaundryTestDatabase(compact: false);
    try {
      await seedLegacyLaundry(db);
      await db.execute(
        'CREATE TABLE teammate_reference (id INTEGER PRIMARY KEY, line TEXT REFERENCES laundry_request_lines(id))',
      );
      await db.insert('teammate_reference', {'id': 1, 'line': 'OLD-LINE'});
      await expectLater(
        db.transaction(LaundryCompactSchema.upgradeV14),
        throwsStateError,
      );
      expect(await db.query('teammate_reference'), [
        {'id': 1, 'line': 'OLD-LINE'},
      ]);
      expect((await db.query('laundry_request_lines')).length, 1);
    } finally {
      await db.close();
    }
  });

  test(
    'actual AppDatabase v13 to v14 preserves shared tables and survives reopen',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final oldPath = await databaseFactoryFfi.getDatabasesPath();
      final directory = await Directory.systemTemp.createTemp(
        'residry-four-tables-',
      );
      Database? current;
      try {
        final previous = await openLaundryTestDatabase(compact: false);
        final source = File('lib/database/database.dart').readAsStringSync();
        for (final match in RegExp(
          r"await database.execute\('''([\s\S]*?)'''\);",
        ).allMatches(source)) {
          final sql = match.group(1)!;
          if (sql.trimLeft().startsWith('CREATE TABLE IF NOT EXISTS')) {
            await previous.execute(sql);
          }
        }
        await previous.insert('societes', {
          'id': 'TEAM-CO',
          'nom': 'Team fixture',
          'adresse': 'Tunis',
          'telephone': '12345678',
          'email': 'fixture@test.invalid',
          'statut': 'Actif',
          'datePartenariat': '2026-10-01',
          'noteEvaluation': 4.0,
          'capaciteMaxKg': 20,
          'iotHealthScore': 90,
          'description': 'Unchanged team record',
        });
        await seedLegacyLaundry(previous);
        final shared = <String, List<Map<String, Object?>>>{};
        for (final row in await previous.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'laundry_%' AND name NOT LIKE 'sqlite_%'",
        )) {
          final name = row['name'] as String;
          shared[name] = await previous.query(name);
        }
        final userSchema = await previous.rawQuery('PRAGMA table_info(users)');
        await previous.setVersion(13);
        final path = '${directory.path}/residry.db';
        await previous.execute('VACUUM INTO ?', [path]);
        await previous.close();
        await databaseFactoryFfi.setDatabasesPath(directory.path);
        current = await AppDatabase.instance.database;
        expect(await current.getVersion(), 14);
        for (final entry in shared.entries) {
          expect(
            await current.query(entry.key),
            entry.value,
            reason: entry.key,
          );
        }
        expect(await current.rawQuery('PRAGMA table_info(users)'), userSchema);
        expect((await LaundryStorage.photos(current, 'OLD-CLAIM')).length, 3);
        await current.close();
        current = await databaseFactoryFfi.openDatabase(path);
        expect(
          (await LaundryStorage.lines(
            current,
            'LEGACY',
          )).single['sorting_verified_by_user_id'],
          7,
        );
        expect(
          (await LaundryStorage.complaintEvents(current, 'OLD-CLAIM')).length,
          3,
        );
        expect(await current.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      } finally {
        await current?.close();
        await databaseFactoryFfi.setDatabasesPath(oldPath);
        await directory.delete(recursive: true);
      }
    },
  );
}

/// Injects a failure after the DROP phase, while all reads/writes still run
/// against a real SQLite transaction. It never emulates or replaces persistence.
class _FailFinalIndex implements DatabaseExecutor {
  _FailFinalIndex(this.inner);
  final DatabaseExecutor inner;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute &&
        (invocation.positionalArguments.first as String).startsWith(
          'CREATE INDEX idx_laundry_events_request',
        )) {
      throw StateError('Test-only final index failure');
    }
    final method = switch (invocation.memberName) {
      #execute => inner.execute,
      #query => inner.query,
      #rawQuery => inner.rawQuery,
      #insert => inner.insert,
      #update => inner.update,
      #delete => inner.delete,
      _ => throw UnsupportedError('${invocation.memberName}'),
    };
    return Function.apply(
      method,
      invocation.positionalArguments,
      invocation.namedArguments,
    );
  }
}
