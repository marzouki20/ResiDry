import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as paths;

import '../features/laundry_companies/data/sample_laundry_data.dart';
import '../features/laundry_companies/domain/models/machine.dart';
import '../features/laundry_companies/domain/models/societe_lavage.dart';
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
      version: 6,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, _) async {
        await _createUsersTable(database);
        await _createSocietesTable(database);
        await _createMachinesTable(database);
        await _seedInitialSocietes(database);
        await _createResidentsTable(database);
        await _seedResidents(database);
        await createLaundryTables(database);
        await importLegacyLaundry(
          database,
          paths.join(databasePath, 'laundry.db'),
        );
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
          await _createSocietesTable(database);
          await _createMachinesTable(database);
          await _seedInitialSocietes(database);
          await _createResidentsTable(database);
          await _seedResidents(database);
        }
        if (oldVersion < 5) {
          try {
            await database.execute(
              "ALTER TABLE machines ADD COLUMN programmeActuel TEXT",
            );
          } catch (_) {}
        }
        if (oldVersion < 6) {
          await createLaundryTables(database);
          await importLegacyLaundry(
            database,
            paths.join(databasePath, 'laundry.db'),
          );
        }
      },
    );
    return _database!;
  }

  Future<void> _createUsersTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSocietesTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS societes (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        adresse TEXT NOT NULL,
        telephone TEXT NOT NULL,
        email TEXT NOT NULL,
        statut TEXT NOT NULL,
        datePartenariat TEXT NOT NULL,
        noteEvaluation REAL NOT NULL,
        capaciteMaxKg INTEGER NOT NULL,
        iotHealthScore INTEGER NOT NULL,
        description TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createMachinesTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS machines (
        id TEXT PRIMARY KEY,
        societeId TEXT NOT NULL,
        nom TEXT NOT NULL,
        type TEXT NOT NULL,
        statut TEXT NOT NULL,
        capaciteKg REAL NOT NULL,
        progressionCycle REAL NOT NULL,
        tempsRestantMinutes INTEGER NOT NULL,
        temperatureC REAL NOT NULL,
        vibrationLevel REAL NOT NULL,
        consommationKwh REAL NOT NULL,
        santeIot INTEGER NOT NULL,
        programmeActuel TEXT,
        FOREIGN KEY (societeId) REFERENCES societes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _seedInitialSocietes(Database database) async {
    for (final s in initialSocietesLavage) {
      await database.insert(
        'societes',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      for (final m in s.machines) {
        await database.insert(
          'machines',
          m.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  Future<void> _createResidentsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS residents (
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

  // -------------------------------------------------------------
  // LAUNDRY: business data uses the SAME database and existing users.
  // -------------------------------------------------------------
  static Future<void> createLaundryTables(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE laundry_items (
        id TEXT PRIMARY KEY,
        resident_id INTEGER,
        resident_name TEXT NOT NULL,
        service_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'deposited',
        price REAL NOT NULL DEFAULT 0,
        price_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (price_confirmed IN (0, 1)),
        created_at TEXT NOT NULL,
        FOREIGN KEY (resident_id) REFERENCES users(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute('''
      CREATE TABLE laundry_status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        laundry_id TEXT NOT NULL,
        old_status TEXT,
        new_status TEXT NOT NULL,
        changed_by_user_id INTEGER,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (laundry_id) REFERENCES laundry_items(id) ON DELETE CASCADE,
        FOREIGN KEY (changed_by_user_id) REFERENCES users(id) ON DELETE RESTRICT
      )
    ''');
    await database.execute(
      'CREATE INDEX idx_laundry_resident ON laundry_items(resident_id)',
    );
    await database.execute(
      'CREATE INDEX idx_laundry_status ON laundry_items(status)',
    );
    await database.execute(
      'CREATE INDEX idx_laundry_history ON laundry_status_history(laundry_id, id)',
    );
  }

  /// Called inside the version-6 creation/upgrade transaction. Never changes or
  /// deletes laundry.db. Old numeric IDs are not evidence of account ownership.
  /// Original resident/author IDs remain available in that read-only archive.
  static Future<void> importLegacyLaundry(
    DatabaseExecutor database,
    String legacyPath,
  ) async {
    if (!await databaseExists(legacyPath)) return;
    final legacy = await openDatabase(
      legacyPath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      final tables = (await legacy.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      )).map((row) => row['name']).toSet();
      if (!tables.contains('laundry_items')) return;
      for (final row in await legacy.query('laundry_items')) {
        await database.insert('laundry_items', {
          'id': row['id'],
          'resident_id': null,
          'resident_name': row['resident_name'],
          'service_type': row['service_type'],
          'status': row['status'],
          'price': row['price'],
          'price_confirmed': row['price_confirmed'] ?? 0,
          'created_at': row['created_at'],
        });
      }
      if (tables.contains('laundry_status_history')) {
        for (final row in await legacy.query(
          'laundry_status_history',
          orderBy: 'id ASC',
        )) {
          await database.insert('laundry_status_history', {
            'id': row['id'],
            'laundry_id': row['laundry_id'],
            'old_status': row['old_status'],
            'new_status': row['new_status'],
            'changed_by_user_id': null,
            'changed_at': row['changed_at'],
          });
        }
      }
    } finally {
      await legacy.close();
    }
  }

  // -------------------------------------------------------------
  // USERS CRUD
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // SOCIETES & MACHINES CRUD (SQLite Persistance)
  // -------------------------------------------------------------
  Future<List<SocieteLavage>> getAllSocietes() async {
    final db = await database;
    final societesRows = await db.query('societes');
    final machinesRows = await db.query('machines');

    final machinesBySocieteId = <String, List<Machine>>{};
    for (final mRow in machinesRows) {
      final machine = Machine.fromMap(mRow);
      machinesBySocieteId.putIfAbsent(machine.societeId, () => []).add(machine);
    }

    return societesRows.map((sRow) {
      final sId = sRow['id'] as String;
      final machines = machinesBySocieteId[sId] ?? [];
      return SocieteLavage.fromMap(sRow, machines: machines);
    }).toList();
  }

  Future<void> saveSociete(SocieteLavage societe) async {
    final db = await database;
    await db.insert(
      'societes',
      societe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (final m in societe.machines) {
      await saveMachine(m);
    }
  }

  Future<void> deleteSociete(String societeId) async {
    final db = await database;
    await db.delete('machines', where: 'societeId = ?', whereArgs: [societeId]);
    await db.delete('societes', where: 'id = ?', whereArgs: [societeId]);
  }

  Future<void> saveMachine(Machine machine) async {
    final db = await database;
    await db.insert(
      'machines',
      machine.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMachine(String machineId) async {
    final db = await database;
    await db.delete('machines', where: 'id = ?', whereArgs: [machineId]);
  }

  // -------------------------------------------------------------
  // RESIDENTS CRUD
  // -------------------------------------------------------------
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
