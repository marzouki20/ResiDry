import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/residents/presentation/residents_home_page.dart';

void main() {
  testWidgets('residents dashboard renders and supports navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResidentsHomePage(userName: 'Mohamed Raed')),
    );

    expect(find.text('Bonjour, Mohamed Raed'), findsOneWidget);
    expect(find.text('Statistiques utiles'), findsOneWidget);

    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Notifications'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Mark all as read'), findsOneWidget);
  });
}
