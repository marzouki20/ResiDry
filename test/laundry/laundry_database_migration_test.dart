import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';

import 'support/test_accounts.dart';

void main() {
  test('real AppDatabase upgrades v5 once, preserves accounts and imports the archive safely', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final previousPath = await databaseFactoryFfi.getDatabasesPath();
    final directory = await Directory.systemTemp.createTemp(
      'residry-upgrade-test-',
    );
    Database? opened;
    addTearDown(() async {
      await opened?.close();
      await databaseFactoryFfi.setDatabasesPath(previousPath);
      await directory.delete(recursive: true);
    });
    await databaseFactoryFfi.setDatabasesPath(directory.path);
    final source = File('lib/database/database.dart').readAsStringSync();
    final sharedSchema = RegExp(r"await database.execute\('''([\s\S]*?)'''\);")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .where(
          (sql) => sql.trimLeft().startsWith('CREATE TABLE IF NOT EXISTS'),
        );
    final commonPath = paths.join(directory.path, 'residry.db');
    final previous = await databaseFactoryFfi.openDatabase(
      commonPath,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, version) async {
          for (final sql in sharedSchema) {
            await db.execute(sql);
          }
          await db.insert('users', testResident.toMap());
          await db.insert('users', testAdmin.toMap());
        },
      ),
    );
    final originalUsers = await previous.query('users', orderBy: 'id');
    await previous.close();

    final legacyPath = paths.join(directory.path, 'laundry.db');
    final archive = await databaseFactoryFfi.openDatabase(legacyPath);
    await archive.execute(
      'CREATE TABLE laundry_items(id TEXT PRIMARY KEY, resident_id INTEGER, resident_name TEXT, service_type TEXT, status TEXT, price REAL, created_at TEXT)',
    );
    await archive.execute(
      'CREATE TABLE laundry_status_history(id INTEGER PRIMARY KEY, laundry_id TEXT, old_status TEXT, new_status TEXT, changed_by_user_id INTEGER, changed_at TEXT)',
    );
    await archive.insert('laundry_items', {
      'id': 'OLD',
      'resident_id': 1,
      'resident_name': 'Different historical person',
      'service_type': 'Lavage',
      'status': 'deposited',
      'price': 15.0,
      'created_at': '2026-10-15T00:00:00Z',
    });
    await archive.insert('laundry_status_history', {
      'id': 1,
      'laundry_id': 'OLD',
      'old_status': null,
      'new_status': 'deposited',
      'changed_by_user_id': 9,
      'changed_at': '2026-10-15T00:00:00Z',
    });
    await archive.close();
    final originalArchive = await File(legacyPath).readAsBytes();

    final common = await AppDatabase.instance.database;
    opened = common;
    expect(await common.getVersion(), 6);
    expect(await common.query('users', orderBy: 'id'), originalUsers);
    expect((await common.query('laundry_items')).single['resident_id'], isNull);
    expect(
      (await common.query('laundry_status_history'))
          .single['changed_by_user_id'],
      isNull,
    );
    expect(
      await common.query(
        'laundry_items',
        where: 'resident_id = ?',
        whereArgs: [1],
      ),
      isEmpty,
    );
    expect(await common.rawQuery('PRAGMA foreign_keys'), [
      {'foreign_keys': 1},
    ]);
    expect(await common.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    expect(await File(legacyPath).readAsBytes(), originalArchive);
    await common.close();
    opened = await databaseFactoryFfi.openDatabase(commonPath);
    expect(await opened.getVersion(), 6);
    expect((await opened.query('laundry_items')).length, 1);
    expect((await opened.query('laundry_status_history')).length, 1);
    expect(await opened.query('users', orderBy: 'id'), originalUsers);
  });
}
