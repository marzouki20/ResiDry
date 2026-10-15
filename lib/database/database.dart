import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/residents/mock/residents_mock_data.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      databaseFactory = databaseFactoryFfi;
    }

    final databasePath = await getDatabasesPath();
    final path = '$databasePath/residry.db';

    _database = await openDatabase(
      path,
      version: 4,
      onCreate: (database, _) async {
        await _createUsersTable(database);
        await _createResidentsTable(database);
        await _seedResidents(database);
      },
      onUpgrade: (database, oldVersion, _) async {
        if (oldVersion < 2) {
          await _createUsersTable(database);
        }
        if (oldVersion >= 2 && oldVersion < 3) {
          await database.execute(
            "ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 4) {
          await _createResidentsTable(database);
          await _seedResidents(database);
        }
      },
    );
    return _database!;
  }

  Future<void> _createUsersTable(Database database) async {
    await database.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createResidentsTable(Database database) async {
    await database.execute('''
      CREATE TABLE residents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        residence_name TEXT NOT NULL,
        residence_address TEXT NOT NULL,
        city TEXT NOT NULL,
        postal_code TEXT NOT NULL,
        apartment_number TEXT NOT NULL,
        floor TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedResidents(Database database) async {
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM residents'),
    );

    if (count != null && count > 0) {
      return;
    }

    final demoResidents = <ResidentProfile>[
      demoResidentProfile,
      secondDemoResidentProfile,
    ];

    for (final resident in demoResidents) {
      await database.insert('residents', resident.toMap()..remove('id'));
    }
  }

  Future<int> createUser(Map<String, Object?> user) async {
    final database = await this.database;
    return database.insert('users', user);
  }

  Future<Map<String, Object?>?> findUserByEmail(String email) async {
    final database = await this.database;
    final users = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    return users.isEmpty ? null : users.first;
  }

  Future<int> createResident(ResidentProfile resident) async {
    final database = await this.database;
    return database.insert('residents', resident.toMap()..remove('id'));
  }

  Future<List<ResidentProfile>> listResidents() async {
    final database = await this.database;
    final rows = await database.query('residents', orderBy: 'id ASC');
    return rows.map(ResidentProfile.fromMap).toList();
  }

  Future<ResidentProfile?> getResidentByEmail(String email) async {
    final database = await this.database;
    final rows = await database.query(
      'residents',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ResidentProfile.fromMap(rows.first);
  }

  Future<int> updateResident(ResidentProfile resident) async {
    final database = await this.database;
    if (resident.id == null) {
      return 0;
    }

    return database.update(
      'residents',
      resident.toMap(),
      where: 'id = ?',
      whereArgs: [resident.id],
    );
  }

  Future<int> deleteResident(int residentId) async {
    final database = await this.database;
    return database.delete(
      'residents',
      where: 'id = ?',
      whereArgs: [residentId],
    );
  }
}
