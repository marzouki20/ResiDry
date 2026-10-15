import 'package:sqflite/sqflite.dart';
import '../core/validation/tunisian_phone.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = '$databasePath/residry.db';

    _database = await openDatabase(
      path,
      version: 8,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, _) async {
        await _createUsersTable(database);
        await _createDeliveryTables(database);
        await _seedDeliveryData(database);
        await createDriverProfileSchema(database);
        await createCapacityEvidenceSchema(database);
        await createRegistrationCertificateSchema(database);
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
          await _createDeliveryTables(database);
          await _seedDeliveryData(database);
        }
        if (oldVersion < 5) await createDriverProfileSchema(database);
        if (oldVersion < 6) await createCapacityEvidenceSchema(database);
        if (oldVersion >= 2 && oldVersion < 8) {
          await createUserPhoneSchema(database);
        }
        if (oldVersion < 7) await createRegistrationCertificateSchema(database);
      },
    );
    return _database!;
  }

  static Future<void> createUserPhoneSchema(DatabaseExecutor database) async {
    await database.execute('ALTER TABLE users ADD COLUMN phone TEXT');
  }

  static Future<void> createRegistrationCertificateSchema(
      DatabaseExecutor database) async {
    await database.execute(
        "ALTER TABLE vehicle_capacity_checks ADD COLUMN back_photo_path TEXT NOT NULL DEFAULT ''");
    await database.execute(
        "ALTER TABLE vehicle_capacity_checks ADD COLUMN registration_text TEXT NOT NULL DEFAULT ''");
    await database.execute(
        "ALTER TABLE vehicle_capacity_review_events ADD COLUMN back_photo_path TEXT NOT NULL DEFAULT ''");
  }

  static Future<void> createDriverProfileSchema(
      DatabaseExecutor database) async {
    await database.execute(
        'ALTER TABLE delivery_drivers ADD COLUMN capacity_kg REAL CHECK(capacity_kg > 0 AND capacity_kg <= 10000)');
    await database.execute('''
      CREATE TABLE driver_service_zones (
        driver_id TEXT NOT NULL REFERENCES delivery_drivers(id) ON DELETE CASCADE,
        governorate_code TEXT NOT NULL,
        PRIMARY KEY (driver_id, governorate_code)
      )
    ''');
  }

  static Future<void> createCapacityEvidenceSchema(
      DatabaseExecutor database) async {
    await database.execute(
        "ALTER TABLE delivery_drivers ADD COLUMN capacity_assessment TEXT NOT NULL DEFAULT 'reviewRequired'");
    await database.execute('''CREATE TABLE vehicle_capacity_checks (
      driver_id TEXT PRIMARY KEY REFERENCES delivery_drivers(id) ON DELETE CASCADE,
      brand TEXT NOT NULL, model TEXT NOT NULL, vehicle_year TEXT NOT NULL,
      photo_path TEXT NOT NULL, photo_source TEXT NOT NULL,
      payload_kg REAL, reserve_kg REAL, declared_kg REAL NOT NULL,
      owner_confirmed INTEGER NOT NULL, assessment TEXT NOT NULL,
      recorded_at TEXT NOT NULL, admin_review_status TEXT NOT NULL DEFAULT 'pending',
      reviewed_at TEXT, reviewed_by TEXT
    )''');
    await database.execute('''CREATE TABLE vehicle_capacity_review_events (
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

  Future<void> _createUsersTable(Database database) async {
    await database.execute('''
      CREATE TABLE users (
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
