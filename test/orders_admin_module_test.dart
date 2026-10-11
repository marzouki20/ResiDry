import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/casiers/presentation/admin/admin_interface.dart';

void main() {
  testWidgets('administrator can open orders and view an order with IoT data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminInterface(userName: 'Administrateur test')),
    );

    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Dashboard commandes'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Administrateur test'), findsOneWidget);
    expect(find.byTooltip('Ouvrir le menu des commandes'), findsNothing);
    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Commandes'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CMD-1024'), findsOneWidget);
    await tester.tap(find.text('CMD-1024'));
    await tester.pumpAndSettle();

    expect(find.text('Informations commande'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Casier connecté · C-024'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Casier connecté · C-024'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Affecter un livreur'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Affecter un livreur'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Voir l’historique'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Voir l’historique'), findsOneWidget);
  });
}
