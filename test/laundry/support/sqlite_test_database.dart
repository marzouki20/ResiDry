import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttttttteee/database/database.dart';

import 'test_accounts.dart';

import 'package:ttttttteee/features/laundry/data/laundry_schema.dart';
import 'package:ttttttteee/features/laundry/data/laundry_compact_schema.dart';

Future<Database> openLaundryTestDatabase({bool compact = true}) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('PRAGMA foreign_keys = ON');
  final source = File('lib/database/database.dart').readAsStringSync();
  final usersSql = RegExp(r'CREATE TABLE IF NOT EXISTS users \([\s\S]*?\)')
      .firstMatch(source)!
      .group(0)!;
  await db.execute(usersSql);
  await AppDatabase.createLaundryTables(db);
  await LaundrySchema.upgradeV11(db);
  await LaundrySchema.upgradeV12(db);
  await LaundrySchema.upgradeV13(db);
  for (final user in testAccounts) {
    await db.insert('users', user.toMap());
  }
  if (compact) await db.transaction(LaundryCompactSchema.upgradeV14);
  return db;
}
