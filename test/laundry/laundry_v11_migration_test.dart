import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/laundry/data/laundry_schema.dart';

import 'support/test_accounts.dart';

void main() {
  test('actual AppDatabase v10 to v11 preserves every shared table and historical record', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final previousPath = await databaseFactoryFfi.getDatabasesPath();
    final directory = await Directory.systemTemp.createTemp('residry-v11-');
    Database? opened;
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
          version: 10,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onCreate: (db, _) async {
            for (final sql in schemas) {
              await db.execute(sql);
            }
            await db.insert('users', testResident.toMap());
            await db.insert('users', testAdmin.toMap());
            await AppDatabase.createLaundryTables(db);
            await db.insert('laundry_items', {
              'id': 'LEGACY',
              'resident_id': null,
              'resident_name': 'Historical name',
              'service_type': 'Historical service',
              'status': 'delivered',
              'price': 17.125,
              'price_confirmed': 1,
              'created_at': '2026-10-01',
            });
            await db.insert('laundry_status_history', {
              'laundry_id': 'LEGACY',
              'old_status': null,
              'new_status': 'delivered',
              'changed_by_user_id': null,
              'changed_at': '2026-10-02',
            });
          },
        ),
      );
      final sharedTables = (await previous.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'laundry_%'",
      )).map((row) => row['name'] as String).toList();
      final snapshots = <String, List<Map<String, Object?>>>{};
      for (final table in sharedTables) {
        snapshots[table] = await previous.query(table);
      }
      final old = (await previous.query('laundry_items')).single;
      final oldHistory = await previous.query('laundry_status_history');
      await previous.close();
      await databaseFactoryFfi.setDatabasesPath(directory.path);
      opened = await AppDatabase.instance.database;
      expect(await opened.getVersion(), 11);
      for (final table in sharedTables) {
        expect(
          await opened.query(table),
          snapshots[table],
          reason: '$table must not change',
        );
      }
      final current = (await opened.query('laundry_items')).single;
      for (final entry in old.entries) {
        expect(current[entry.key], entry.value);
      }
      expect(current['treatment_due_at'], isNull);
      expect(current['urgency'], isNull);
      expect(await opened.query('laundry_status_history'), oldHistory);
      expect(await opened.query('laundry_pricing_rules'), isEmpty);
      expect(await opened.query('laundry_request_lines'), isEmpty);
      expect((await opened.query('laundry_service_types')).length, 3);
      await opened.transaction((db) => LaundrySchema.upgradeV11(db));
      expect((await opened.query('laundry_service_types')).length, 3);
      expect(await opened.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    } finally {
      await opened?.close();
      await databaseFactoryFfi.setDatabasesPath(previousPath);
      await directory.delete(recursive: true);
    }
  });
}
