import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/laundry/data/laundry_schema.dart';

import 'support/test_accounts.dart';

void main() {
  test('legacy v12 to v13 migration preserves sorting and creates empty complaint tables', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final oldPath = await databaseFactoryFfi.getDatabasesPath();
    final directory = await Directory.systemTemp.createTemp(
      'residry-claims-v13-',
    );
    Database? current;
    try {
      final source = File('lib/database/database.dart').readAsStringSync();
      final schemas = RegExp(r"await database.execute\('''([\s\S]*?)'''\);")
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where(
            (sql) => sql.trimLeft().startsWith('CREATE TABLE IF NOT EXISTS'),
          );
      final previous = await databaseFactoryFfi.openDatabase(
        '${directory.path}/residry.db',
        options: OpenDatabaseOptions(
          version: 12,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onCreate: (db, _) async {
            for (final sql in schemas) {
              await db.execute(sql);
            }
            for (final user in [testResident, testAdmin, testPressing]) {
              await db.insert('users', user.toMap());
            }
            await AppDatabase.createLaundryTables(db);
            await LaundrySchema.upgradeV11(db);
            await LaundrySchema.upgradeV12(db);
            await db.insert('laundry_items', {
              'id': 'R',
              'resident_id': 1,
              'resident_name': 'Archive',
              'service_type': 'Lavage',
              'price': 17.125,
              'created_at': '2026-10-01',
            });
            await db.insert('laundry_request_lines', {
              'id': 'L',
              'laundry_id': 'R',
              'garment_type': 'Chemise',
              'service_id': 'washing',
              'quantity': 3,
              'pricing_basis': 'per_kg',
              'created_at': '2026-10-01',
              'sorting_color': 'white',
              'sorting_fabric': 'cotton',
              'sorting_verified_by_user_id': 7,
              'sorting_verified_at': '2026-10-28',
            });
            await db.insert('laundry_status_history', {
              'laundry_id': 'R',
              'new_status': 'deposited',
              'changed_by_user_id': 1,
              'changed_at': '2026-10-01',
            });
          },
        ),
      );
      final tables = (await previous.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      )).map((r) => r['name'] as String);
      final snapshots = <String, List<Map<String, Object?>>>{};
      for (final table in tables) {
        snapshots[table] = await previous.query(table);
      }
      final userColumns = await previous.rawQuery('PRAGMA table_info(users)');
      await previous.close();
      await databaseFactoryFfi.setDatabasesPath(directory.path);
      current = await databaseFactoryFfi.openDatabase(
        '${directory.path}/residry.db',
        options: OpenDatabaseOptions(
          version: 13,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onUpgrade: (db, oldVersion, newVersion) =>
              LaundrySchema.upgradeV13(db),
        ),
      );
      expect(await current.getVersion(), 13);
      for (final entry in snapshots.entries) {
        expect(await current.query(entry.key), entry.value, reason: entry.key);
      }
      expect(await current.rawQuery('PRAGMA table_info(users)'), userColumns);
      for (final table in [
        'laundry_complaints',
        'laundry_complaint_events',
        'laundry_complaint_attachments',
      ]) {
        expect(await current.query(table), isEmpty);
      }
      await current.transaction((db) => LaundrySchema.upgradeV13(db));
      await current.insert('laundry_complaints', {
        'id': 'C',
        'laundry_id': 'R',
        'resident_id': 1,
        'line_id': 'L',
        'garment_snapshot': 'Chemise',
        'reason': 'damaged',
        'description': 'Description suffisamment longue',
        'created_at': '2026-10-28',
        'updated_at': '2026-10-28',
      });
      await expectLater(
        current.update('laundry_complaints', {'status': 'rejected'}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        current.update('laundry_complaints', {'resident_id': 999}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        current.delete('laundry_items', where: 'id = ?', whereArgs: ['R']),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        current.insert('laundry_complaint_events', {
          'complaint_id': 'C',
          'new_status': 'submitted',
          'actor_id': 999,
          'revision': 1,
          'created_at': '2026-10-28',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        current.insert('laundry_complaint_attachments', {
          'complaint_id': 'C',
          'mime_type': 'image/png',
          'content': 'not a blob',
          'created_at': '2026-10-28',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await current.insert('laundry_complaint_attachments', {
        'complaint_id': 'C',
        'mime_type': 'image/png',
        'content': Uint8List.fromList([1, 2, 3]),
        'created_at': '2026-10-28',
      });
      expect(await current.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await current.close();
      current = await databaseFactoryFfi.openDatabase(
        '${directory.path}/residry.db',
      );
      expect(
        (await current.query('laundry_complaint_attachments'))
            .single['content'],
        Uint8List.fromList([1, 2, 3]),
      );
      expect((await current.query('laundry_items')).single['price'], 17.125);
    } finally {
      await current?.close();
      await databaseFactoryFfi.setDatabasesPath(oldPath);
      await directory.delete(recursive: true);
    }
  });
}
