import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/features/delivery_drivers/data/sqlite_delivery_repository.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/delivery_status.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqliteDeliveryRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(
        'CREATE TABLE vehicle_capacity_checks (driver_id TEXT PRIMARY KEY, recorded_at TEXT, admin_review_status TEXT)');
    await database.execute('''
      CREATE TABLE delivery_drivers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        status TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        rating REAL NOT NULL,
        assigned_zone TEXT NOT NULL,
        deliveries_completed INTEGER NOT NULL,
        capacity_assessment TEXT DEFAULT 'approved',
        capacity_kg REAL DEFAULT 40,
        archived_at TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE delivery_missions (
        id TEXT PRIMARY KEY,
        resident_name TEXT NOT NULL,
        apartment TEXT NOT NULL,
        locker_id TEXT NOT NULL,
        laundry_company TEXT NOT NULL,
        status TEXT NOT NULL,
        mission_type TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        scheduled_at TEXT NOT NULL,
        scheduled_label TEXT NOT NULL,
        assigned_driver_id TEXT,
        notes TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE delivery_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mission_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        details TEXT NOT NULL,
        occurred_at TEXT NOT NULL
      )
    ''');
    await database.insert('delivery_drivers', {
      'id': 'LIV-001',
      'name': 'Aymen Abdellatif',
      'email': 'aymen@residry.tn',
      'phone': '+216 55 123 456',
      'status': 'En service',
      'vehicle_type': 'Scooter',
      'rating': 4.9,
      'assigned_zone': 'Tunis',
      'deliveries_completed': 0,
    });
    await database.insert('delivery_drivers', {
      'id': 'LIV-002',
      'name': 'Livreur indisponible',
      'email': 'offline@residry.tn',
      'phone': '+216 00 000 000',
      'status': 'Hors service',
      'vehicle_type': 'Scooter',
      'rating': 4.0,
      'assigned_zone': 'Tunis',
      'deliveries_completed': 0,
    });
    await database.insert('delivery_missions', {
      'id': 'MIS-001',
      'resident_name': 'Resident',
      'apartment': 'A-1',
      'locker_id': 'C-1',
      'laundry_company': 'Laundry',
      'status': DeliveryStatus.readyForPickup,
      'mission_type': 'Collecte',
      'weight_kg': 4.2,
      'scheduled_at': '2026-10-11T12:00:00Z',
      'scheduled_label': 'Aujourd’hui · 13:00',
      'updated_at': '2026-10-11T10:00:00Z',
    });
    repository = SqliteDeliveryRepository(
      databaseProvider: () async => database,
    );
  });

  tearDown(() => database.close());
  test('only submitted pending evidence becomes a pending application',
      () async {
    expect(
        (await repository.getDrivers()).every((d) => !d.hasPendingApplication),
        isTrue);
    await database.insert('vehicle_capacity_checks', {
      'driver_id': 'LIV-001',
      'recorded_at': '2026-10-12T10:00:00Z',
      'admin_review_status': 'pending'
    });
    var driver =
        (await repository.getDrivers()).firstWhere((d) => d.id == 'LIV-001');
    expect(driver.hasPendingApplication, isTrue);
    expect(driver.applicationSubmittedAt, DateTime.utc(2026, 10, 12, 10));
    for (final status in ['approved', 'rejected']) {
      await database
          .update('vehicle_capacity_checks', {'admin_review_status': status});
      driver =
          (await repository.getDrivers()).firstWhere((d) => d.id == 'LIV-001');
      expect(driver.hasPendingApplication, isFalse);
    }
  });

  test('pending and rejected drivers cannot receive missions or audit events',
      () async {
    for (final status in ['reviewRequired', 'consistent', 'rejected']) {
      await database.update('delivery_drivers', {'capacity_assessment': status},
          where: 'id = ?', whereArgs: ['LIV-001']);
      await expectLater(
          repository.assignMission(missionId: 'MIS-001', driverId: 'LIV-001'),
          throwsStateError);
      expect(
          (await database.query('delivery_missions'))
              .single['assigned_driver_id'],
          isNull);
      expect(await database.query('delivery_events'), isEmpty);
    }
  });

  test('assignment reserves capacity and reassignment does not double count',
      () async {
    await database.update('delivery_drivers', {'capacity_kg': 4},
        where: 'id = ?', whereArgs: ['LIV-001']);
    await expectLater(
        repository.assignMission(missionId: 'MIS-001', driverId: 'LIV-001'),
        throwsStateError);
    await database.update('delivery_drivers', {'capacity_kg': 5},
        where: 'id = ?', whereArgs: ['LIV-001']);
    await repository.assignMission(missionId: 'MIS-001', driverId: 'LIV-001');
    await repository.assignMission(missionId: 'MIS-001', driverId: 'LIV-001');
    final another = Map<String, Object?>.of(
        (await database.query('delivery_missions')).single)
      ..['id'] = 'MIS-002'
      ..['assigned_driver_id'] = null;
    await database.insert('delivery_missions', another);
    await expectLater(
        repository.assignMission(missionId: 'MIS-002', driverId: 'LIV-001'),
        throwsStateError);
    await database.update(
        'delivery_missions', {'status': DeliveryStatus.delivered},
        where: 'id = ?', whereArgs: ['MIS-001']);
    await repository.assignMission(missionId: 'MIS-002', driverId: 'LIV-001');
  });

  test('assigns only a ready mission to an active driver and audits it',
      () async {
    await repository.assignMission(
      missionId: 'MIS-001',
      driverId: 'LIV-001',
    );

    final missions = await repository.getMissions(
      driverName: 'Aymen Abdellatif',
    );
    final events = await database.query('delivery_events');

    expect(missions, hasLength(1));
    expect(missions.single.driverName, 'Aymen Abdellatif');
    expect(events.single['event_type'], 'MISSION_ASSIGNED');
  });

  test('rejects assignment to an unavailable driver', () async {
    expect(
      () => repository.assignMission(
        missionId: 'MIS-001',
        driverId: 'LIV-002',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('advances mission in the defined order and writes an event', () async {
    final updated = await repository.advanceMission('MIS-001');
    final events = await database.query('delivery_events');

    expect(updated.status, DeliveryStatus.outboundTransit);
    expect(events.single['event_type'], 'STATUS_CHANGED');
    expect(events.single['details'], contains(DeliveryStatus.outboundTransit));
  });

  test('does not advance a completed mission', () async {
    await database.update(
      'delivery_missions',
      {'status': DeliveryStatus.delivered},
      where: 'id = ?',
      whereArgs: ['MIS-001'],
    );

    expect(
      () => repository.advanceMission('MIS-001'),
      throwsA(isA<StateError>()),
    );
  });
}
