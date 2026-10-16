import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/app.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_navigation_access.dart';
import 'package:ttttttteee/features/residents/presentation/residents_home_page.dart';

import 'support/test_accounts.dart';

void main() {
  late Database db;
  late Directory directory;
  late String previousPath;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    previousPath = await databaseFactoryFfi.getDatabasesPath();
    directory = await Directory.systemTemp.createTemp('residry-login-test-');
    await databaseFactoryFfi.setDatabasesPath(directory.path);
    db = await AppDatabase.instance.database;
    for (final user in testAccounts) {
      await db.insert('users', user.toMap());
    }
  });
  tearDownAll(() async {
    await db.close();
    await databaseFactoryFfi.setDatabasesPath(previousPath);
    await directory.delete(recursive: true);
  });

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    // Native SQLite callbacks need real event-loop time; pumping only fake time
    // can leave an offstage dashboard's loading animation running indefinitely.
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty && !tester.binding.hasScheduledFrame) {
        break;
      }
    }
    expect(finder, findsOneWidget);
  }

  for (final user in [testResident, testDriver, testPressing, testAdmin]) {
    testWidgets('existing ${user.role} login preserves its actual users.id', (
      tester,
    ) async {
      await tester.pumpWidget(const OrbitApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), user.email);
      await tester.enterText(find.byType(TextField).at(1), user.password);
      await tester.ensureVisible(find.text('Sign in').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in').first);
      final destination = user == testResident
          ? find.byType(ResidentsHomePage)
          : user == testDriver
          ? find.byType(DriverOnboardingPage)
          : user == testPressing
          ? find.byType(LaundryNavigationAccess)
          : find.byType(AdminInterface);
      await waitFor(tester, destination);
      final actual = user == testResident
          ? tester.widget<ResidentsHomePage>(destination).currentUser
          : user == testDriver
          ? tester.widget<DriverOnboardingPage>(destination).currentUser
          : user == testPressing
          ? tester.widget<LaundryNavigationAccess>(destination).currentUser
          : tester.widget<AdminInterface>(destination).currentUser;
      expect(actual!.id, user.id);
      expect(actual.role, user.role);
      expect(actual.name, user.name);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'registration forwards inserted users.id, not independent residents.id',
    (tester) async {
      await tester.pumpWidget(const OrbitApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'New Resident');
      await tester.enterText(find.byType(TextField).at(1), 'new@test.invalid');
      await tester.enterText(find.byType(TextField).at(2), 'test-password');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await waitFor(tester, find.byType(ResidentsHomePage));
      final actual = tester
          .widget<ResidentsHomePage>(find.byType(ResidentsHomePage))
          .currentUser!;
      final account = (await tester.runAsync(
        () => db.query(
          'users',
          where: 'email = ?',
          whereArgs: ['new@test.invalid'],
        ),
      ))!.single;
      final profile = (await tester.runAsync(
        () => db.query(
          'residents',
          where: 'email = ?',
          whereArgs: ['new@test.invalid'],
        ),
      ))!.single;
      expect(actual.id, account['id']);
      expect(actual.id, isNot(profile['id']));
      expect(actual.role, 'Résident');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
