import 'package:ttttttteee/features/delivery_drivers/domain/vehicle_capacity_evidence.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttttttteee/core/localization/app_locale.dart';
import 'package:ttttttteee/core/localization/translation_catalog.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';
import 'package:ttttttteee/features/casiers/presentation/resident/resident_interface.dart';
import 'package:ttttttteee/features/delivery_drivers/data/delivery_repository.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/admin_driver_management.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_interface.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';
import 'package:ttttttteee/features/lockers/presentation/home_page.dart';
import 'package:ttttttteee/models/delivery_driver.dart';
import 'package:ttttttteee/models/delivery_order.dart';

class _Repository implements DeliveryRepository {
  _Repository({this.drivers});
  final List<DeliveryDriver>? drivers;
  @override
  Future<List<DeliveryDriver>> getDrivers() async =>
      drivers ?? demoDeliveryDrivers;
  @override
  Future<List<DeliveryOrder>> getMissions({String? driverName}) async =>
      demoDeliveryOrders;
  @override
  Future<void> assignMission(
      {required String missionId, required String driverId}) async {}
  @override
  Future<DeliveryOrder> advanceMission(String missionId) =>
      throw UnimplementedError();
}

Widget _app(AppLocaleController controller, Widget home) => AppLocaleScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => MaterialApp(
          theme: AppTheme.light,
          locale: controller.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: home,
        ),
      ),
    );

Future<void> _switchLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.language_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('application inbox shows pending submissions newest first',
      (tester) async {
    DeliveryDriver driver(String id, String status, DateTime? submitted) =>
        DeliveryDriver(
            id: id,
            name: id,
            email: '$id@test.tn',
            phone: '',
            applicationReviewStatus: status,
            applicationSubmittedAt: submitted);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AdminDriverManagementView(
                repository: _Repository(drivers: [
      driver('old', 'pending', DateTime.utc(2026, 10, 11)),
      driver('new', 'pending', DateTime.utc(2026, 10, 12)),
      driver('approved', 'approved', DateTime.utc(2026, 10, 12)),
      driver('seed', 'pending', null),
    ])))));
    await tester.pumpAndSettle();
    expect(find.text('New driver applications'), findsOneWidget);
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('pending-applications-count')))
            .data,
        '2');
    expect(find.byKey(const ValueKey('application-approved')), findsNothing);
    expect(find.byKey(const ValueKey('application-seed')), findsNothing);
    expect(
        tester.getTopLeft(find.byKey(const ValueKey('application-new'))).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const ValueKey('application-old')))
            .dy));
    expect(tester.takeException(), isNull);
  });

  test('all existing static translation calls have Arabic coverage', () {
    final pattern = RegExp(
        r'''en:\s*(['"])((?:\\.|(?!\1).)*?)\1\s*,\s*fr:\s*(['"])((?:\\.|(?!\3).)*?)\3(?:\s*,\s*ar:\s*(['"])((?:\\.|(?!\5).)*?)\5)?''',
        dotAll: true);
    final missing = <String>{};
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        final source = match[2]!;
        if (source.contains(r'$')) continue;
        if (!RegExp(r'[\u0600-\u06ff]')
            .hasMatch(match[6] ?? translateDisplayText(source, 'ar'))) {
          missing.add(source);
        }
      }
    }
    expect(missing, isEmpty, reason: 'Every static translation needs Arabic');
  });

  test('dynamic messages preserve identifiers and names in all languages', () {
    expect(translateDisplayText('Bonjour, Khalil', 'en'), 'Hello, Khalil');
    expect(translateDisplayText('Bonjour, Khalil', 'ar'), 'مرحبًا, Khalil');
    expect(translateDisplayText('Casier C-024 déverrouillé avec succès.', 'en'),
        'Locker C-024 unlocked successfully.');
    expect(translateDisplayText('Casier C-024 déverrouillé avec succès.', 'ar'),
        'تم فتح قفل الخزانة C-024 بنجاح.');
    expect(
        translateDisplayText(
            'Standard · Charge max. 8.0 kg · RFID/NFC activé', 'en'),
        'Standard · Max. load 8.0 kg · RFID/NFC enabled');
    expect(translateDisplayText('Aymen Abdellatif', 'ar'), 'Aymen Abdellatif');
    expect(translateDisplayText('CMD-101', 'fr'), 'CMD-101');
  });

  testWidgets(
      'admin language picker updates dashboard and drawer without leaving the account',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppLocaleController(initialLocale: const Locale('fr'));
    await tester
        .pumpWidget(_app(controller, const AdminInterface(userName: 'Khalil')));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour, Khalil'), findsOneWidget);
    await _switchLanguage(tester, 'English');
    expect(find.text('Hello, Khalil'), findsOneWidget);
    expect(find.text('Total lockers'), findsOneWidget);
    expect(find.text('Casiers au total'), findsNothing);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ADMINISTRATOR AREA'), findsOneWidget);
    expect(find.text('RESIDENCE MANAGEMENT'), findsOneWidget);
    expect(find.text('Driver management'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await _switchLanguage(tester, 'العربية');
    expect(find.text('إجمالي الخزائن'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(AdminInterface))),
        TextDirection.rtl);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('مساحة المسؤول'), findsOneWidget);
    expect(find.text('إدارة الخزائن'), findsOneWidget);
    await tester.tap(find.text('إدارة الخزائن'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('خزانة جديدة'), findsOneWidget);
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('حقل مطلوب'), findsWidgets);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    await _switchLanguage(tester, 'Français');
    expect(find.text('Gestion des casiers'), findsWidgets);
    expect(controller.locale, const Locale('fr'));
    expect((await AppLocaleController.load()).locale, const Locale('fr'));
    expect(tester.takeException(), isNull);
  });

  for (final code in ['fr', 'en', 'ar']) {
    testWidgets('resident and laundry pages render in $code', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppLocaleController(initialLocale: Locale(code));
      await tester.pumpWidget(
          _app(controller, const ResidentInterface(userName: 'Khalil')));
      await tester.pumpAndSettle();
      expect(
          find.text(
              translateDisplayText('Votre linge, en toute sérénité.', code)),
          findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('ESPACE RÉSIDENT', code)),
          findsOneWidget);
      await tester.tap(find.text(translateDisplayText('Historique', code)));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Porte fermée', code)),
          findsOneWidget);
      await tester.tap(find.text(translateDisplayText('Ce mois', code)));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Nouveau cycle de lavage', code)),
          findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(translateDisplayText('Notifications', code)));
      await tester.pumpAndSettle();
      expect(
          find.text(
              translateDisplayText('Votre casier est bien verrouillé.', code)),
          findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(translateDisplayText('Profil', code)));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Compte protégé', code)),
          findsOneWidget);
      await tester.pumpWidget(_app(controller,
          const HomePage(userName: 'Khalil', userRole: 'Société de lavage')));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Your lockers', code)),
          findsOneWidget);
      expect(find.textContaining('Khalil'), findsOneWidget);
    });

    testWidgets('driver screens and onboarding render in $code',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppLocaleController(initialLocale: Locale(code));
      await tester.pumpWidget(_app(
          controller,
          DriverInterface(
              userName: 'Aymen Abdellatif', repository: _Repository())));
      await tester.pumpAndSettle();
      expect(
          find.text(translateDisplayText(
              'Welcome to your ResiDry driver area.', code)),
          findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(
          find.text(translateDisplayText('DRIVER AREA', code)), findsOneWidget);
      await tester.tap(find.text(translateDisplayText('My deliveries', code)));
      await tester.pumpAndSettle();
      expect(
          find.text(translateDisplayText(
              'Manage laundry collections and locker drop-offs.', code)),
          findsOneWidget);
      for (final tab in ['IoT lockers', 'Notifications', 'My profile']) {
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(
            of: find.byType(Drawer),
            matching: find.text(translateDisplayText(tab, code))));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(_app(
          controller,
          Scaffold(
              body: AdminDriverManagementView(repository: _Repository()))));
      await tester.pumpAndSettle();
      expect(
          find.text(translateDisplayText(
              'Monitor drivers and assign missions.', code)),
          findsOneWidget);
      await tester.pumpWidget(_app(
          controller,
          const DriverOnboardingPage(
              userName: 'Khalil',
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
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Vehicle type', code)),
          findsOneWidget);
      await tester.tap(find.text(translateDisplayText('Continue', code)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(translateDisplayText('Continue', code)));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Service area', code)),
          findsOneWidget);
      await tester
          .ensureVisible(find.text(translateDisplayText('Tunis', code)));
      await tester.tap(find.text(translateDisplayText('Tunis', code)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(translateDisplayText('Continue', code)));
      await tester.pumpAndSettle();
      expect(find.text(translateDisplayText('Profile summary', code)),
          findsOneWidget);
    });
  }
}
