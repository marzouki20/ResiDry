import 'dart:io';
import '../features/laundry/data/laundry_schema.dart';
import '../features/laundry/data/laundry_compact_schema.dart';
import '../features/laundry/data/laundry_storage.dart';
import 'package:path/path.dart' as paths;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../features/laundry_companies/data/sample_laundry_data.dart';
import '../features/laundry_companies/domain/models/machine.dart';
import '../features/laundry_companies/domain/models/societe_lavage.dart';
import '../features/residents/mock/residents_mock_data.dart';
import '../core/validation/tunisian_phone.dart';

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
      version: 14,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, _) async {
        await _createUsersTable(database);
        await _createSocietesTable(database);
        await _createMachinesTable(database);
        await _seedInitialSocietes(database);
        await _createResidentsTable(database);
        await _seedResidents(database);
        await _createDeliveryTables(database);
        await _seedDeliveryData(database);
        await createDriverProfileSchema(database);
        await createCapacityEvidenceSchema(database);
        await createRegistrationCertificateSchema(database);
        await ensureLaundrySchema(database, paths.join(databasePath, 'laundry.db'));
        await LaundrySchema.upgradeV11(database);
        await LaundrySchema.upgradeV12(database);
        await LaundrySchema.upgradeV13(database);
        await LaundryCompactSchema.upgradeV14(database);
      },
      onUpgrade: (database, oldVersion, _) async {
        if (oldVersion >= 10) {
          if (oldVersion < 11) {
            await LaundrySchema.upgradeV11(database);
          }
          if (oldVersion < 12) {
            await LaundrySchema.upgradeV12(database);
          }
          if (oldVersion < 13) {
            await LaundrySchema.upgradeV13(database);
          }
          if (oldVersion < 14) {
            await LaundryCompactSchema.upgradeV14(database);
          }
          return;
        }
        if (oldVersion < 2) {
          await _createUsersTable(database);
        }
        if (oldVersion >= 2 && oldVersion < 3) {
          await database.execute(
            "ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ''",
          );
        }
        await _createSocietesTable(database);
        await _createMachinesTable(database);
        await _createResidentsTable(database);
        await _seedInitialSocietes(database);
        await _seedResidents(database);
        if (!await _hasColumn(database, 'machines', 'programmeActuel')) {
          await database.execute(
            'ALTER TABLE machines ADD COLUMN programmeActuel TEXT',
          );
        }
        await _createDeliveryTables(database);
        await _seedDeliveryData(database);
        await createUserPhoneSchema(database);
        await createDriverProfileSchema(database);
        await createCapacityEvidenceSchema(database);
        await createRegistrationCertificateSchema(database);
        await ensureLaundrySchema(database, paths.join(databasePath, 'laundry.db'));
        await LaundrySchema.upgradeV11(database);
        await LaundrySchema.upgradeV12(database);
        await LaundrySchema.upgradeV13(database);
        await LaundryCompactSchema.upgradeV14(database);
      },
    );
    return _database!;
  }

  /// Supports both the team's v9 and Laundry's earlier v6 database.
  /// Import the archive only when adding Laundry for the first time.
  static Future<void> ensureLaundrySchema(
    DatabaseExecutor database,
    String legacyPath,
  ) async {
    final existing = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'laundry_items'],
    );
    if (existing.isNotEmpty) return;
    await createLaundryTables(database);
    await importLegacyLaundry(database, legacyPath);
  }

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
        final compact = (await database.query(
          'sqlite_master',
          columns: ['name'],
          where: 'type = ? AND name = ?',
          whereArgs: ['table', 'laundry_events'],
        )).isNotEmpty;
        for (final row in await legacy.query(
          'laundry_status_history',
          orderBy: 'id ASC',
        )) {
          final event = <String, Object?>{
            'id': row['id'],
            'laundry_id': row['laundry_id'],
            'old_status': row['old_status'],
            'new_status': row['new_status'],
            'changed_by_user_id': null,
            'changed_at': row['changed_at'],
          };
          if (compact) {
            await LaundryStorage.addHistory(database, event);
          } else {
            await database.insert('laundry_status_history', event);
          }
        }
      }
    } finally {
      await legacy.close();
    }
  }

  // -------------------------------------------------------------
  // USERS CRUD
  // -------------------------------------------------------------
  static Future<void> createUserPhoneSchema(DatabaseExecutor database) async {
    if (!await _hasColumn(database, 'users', 'phone')) {
      await database.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
  }

  static Future<bool> _hasColumn(
      DatabaseExecutor database, String table, String column) async {
    final columns = await database.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name'] == column);
  }

  static Future<void> createRegistrationCertificateSchema(
      DatabaseExecutor database) async {
    if (!await _hasColumn(
        database, 'vehicle_capacity_checks', 'back_photo_path')) {
      await database.execute(
          "ALTER TABLE vehicle_capacity_checks ADD COLUMN back_photo_path TEXT NOT NULL DEFAULT ''");
    }
    if (!await _hasColumn(
        database, 'vehicle_capacity_checks', 'registration_text')) {
      await database.execute(
          "ALTER TABLE vehicle_capacity_checks ADD COLUMN registration_text TEXT NOT NULL DEFAULT ''");
    }
    if (!await _hasColumn(
        database, 'vehicle_capacity_review_events', 'back_photo_path')) {
      await database.execute(
          "ALTER TABLE vehicle_capacity_review_events ADD COLUMN back_photo_path TEXT NOT NULL DEFAULT ''");
    }
  }

  static Future<void> createDriverProfileSchema(
      DatabaseExecutor database) async {
    if (!await _hasColumn(database, 'delivery_drivers', 'capacity_kg')) {
      await database.execute(
          'ALTER TABLE delivery_drivers ADD COLUMN capacity_kg REAL CHECK(capacity_kg > 0 AND capacity_kg <= 10000)');
    }
    await database.execute('''
      CREATE TABLE IF NOT EXISTS driver_service_zones (
        driver_id TEXT NOT NULL REFERENCES delivery_drivers(id) ON DELETE CASCADE,
        governorate_code TEXT NOT NULL,
        PRIMARY KEY (driver_id, governorate_code)
      )
    ''');
  }

  static Future<void> createCapacityEvidenceSchema(
      DatabaseExecutor database) async {
    if (!await _hasColumn(
        database, 'delivery_drivers', 'capacity_assessment')) {
      await database.execute(
          "ALTER TABLE delivery_drivers ADD COLUMN capacity_assessment TEXT NOT NULL DEFAULT 'reviewRequired'");
    }
    await database
        .execute('''CREATE TABLE IF NOT EXISTS vehicle_capacity_checks (
      driver_id TEXT PRIMARY KEY REFERENCES delivery_drivers(id) ON DELETE CASCADE,
      brand TEXT NOT NULL, model TEXT NOT NULL, vehicle_year TEXT NOT NULL,
      photo_path TEXT NOT NULL, photo_source TEXT NOT NULL,
      payload_kg REAL, reserve_kg REAL, declared_kg REAL NOT NULL,
      owner_confirmed INTEGER NOT NULL, assessment TEXT NOT NULL,
      recorded_at TEXT NOT NULL, admin_review_status TEXT NOT NULL DEFAULT 'pending',
      reviewed_at TEXT, reviewed_by TEXT
    )''');
    await database
        .execute('''CREATE TABLE IF NOT EXISTS vehicle_capacity_review_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      driver_id TEXT NOT NULL REFERENCES delivery_drivers(id),
      evidence_recorded_at TEXT NOT NULL, photo_path TEXT NOT NULL,
      reviewed_at TEXT NOT NULL, reviewer TEXT NOT NULL, decision TEXT NOT NULL,
      payload_kg REAL, reserve_kg REAL
    )''');
  }

  Future<void> _createDeliveryTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS delivery_drivers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        status TEXT NOT NULL CHECK (
          status IN ('En service', 'En livraison', 'Hors service')
        ),
        vehicle_type TEXT NOT NULL,
        rating REAL NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
        assigned_zone TEXT NOT NULL,
        deliveries_completed INTEGER NOT NULL DEFAULT 0
          CHECK (deliveries_completed >= 0),
        archived_at TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS delivery_missions (
        id TEXT PRIMARY KEY,
        resident_name TEXT NOT NULL,
        apartment TEXT NOT NULL,
        locker_id TEXT NOT NULL,
        laundry_company TEXT NOT NULL,
        status TEXT NOT NULL CHECK (
          status IN (
            'À récupérer', 'En transit', 'En lavage',
            'En transit retour', 'Déposé au casier', 'Livré'
          )
        ),
        mission_type TEXT NOT NULL CHECK (
          mission_type IN ('Collecte', 'Livraison')
        ),
        weight_kg REAL NOT NULL CHECK (weight_kg > 0),
        scheduled_at TEXT NOT NULL,
        scheduled_label TEXT NOT NULL,
        assigned_driver_id TEXT,
        notes TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (assigned_driver_id) REFERENCES delivery_drivers(id)
          ON DELETE RESTRICT
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS delivery_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mission_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        details TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES delivery_missions(id)
          ON DELETE RESTRICT
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_delivery_missions_driver_status
      ON delivery_missions(assigned_driver_id, status)
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_delivery_events_mission_time
      ON delivery_events(mission_id, occurred_at)
    ''');
  }

  Future<void> _seedDeliveryData(Database database) async {
    final drivers = <Map<String, Object?>>[
      {
        'id': 'LIV-001',
        'name': 'Aymen Abdellatif',
        'email': 'aymen@residry.tn',
        'phone': '+216 55 123 456',
        'status': 'En service',
        'vehicle_type': 'Scooter électrique',
        'rating': 4.9,
        'assigned_zone': 'Résidence Université',
        'deliveries_completed': 68,
      },
      {
        'id': 'LIV-002',
        'name': 'Sami Karray',
        'email': 'sami.karray@residry.tn',
        'phone': '+216 98 765 432',
        'status': 'En livraison',
        'vehicle_type': 'Camionnette',
        'rating': 4.8,
        'assigned_zone': 'Résidence Les Jardins',
        'deliveries_completed': 112,
      },
      {
        'id': 'LIV-003',
        'name': 'Youssef Mansouri',
        'email': 'youssef@residry.tn',
        'phone': '+216 22 334 455',
        'status': 'Hors service',
        'vehicle_type': 'Scooter',
        'rating': 4.7,
        'assigned_zone': 'Résidence Les Palmiers',
        'deliveries_completed': 35,
      },
    ];
    for (final driver in drivers) {
      await database.insert(
        'delivery_drivers',
        driver,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final now = DateTime.now().toUtc();
    final missions = <Map<String, Object?>>[
      _missionSeed(
        id: 'CMD-101',
        resident: 'Mohamed Khalil',
        apartment: 'A-204',
        locker: 'C-024',
        company: 'Pressing Express',
        status: 'À récupérer',
        type: 'Collecte',
        weight: 5.2,
        scheduledAt: now.add(const Duration(hours: 2)),
        label: 'Aujourd’hui · 14:00',
        driverId: 'LIV-001',
        notes: 'Linge délicat - Récupération au casier C-024',
      ),
      _missionSeed(
        id: 'CMD-102',
        resident: 'Sara Benali',
        apartment: 'B-105',
        locker: 'C-017',
        company: 'EcoClean Laundry',
        status: 'En transit',
        type: 'Collecte',
        weight: 3.8,
        scheduledAt: now.add(const Duration(hours: 1)),
        label: 'Aujourd’hui · 13:30',
        driverId: 'LIV-001',
        notes: 'Acheminement vers EcoClean',
      ),
      _missionSeed(
        id: 'CMD-103',
        resident: 'Yassine Amrani',
        apartment: 'A-310',
        locker: 'C-031',
        company: 'Pressing Plus',
        status: 'En transit retour',
        type: 'Livraison',
        weight: 4.5,
        scheduledAt: now.add(const Duration(hours: 3)),
        label: 'Aujourd’hui · 15:15',
        driverId: 'LIV-001',
        notes: 'Dépôt de linge propre prévu dans casier C-031',
      ),
      _missionSeed(
        id: 'CMD-098',
        resident: 'Lina Haddad',
        apartment: 'C-206',
        locker: 'C-012',
        company: 'Pressing Express',
        status: 'Déposé au casier',
        type: 'Livraison',
        weight: 3.1,
        scheduledAt: now.subtract(const Duration(days: 1)),
        label: 'Hier · 18:20',
        driverId: 'LIV-002',
        notes: 'Livré et casier verrouillé',
      ),
    ];
    for (final mission in missions) {
      await database.insert(
        'delivery_missions',
        mission,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Map<String, Object?> _missionSeed({
    required String id,
    required String resident,
    required String apartment,
    required String locker,
    required String company,
    required String status,
    required String type,
    required double weight,
    required DateTime scheduledAt,
    required String label,
    required String driverId,
    required String notes,
  }) {
    return {
      'id': id,
      'resident_name': resident,
      'apartment': apartment,
      'locker_id': locker,
      'laundry_company': company,
      'status': status,
      'mission_type': type,
      'weight_kg': weight,
      'scheduled_at': scheduledAt.toIso8601String(),
      'scheduled_label': label,
      'assigned_driver_id': driverId,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
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
    for (final societe in initialSocietesLavage) {
      await database.insert(
        'societes',
        societe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      for (final machine in societe.machines) {
        await database.insert(
          'machines',
          machine.toMap(),
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
    if (count != null && count > 0) return;
    for (final resident in [demoResidentProfile, secondDemoResidentProfile]) {
      await database.insert('residents', resident.toMap()..remove('id'));
    }
  }

  Future<List<SocieteLavage>> getAllSocietes() async {
    final db = await database;
    final societesRows = await db.query('societes');
    final machinesRows = await db.query('machines');
    final machinesBySocieteId = <String, List<Machine>>{};
    for (final row in machinesRows) {
      final machine = Machine.fromMap(row);
      machinesBySocieteId.putIfAbsent(machine.societeId, () => []).add(machine);
    }
    return societesRows.map((row) {
      final id = row['id'] as String;
      return SocieteLavage.fromMap(row,
          machines: machinesBySocieteId[id] ?? const []);
    }).toList();
  }

  Future<void> saveSociete(SocieteLavage societe) async {
    final db = await database;
    await db.insert('societes', societe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final machine in societe.machines) {
      await saveMachine(machine);
    }
  }

  Future<void> deleteSociete(String societeId) async {
    final db = await database;
    await db.delete('machines', where: 'societeId = ?', whereArgs: [societeId]);
    await db.delete('societes', where: 'id = ?', whereArgs: [societeId]);
  }

  Future<void> saveMachine(Machine machine) async {
    final db = await database;
    await db.insert('machines', machine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMachine(String machineId) async {
    final db = await database;
    await db.delete('machines', where: 'id = ?', whereArgs: [machineId]);
  }

  Future<int> createResident(ResidentProfile resident) async {
    final db = await database;
    return db.insert('residents', resident.toMap()..remove('id'));
  }

  Future<List<ResidentProfile>> listResidents() async {
    final db = await database;
    final rows = await db.query('residents', orderBy: 'id ASC');
    return rows.map(ResidentProfile.fromMap).toList();
  }

  Future<ResidentProfile?> getResidentByEmail(String email) async {
    final db = await database;
    final rows = await db.query('residents',
        where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : ResidentProfile.fromMap(rows.first);
  }

  Future<int> updateResident(ResidentProfile resident) async {
    final db = await database;
    if (resident.id == null) return 0;
    return db.update('residents', resident.toMap(),
        where: 'id = ?', whereArgs: [resident.id]);
  }

  Future<int> deleteResident(int residentId) async {
    final db = await database;
    return db.delete('residents', where: 'id = ?', whereArgs: [residentId]);
  }

  Future<void> _createUsersTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT
      )
    ''');
  }

  Future<int> createUser(Map<String, Object?> user) async {
    if (user['role'] == 'Livreur' &&
        (user['phone'] is! String ||
            !TunisianPhone.isValidInternational(user['phone']! as String))) {
      throw ArgumentError('A valid Tunisian driver phone number is required');
    }
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
}
