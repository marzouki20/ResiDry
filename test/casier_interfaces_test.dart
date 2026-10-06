import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';
import 'package:ttttttteee/features/casiers/presentation/resident/resident_interface.dart';

Future<void> _selectDrawerDestination(
  WidgetTester tester,
  String destination,
) async {
  await tester.tap(find.byTooltip('Ouvrir le menu'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Drawer), matching: find.text(destination)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('administrator sidebar opens, closes, and navigates pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );

    expect(find.text('Tableau de bord'), findsOneWidget);
    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    expect(find.text('ESPACE ADMINISTRATEUR'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer le menu'));
    await tester.pumpAndSettle();
    expect(find.text('ESPACE ADMINISTRATEUR'), findsNothing);

    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Gestion des casiers'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gestion des casiers'), findsWidgets);
    expect(find.text('ESPACE ADMINISTRATEUR'), findsNothing);
    expect(find.text('C-024'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau casier'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await _selectDrawerDestination(tester, 'Anomalies');
    expect(find.text('Anomalies & alertes'), findsOneWidget);
    await _selectDrawerDestination(tester, 'Maintenance');
    expect(
      find.text('Équipements à contrôler ou en cours de réparation.'),
      findsOneWidget,
    );
    await _selectDrawerDestination(tester, 'Profil');
    expect(find.text('Profil administrateur'), findsOneWidget);
  });

  testWidgets('resident sidebar navigates pages and only shows their locker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResidentInterface(userName: 'Resident Test')),
    );

    expect(find.text('C-024'), findsOneWidget);
    expect(find.text('5.2'), findsOneWidget);

    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    expect(find.text('ESPACE RÉSIDENT'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Mon casier'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ESPACE RÉSIDENT'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Déverrouiller le casier'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Déverrouiller le casier'), findsOneWidget);

    await tester.tap(find.text('Déverrouiller le casier'));
    await tester.pumpAndSettle();
    expect(find.text('Votre casier est déverrouillé.'), findsOneWidget);

    await _selectDrawerDestination(tester, 'Historique');
    expect(find.text('Historique'), findsWidgets);

    await _selectDrawerDestination(tester, 'Notifications');
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Sara Benali'), findsNothing);
    await _selectDrawerDestination(tester, 'Profil');
    expect(find.text('Mon profil'), findsWidgets);
    await _selectDrawerDestination(tester, 'Accueil');
    expect(find.text('Votre linge, en toute sérénité.'), findsOneWidget);
  });
}
