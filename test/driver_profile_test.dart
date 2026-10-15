import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/delivery_drivers/data/driver_profile_repository.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/tunisia_governorates.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/vehicle_capacity_evidence.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';

void main() {
  sqfliteFfiInit();
  test('24 governorates have unique stable codes and bilingual names', () {
    expect(tunisiaGovernorates.length, 24);
    expect(tunisiaGovernorates.map((g) => g.code).toSet().length, 24);
    expect(
        tunisiaGovernorates
            .every((g) => g.name.isNotEmpty && g.arabicName.isNotEmpty),
        isTrue);
  });

  test(
      'v4 migration preserves drivers and multi-zone profile survives reopening',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('residry-profile-test-');
    final path = '${directory.path}/profile.db';
    Database? db;
    try {
      db = await databaseFactoryFfi.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 4,
              onCreate: (db, _) async {
                await db.execute(
                    'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT, role TEXT)');
                await db.execute('''CREATE TABLE delivery_drivers (
            id TEXT PRIMARY KEY, name TEXT, email TEXT UNIQUE, phone TEXT,
            status TEXT, rating REAL, vehicle_type TEXT, assigned_zone TEXT,
            deliveries_completed INTEGER, archived_at TEXT)''');
                await db.insert('users',
                    {'id': 1, 'email': 'driver@test.tn', 'role': 'Livreur'});
                await db.insert('delivery_drivers', {
                  'id': 'existing',
                  'email': 'driver@test.tn',
                  'name': 'Driver',
                  'rating': 4.9,
                  'deliveries_completed': 15
                });
              }));
      await db.close();
      db = await databaseFactoryFfi.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 8,
              onUpgrade: (db, oldVersion, newVersion) async {
                await AppDatabase.createDriverProfileSchema(db);
                await AppDatabase.createCapacityEvidenceSchema(db);
                await AppDatabase.createRegistrationCertificateSchema(db);
                await AppDatabase.createUserPhoneSchema(db);
              }));
      await db.update('users', {'phone': '+21655123456'},
          where: 'id = ?', whereArgs: [1]);
      final repository = DriverProfileRepository(
          databaseProvider: () async => db!,
          evidenceDirectoryProvider: () async => directory);
      final initialPhoto =
          await File('${directory.path}/initial.jpg').writeAsBytes([1, 2, 3]);
      await expectLater(
          repository.save(
              email: 'driver@test.tn',
              name: 'Driver',
              vehicle: 'Moto',
              capacityKg: 40,
              governorateCodes: {'11'}),
          throwsArgumentError);
      await repository.save(
          email: 'driver@test.tn',
          name: 'Driver',
          vehicle: 'Camionnette',
          capacityKg: 750.5,
          governorateCodes: {'11', '61'},
          evidence: VehicleCapacityEvidence(
              imagePath: initialPhoto.path,
              source: 'gallery',
              brand: 'Example',
              model: 'Van',
              year: '2022',
              payloadKg: null,
              reserveKg: 100,
              ownerConfirmed: true));
      await db.close();
      db = await databaseFactoryFfi.openDatabase(path);
      final driver = (await db.query('delivery_drivers')).single;
      expect(driver['id'], 'existing');
      expect(driver['capacity_kg'], 750.5);
      expect(driver['assigned_zone'], 'Tunis, Sfax');
      expect(driver['phone'], '+21655123456');
      expect(driver['rating'], 4.9);
      expect(driver['deliveries_completed'], 15);
      expect(driver['capacity_assessment'], 'reviewRequired');
      final original =
          await File('${directory.path}/original.jpg').writeAsBytes([1, 2, 3]);
      await repository.save(
          email: 'driver@test.tn',
          name: 'Driver',
          vehicle: 'Camionnette',
          capacityKg: 750.5,
          governorateCodes: {'11', '61'},
          evidence: VehicleCapacityEvidence(
              imagePath: original.path,
              source: 'gallery',
              brand: 'Example',
              model: 'Van',
              year: '2022',
              payloadKg: 1000,
              reserveKg: 100,
              ownerConfirmed: true));
      final record = (await repository.getEvidence('existing'))!;
      final recordedAt = record['recorded_at']! as String;
      expect(record['photo_path'], isNot(original.path));
      expect(
          await File(record['photo_path']! as String).readAsBytes(), [1, 2, 3]);
      await original.delete();
      expect(await File(record['photo_path']! as String).exists(), isTrue);
      await expectLater(
          repository.reviewEvidence(
              driverId: 'existing',
              recordedAt: recordedAt,
              reviewer: 'Admin',
              approved: true,
              payloadKg: 800,
              reserveKg: 100),
          throwsArgumentError);
      expect(await db.query('vehicle_capacity_review_events'), isEmpty);
      await repository.reviewEvidence(
          driverId: 'existing',
          recordedAt: recordedAt,
          reviewer: 'Admin',
          approved: true,
          payloadKg: 1000,
          reserveKg: 100);
      expect((await db.query('delivery_drivers')).single['capacity_assessment'],
          'approved');
      expect(
          (await db.query('vehicle_capacity_review_events')).single['reviewer'],
          'Admin');
      await expectLater(
          repository.reviewEvidence(
              driverId: 'existing',
              recordedAt: 'stale',
              reviewer: 'Admin',
              approved: false),
          throwsStateError);
      expect(
          (await db.query('driver_service_zones'))
              .map((row) => row['governorate_code'])
              .toSet(),
          {'11', '61'});
      await expectLater(
          repository.save(
              email: 'driver@test.tn',
              name: 'Driver',
              vehicle: 'Moto',
              capacityKg: 40,
              governorateCodes: {}),
          throwsArgumentError);
      expect((await db.query('driver_service_zones')).length, 2);
    } finally {
      await db?.close();
      await directory.delete(recursive: true);
    }
  });

  testWidgets(
      'onboarding validates zones, selects multiple and preserves them on Back',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: DriverOnboardingPage(
            userName: 'Driver',
            initialEvidence: VehicleCapacityEvidence(
                imagePath: 'fixture.jpg',
                backImagePath: 'back.jpg',
                source: 'registration',
                brand: 'Example',
                model: 'Van',
                year: '2022',
                payloadKg: 750,
                reserveKg: 100,
                ownerConfirmed: true))));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Select at least one governorate.'), findsOneWidget);
    await tester.ensureVisible(find.text('Tunis'));
    await tester.tap(find.text('Tunis'));
    await tester.tap(find.text('Ariana'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 24 selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Registration certificate verification'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 24 selected'), findsOneWidget);
    await tester.ensureVisible(find.text('Select all'));
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('24 / 24 selected'), findsOneWidget);
    await tester.tap(find.text('Clear selection'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 24 selected'), findsOneWidget);
  });

  testWidgets(
      'admin Back returns to previous section and dashboard exit requires confirmation',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: AdminInterface(userName: 'Admin')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Locker management'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'Search locker or resident...');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Admin'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
        find.text('Do you want to sign out of your account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Admin'), findsOneWidget);
  });
}
