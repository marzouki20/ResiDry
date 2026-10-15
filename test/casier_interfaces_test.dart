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
  final destinationFinder = find.descendant(
    of: find.byType(Drawer),
    matching: find.text(destination),
  );
  await tester.scrollUntilVisible(
    destinationFinder,
    250,
    scrollable: find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(destinationFinder);
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


  testWidgets('administrator sidebar opens laundry-company management', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );

    await _selectDrawerDestination(tester, 'Sociétés de lavage');

    expect(find.text('Sociétés de Lavage Partenaires'), findsOneWidget);
    expect(find.text('EcoWash Express Premium'), findsOneWidget);
    expect(find.text('Nouvelle Société'), findsOneWidget);
  });

  testWidgets('administrator can manage laundry items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );

    await _selectDrawerDestination(tester, 'Gestion du linge');

    expect(find.text('Gestion du linge'), findsOneWidget);
    expect(find.text('#LD001'), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter une commande'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modifier').first);
    await tester.pumpAndSettle();
    expect(find.text('Modifier la commande'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supprimer').first);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer la commande'), findsOneWidget);
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('#LD001'), findsNothing);
  });

  testWidgets('locker form validates required and duplicate identifiers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );
    await _selectDrawerDestination(tester, 'Gestion des casiers');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('L’identifiant du casier est obligatoire.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'C-024');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Cet identifiant est déjà utilisé.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'C-042');
    await tester.enterText(find.byType(TextFormField).at(3), '0');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez un poids valide'), findsOneWidget);
    expect(find.text('Nouveau casier'), findsOneWidget);
  });

  testWidgets('administrator can create, view, edit, and delete a locker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Admin')),
    );
    await _selectDrawerDestination(tester, 'Gestion des casiers');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'C-042');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nora Trabelsi');
    await tester.enterText(find.byType(TextFormField).at(2), 'D-402');
    await tester.enterText(find.byType(TextFormField).at(3), '10');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('C-042'), findsOneWidget);

    final createdLocker = find.ancestor(
      of: find.text('C-042'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: createdLocker,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir détails'));
    await tester.pumpAndSettle();
    expect(find.text('Casier C-042'), findsOneWidget);
    expect(find.text('Nora Trabelsi · D-402'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final lockerAfterDetails = find.ancestor(
      of: find.text('C-042'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: lockerAfterDetails,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Nora Ben Salem');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Nora Ben Salem · D-402'), findsOneWidget);

    final editedLocker = find.ancestor(
      of: find.text('C-042'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: editedLocker,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('C-042'), findsNothing);
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
