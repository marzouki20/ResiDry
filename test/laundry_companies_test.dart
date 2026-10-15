import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/laundry_companies/presentation/pages/societe_detail_page.dart';
import 'package:ttttttteee/features/laundry_companies/presentation/societes_lavage_page.dart';
import 'package:ttttttteee/features/laundry_companies/presentation/widgets/societe_form_dialog.dart';

void main() {
  testWidgets('SocietesLavagePage displays initial companies and statistics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocietesLavagePage(userName: 'Admin Test'),
      ),
    );

    expect(find.text('Sociétés de Lavage Partenaires'), findsOneWidget);
    expect(find.text('EcoWash Express Premium'), findsOneWidget);
    expect(find.text('Clean&Dry Residence Service'), findsOneWidget);
    expect(find.text('Azur Lavage & Pressing'), findsOneWidget);
    expect(find.text('Nouvelle Société'), findsOneWidget);
  });

  testWidgets('SocieteFormDialog validates required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SocieteFormDialog(
              onSave: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ajouter une Société'), findsOneWidget);

    // Tap Enregistrer without filling fields
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    // Verify validation errors are shown
    expect(find.text('Le nom de la société est obligatoire.'), findsOneWidget);
    expect(find.text('L’adresse est obligatoire.'), findsOneWidget);
    expect(find.text('Téléphone requis.'), findsOneWidget);
    expect(find.text('Email requis.'), findsOneWidget);
  });

  testWidgets('Can search companies and filter by status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocietesLavagePage(userName: 'Admin Test'),
      ),
    );

    // Filter by Sous Maintenance
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sous Maintenance'));
    await tester.pumpAndSettle();

    expect(find.text('Azur Lavage & Pressing'), findsOneWidget);
    expect(find.text('EcoWash Express Premium'), findsNothing);

    // Reset filter to Tous
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tous'));
    await tester.pumpAndSettle();

    // Search by text
    await tester.enterText(find.byType(TextField).first, 'Clean&Dry');
    await tester.pumpAndSettle();

    expect(find.text('Clean&Dry Residence Service'), findsOneWidget);
    expect(find.text('EcoWash Express Premium'), findsNothing);
  });

  testWidgets('Navigates to SocieteDetailPage and manages machines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocietesLavagePage(userName: 'Admin Test'),
      ),
    );

    // Tap on Consulter icon button of the first company
    final consulterBtn = find.byTooltip('Consulter').first;
    await tester.ensureVisible(consulterBtn);
    await tester.tap(consulterBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SocieteDetailPage), findsOneWidget);
    expect(find.text('Parc de Machines'), findsOneWidget);
    expect(find.text('EcoDrum Pro 01'), findsOneWidget);

    // Tap Ajouter Machine button
    await tester.tap(find.text('Ajouter Machine'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter une Machine IoT'), findsOneWidget);
  });
}
