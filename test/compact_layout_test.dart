import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/auth/presentation/auth_screen.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';
import 'package:ttttttteee/features/casiers/presentation/resident/resident_interface.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_interface.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry_companies/data/sample_laundry_data.dart';
import 'package:ttttttteee/features/laundry_companies/presentation/pages/societe_detail_page.dart';
import 'package:ttttttteee/features/laundry_companies/presentation/societes_lavage_page.dart';
import 'package:ttttttteee/features/residents/presentation/residents_home_page.dart';

Future<void> _openDrawerPage(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('Ouvrir le menu'));
  await tester.pumpAndSettle();
  final destination = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(title),
  );
  await tester.scrollUntilVisible(
    destination,
    220,
    scrollable: find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(destination);
  await tester.pumpAndSettle();
  final error = tester.takeException();
  if (error != null) {
    fail('Layout failed on $title: $error');
  }
}

void _expectNoLayoutError(WidgetTester tester, String screen) {
  final error = tester.takeException();
  if (error != null) {
    fail('Layout failed on $screen: $error');
  }
}

void main() {
  testWidgets('primary interfaces fit a compact 6.2-inch phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Authentication');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Authentication sign-up');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Authentication password reset');

    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Admin dashboard');
    await _openDrawerPage(tester, 'Gestion des casiers');
    await _openDrawerPage(tester, 'Anomalies');
    await _openDrawerPage(tester, 'Maintenance');
    await _openDrawerPage(tester, 'Profil');
    await _openDrawerPage(tester, 'Dashboard commandes');
    await _openDrawerPage(tester, 'Commandes');
    await _openDrawerPage(tester, 'Livraisons');
    await _openDrawerPage(tester, 'Alertes commandes');
    await _openDrawerPage(tester, 'Sociétés de lavage');
    expect(tester.takeException(), isNull, reason: 'Laundry companies');

    await tester.tap(find.text('EcoWash Express Premium'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Laundry company details');
    await tester.tap(find.text('Ajouter Machine'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Machine form');
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openDrawerPage(tester, 'Gestion du linge');
    _expectNoLayoutError(tester, 'Laundry management');

    await tester.pumpWidget(
      const MaterialApp(home: ResidentsHomePage(userName: 'Resident')),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Resident dashboard');
    await _openDrawerPage(tester, 'Profile');
    await _openDrawerPage(tester, 'Residence');
    await _openDrawerPage(tester, 'Laundry requests');
    await _openDrawerPage(tester, 'Notifications');
    await _openDrawerPage(tester, 'Locker assignment');

    await tester.pumpWidget(
      const MaterialApp(home: DriverInterface(userName: 'Driver')),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Driver dashboard');
    await _openDrawerPage(tester, 'Mes livraisons');
    await _openDrawerPage(tester, 'Casiers IoT');
    await _openDrawerPage(tester, 'Notifications');
    await _openDrawerPage(tester, 'Mon profil');

    await tester.pumpWidget(
      MaterialApp(
        home: SocieteDetailPage(
          societe: initialSocietesLavage.first,
          onSocieteUpdated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Company details');
    await tester.tap(find.text('Ajouter Machine'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Machine form');
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: SocietesLavagePage()));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Company list');
    await tester.ensureVisible(find.byType(FloatingActionButton));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Laundry company form');

    await tester.pumpWidget(
      const MaterialApp(home: DriverOnboardingPage(userName: 'Driver')),
    );
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Driver onboarding vehicle step');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Driver onboarding zone step');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Driver onboarding GPS step');

    await tester.pumpWidget(const MaterialApp(home: LaundryPage()));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Laundry list');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    _expectNoLayoutError(tester, 'Laundry item form');
  });
}
