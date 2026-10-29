import 'support/laundry_rows.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/pressing_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_tariffs_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_request_editor.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin;
  late DateTime now;
  setUp(() async {
    db = await openLaundryTestDatabase();
    now = DateTime.now().toUtc();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
      clock: () => now,
    );
  });
  tearDown(() async => db.close());
  Future<void> settle(WidgetTester tester) async {
    for (var n = 0; n < 100; n++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
    fail('SQLite did not settle');
  }

  Future<void> open(
    WidgetTester tester,
    Widget page, {
    String language = 'fr',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        locale: Locale(language),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: page,
      ),
    );
    await settle(tester);
  }

  Future<void> tapRequestAction(WidgetTester tester, String label) async {
    final action = find.text(label);
    await tester.scrollUntilVisible(
      action,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    await settle(tester);
  }

  testWidgets(
    'admin configures real tariff, resident saves articles, admin sees calculated quote',
    (tester) async {
      await open(tester, LaundryPage(repository: admin));
      await tester.ensureVisible(find.text('Tarifs'));
      await tester.tap(find.text('Tarifs'));
      await settle(tester);
      expect(find.byType(LaundryTariffsPage), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '5');
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.enterText(find.byType(TextFormField).last, '90');
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final rates = await tester.runAsync(() => admin.getTariffs());
      expect(rates!.single.rate.unitPriceMillimes, 5000);
      expect(rates.single.estimatedMinutes, 90);
      await open(
        tester,
        ResidentLaundryPage(repository: admin.forUser(testResident)),
      );
      await tester.tap(find.text('Nouvelle demande'));
      await settle(tester);
      expect(find.byType(LaundryRequestEditor), findsOneWidget);
      expect(find.textContaining('DT'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Chemises blanches',
      );
      await tester.ensureVisible(find.byType(TextFormField).at(1));
      await tester.enterText(find.byType(TextFormField).at(1), '3');
      await tester.ensureVisible(find.byType(TextFormField).at(2));
      await tester.enterText(find.byType(TextFormField).at(2), '3');
      await tester.ensureVisible(find.byType(TextFormField).at(3));
      await tester.enterText(find.byType(TextFormField).at(3), 'Fragile');
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final requests = await tester.runAsync(() => admin.getAll());
      expect(requests!.single.price, 15);
      expect(requests.single.residentId, 1);
      final details = await tester.runAsync(
        () => admin.getDetails(requests.single.id),
      );
      expect(details!.lines.single.quantity, 3);
      expect(details.lines.single.weightGrams, 3000);
      expect(details.lines.single.instructions, 'Fragile');
      await open(tester, LaundryPage(repository: admin));
      await tester.scrollUntilVisible(
        find.text('Modifier'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await settle(tester);
      await tester.ensureVisible(find.text('Calculer le devis'));
      await tester.tap(find.text('Calculer le devis'));
      await settle(tester);
      final quote = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('15.000 DT'),
      );
      await tester.ensureVisible(quote);
      expect(quote, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'resident edits and deletes detailed requests through screens and real SQLite',
    (tester) async {
      final resident = admin.forUser(testResident);
      await open(tester, ResidentLaundryPage(repository: resident));
      await tester.tap(find.text('Nouvelle demande'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Chemise');
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final requests = await tester.runAsync(
        () => resident.getByResidentId(testResident.id!),
      );
      final id = requests!.single.id;
      await tapRequestAction(tester, 'Modifier');
      await tester.enterText(find.byType(TextFormField).first, 'Drap blanc');
      await tester.ensureVisible(find.byType(TextFormField).at(1));
      await tester.enterText(find.byType(TextFormField).at(1), '4');
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final details = await tester.runAsync(() => resident.getDetails(id));
      expect(details!.lines.single.garment, 'Drap blanc');
      expect(details.lines.single.quantity, 4);
      await tapRequestAction(tester, 'Supprimer');
      await tester.tap(find.text('Annuler'));
      await settle(tester);
      expect(await tester.runAsync(() => resident.getById(id)), isNotNull);
      await tester.tap(find.text('Supprimer'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await settle(tester);
      expect(
        await tester.runAsync(() => resident.getByResidentId(testResident.id!)),
        isEmpty,
      );
      expect(
        await tester.runAsync(
          () => readLaundryRows(db, 'laundry_request_lines'),
        ),
        isEmpty,
      );
      expect(
        await tester.runAsync(
          () => readLaundryRows(db, 'laundry_status_history'),
        ),
        isEmpty,
      );
      expect(
        (await tester.runAsync(() => db.query('users')))!.length,
        testAccounts.length,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'admin creates edits and deletes detailed requests through screens and real SQLite',
    (tester) async {
      await open(tester, LaundryPage(repository: admin));
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      expect(await tester.runAsync(() => admin.getAll()), isEmpty);
      final selector = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await settle(tester);
      await tester.tap(find.text('Sara · #2').last);
      await settle(tester);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Pantalon');
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final requests = await tester.runAsync(() => admin.getAll());
      final id = requests!.single.id;
      expect(requests.single.residentId, testOtherResident.id);
      expect(
        await tester.runAsync(
          () => admin.forUser(testResident).getByResidentId(testResident.id!),
        ),
        isEmpty,
      );
      await tapRequestAction(tester, 'Modifier');
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Pantalon noir');
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final details = await tester.runAsync(() => admin.getDetails(id));
      expect(details!.lines.single.garment, 'Pantalon noir');
      expect(details.item.residentId, testOtherResident.id);
      await tapRequestAction(tester, 'Supprimer');
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await settle(tester);
      expect(await tester.runAsync(() => admin.getAll()), isEmpty);
      expect(
        await tester.runAsync(() => db.rawQuery('PRAGMA foreign_key_check')),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'saved deadline produces a visible alert on refresh and ready clears it',
    (tester) async {
      await tester.runAsync(() async {
        await admin.saveRequest(
          LaundryDetails(
            item: LaundryItem(
              id: 'DUE',
              residentId: 1,
              residentName: '',
              serviceType: '',
              status: LaundryStatus.deposited,
              price: 0,
            ),
            dueAt: now.add(const Duration(minutes: 1)),
            lines: const [
              LaundryLine(
                id: 'L',
                garment: 'Chemise',
                serviceId: 'washing',
                quantity: 3,
                weightGrams: 3000,
              ),
            ],
          ),
        );
      });
      final pressing = admin.forUser(testPressing);
      await open(
        tester,
        Scaffold(body: PressingLaundryPage(repository: pressing)),
      );
      expect(find.textContaining('En retard :'), findsNothing);
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 1));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.textContaining('En retard :'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('En retard :'), findsOneWidget);
      await tester.runAsync(() async {
        await pressing.transitionStatus(
          'DUE',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
        );
        await pressing.transitionStatus(
          'DUE',
          expectedStatus: LaundryStatus.processing,
          newStatus: LaundryStatus.ready,
        );
      });
      await tester.tap(find.byTooltip('Actualiser'));
      await settle(tester);
      expect(find.textContaining('En retard :'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'deadline date and time pickers persist the explicitly selected value',
    (tester) async {
      // The repository clock is earlier than the picker's selected device time.
      now = now.subtract(const Duration(hours: 2));
      await open(
        tester,
        ResidentLaundryPage(repository: admin.forUser(testResident)),
      );
      await tester.tap(find.text('Nouvelle demande'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Chemise');
      final deadline = find.text('Échéance de traitement (facultative)');
      await tester.ensureVisible(deadline);
      await tester.tap(deadline);
      await settle(tester);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK').last);
      await settle(tester);
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK').last);
      await settle(tester);
      await tester.tap(find.text('Enregistrer'));
      await settle(tester);
      final items = await tester.runAsync(() => admin.getAll());
      final details = await tester.runAsync(
        () => admin.getDetails(items!.single.id),
      );
      expect(details!.dueAt, isNotNull);
      expect(details.dueAt!.isAfter(now), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final language in ['fr', 'en', 'ar']) {
    testWidgets('tariff configuration fits compact $language layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(
        tester,
        LaundryTariffsPage(repository: admin),
        language: language,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
