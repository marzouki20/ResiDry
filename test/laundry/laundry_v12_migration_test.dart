import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/laundry/data/laundry_schema.dart';

import 'support/test_accounts.dart';

void main() {
  test('legacy v11 to v12 migration preserves all tables and adds nullable care columns only', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final oldPath = await databaseFactoryFfi.getDatabasesPath();
    final directory = await Directory.systemTemp.createTemp('residry-sorting-');
    Database? current;
    try {
      final source = File('lib/database/database.dart').readAsStringSync();
      final schemas = RegExp(r"await database.execute\('''([\s\S]*?)'''\);")
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where((s) => s.trimLeft().startsWith('CREATE TABLE IF NOT EXISTS'));
      final previous = await databaseFactoryFfi.openDatabase(
        '${directory.path}/residry.db',
        options: OpenDatabaseOptions(
          version: 11,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onCreate: (db, _) async {
            for (final sql in schemas) {
              await db.execute(sql);
            }
            for (final user in [testResident, testPressing]) {
              await db.insert('users', user.toMap());
            }
            await AppDatabase.createLaundryTables(db);
            await LaundrySchema.upgradeV11(db);
            await db.insert('laundry_items', {
              'id': 'OLD',
              'resident_id': 1,
              'resident_name': 'Archive',
              'service_type': 'Lavage',
              'price': 17.125,
              'created_at': '2026-10-01',
            });
            await db.insert('laundry_request_lines', {
              'id': 'L',
              'laundry_id': 'OLD',
              'garment_type': 'Chemise',
              'service_id': 'washing',
              'quantity': 3,
              'pricing_basis': 'per_kg',
              'created_at': '2026-10-01',
            });
            await db.insert('laundry_status_history', {
              'laundry_id': 'OLD',
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
          version: 12,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onUpgrade: (db, oldVersion, newVersion) =>
              LaundrySchema.upgradeV12(db),
        ),
      );
      expect(await current.getVersion(), 12);
      expect(await current.rawQuery('PRAGMA table_info(users)'), userColumns);
      for (final entry in snapshots.entries) {
        final rows = await current.query(entry.key);
        if (entry.key != 'laundry_request_lines') {
          expect(rows, entry.value, reason: entry.key);
        } else {
          for (final old in entry.value.single.entries) {
            expect(rows.single[old.key], old.value);
          }
          final added = rows.single.entries.where(
            (e) => e.key.startsWith('sorting_'),
          );
          expect(added.length, 8);
          expect(added.every((e) => e.value == null), isTrue);
        }
      }
      await current.transaction((txn) => LaundrySchema.upgradeV12(txn));
      for (final values in [
        {'sorting_max_temperature_c': 0},
        {'sorting_max_temperature_c': 30.5},
        {'sorting_color': 'invented'},
        {
          'sorting_verified_by_user_id': 999,
          'sorting_verified_at': '2026-10-28',
        },
        {'sorting_verified_by_user_id': 7},
      ]) {
        await expectLater(
          current.update('laundry_request_lines', values),
          throwsA(isA<DatabaseException>()),
        );
      }
      await current.update('laundry_request_lines', {
        'sorting_color': 'white',
        'sorting_verified_by_user_id': 7,
        'sorting_verified_at': '2026-10-28',
      });
      expect(await current.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await current.close();
      current = await databaseFactoryFfi.openDatabase(
        '${directory.path}/residry.db',
      );
      expect(
        (await current.query('laundry_request_lines')).single['sorting_color'],
        'white',
      );
      expect((await current.query('laundry_items')).single['price'], 17.125);
    } finally {
      await current?.close();
      await databaseFactoryFfi.setDatabasesPath(oldPath);
      await directory.delete(recursive: true);
    }
  });
}
