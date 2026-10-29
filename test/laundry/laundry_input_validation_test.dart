import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_tariffs_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_request_editor.dart';

import 'support/memory_database.dart';
import 'support/test_accounts.dart';

void main() {
  late LaundryRepository admin;
  setUp(() {
    final db = MemoryDatabase();
    db.rows['users']!.addAll(testAccounts.map((u) => u.toMap()));
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
  });
  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'resident sees required errors, invalid quantities and weights before anything is stored',
    (tester) async {
      await open(
        tester,
        ResidentLaundryPage(repository: admin.forUser(testResident)),
      );
      await tester.tap(find.text('Nouvelle demande'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '   ');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Champ obligatoire'), findsOneWidget);
      expect(await admin.getAll(), isEmpty);
      expect(
        tester.getTopLeft(fields.first).dy,
        inInclusiveRange(0, tester.view.physicalSize.height),
      );
      await tester.enterText(fields.first, 'Chemise blanche');
      await tester.pumpAndSettle();
      expect(find.text('Champ obligatoire'), findsNothing);
      await tester.ensureVisible(fields.at(1));
      await tester.pumpAndSettle();
      for (final invalid in ['0', '-1', '1.5', 'abc', '100001', '0x10', '+3']) {
        await tester.enterText(fields.at(1), invalid);
        await tester.pumpAndSettle();
        expect(
          find.text('Quantité positive attendue'),
          findsOneWidget,
          reason: invalid,
        );
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(await admin.getAll(), isEmpty);
      }
      await tester.enterText(fields.at(1), '3');
      await tester.pumpAndSettle();
      expect(find.text('Quantité positive attendue'), findsNothing);
      await tester.ensureVisible(fields.at(2));
      await tester.pumpAndSettle();
      for (final invalid in ['0', '-2', '1.2345', 'NaN', 'abc']) {
        await tester.enterText(fields.at(2), invalid);
        await tester.pumpAndSettle();
        expect(
          find.text('Poids positif, 3 décimales maximum'),
          findsOneWidget,
          reason: invalid,
        );
      }
      await tester.enterText(fields.at(2), '2,500');
      await tester.pumpAndSettle();
      expect(find.text('Poids positif, 3 décimales maximum'), findsNothing);
      expect(find.textContaining('DT'), findsNothing);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryRequestEditor), findsNothing);
      final details = await admin.getDetails((await admin.getAll()).single.id);
      expect(details.lines.single.quantity, 3);
      expect(details.lines.single.weightGrams, 2500);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tariff errors remain visible and corrected values can be saved',
    (tester) async {
      await open(tester, LaundryTariffsPage(repository: admin));
      final fields = find.byType(TextFormField);
      for (final value in ['-5', 'NaN', '1.2345', '']) {
        await tester.ensureVisible(fields.first);
        await tester.pumpAndSettle();
        await tester.enterText(fields.first, value);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(
          find.text('Montant valide, 3 décimales maximum'),
          findsOneWidget,
        );
        expect(await admin.getTariffs(), isEmpty);
      }
      await tester.enterText(fields.first, '5,125');
      await tester.pumpAndSettle();
      await tester.ensureVisible(fields.last);
      await tester.pumpAndSettle();
      for (final value in ['0', '-1', '1.5', 'abc', '525601', '0x10', '+3']) {
        await tester.enterText(fields.last, value);
        await tester.pumpAndSettle();
        expect(find.text('Durée positive attendue'), findsOneWidget);
      }
      await tester.enterText(fields.last, '90');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect((await admin.getTariffs()).single.rate.unitPriceMillimes, 5125);
      expect(tester.takeException(), isNull);
    },
  );
}
