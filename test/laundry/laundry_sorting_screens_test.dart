import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_sorting.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_sorting_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/pressing_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_sorting_profile_dialog.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin, pressing;
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
    pressing = admin.forUser(testPressing);
    await admin.saveRequest(
      LaundryDetails(
        item: LaundryItem(
          id: 'R1',
          residentId: 1,
          residentName: '',
          serviceType: '',
          status: LaundryStatus.deposited,
          price: 0,
        ),
        lines: const [
          LaundryLine(
            id: 'L1',
            garment: 'Chemise blanche',
            serviceId: 'washing',
            quantity: 3,
          ),
          LaundryLine(
            id: 'L2',
            garment: 'Drap blanc',
            serviceId: 'washing',
            quantity: 1,
          ),
        ],
      ),
    );
  });
  tearDown(() async => db.close());
  Future<void> settle(WidgetTester tester) async {
    for (var n = 0; n < 150; n++) {
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
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        locale: Locale(language),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page,
      ),
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> choose<T>(WidgetTester tester, String label) async {
    await tap(tester, find.byType(DropdownButtonFormField<T>));
    await tap(tester, find.text(label).last);
  }

  testWidgets(
    'pressing opens sorting, validates input and saves actual care data and groups',
    (tester) async {
      await open(
        tester,
        Scaffold(body: PressingLaundryPage(repository: pressing)),
      );
      await tap(tester, find.text('Tri intelligent'));
      expect(find.byType(LaundrySortingPage), findsOneWidget);
      expect(
        find.textContaining('0 groupe(s) proposé(s) · 2 lot(s) à examiner'),
        findsOneWidget,
      );
      for (final id in ['L1', 'L2']) {
        final lot = find.byKey(ValueKey('sorting-lot-R1-$id'));
        await tap(
          tester,
          find.descendant(
            of: lot,
            matching: find.widgetWithText(TextButton, 'Vérifier l’étiquette'),
          ),
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Enregistrer'),
              )
              .onPressed,
          isNull,
        );
        await choose<LaundryColorFamily>(tester, 'Blancs');
        await choose<LaundryFabric>(tester, 'Coton');
        await choose<LaundryWashCycle>(tester, 'Normal');
        final temperature = find.byType(TextFormField);
        await tester.ensureVisible(temperature);
        for (final value in ['0', '-1', '0x10', '100', '40.5', 'abc']) {
          await tester.enterText(temperature, value);
          await tester.pumpAndSettle();
          expect(
            find.text('Entrez un entier entre 1 et 95 °C.'),
            findsOneWidget,
          );
        }
        await tester.enterText(temperature, '40');
        await tester.pumpAndSettle();
        expect(find.text('Entrez un entier entre 1 et 95 °C.'), findsNothing);
        await choose<LaundryDyeTransferRisk>(
          tester,
          'Faible selon vérification',
        );
        await choose<bool>(tester, 'Non');
        await tap(tester, find.byType(CheckboxListTile));
        await tap(tester, find.widgetWithText(FilledButton, 'Enregistrer'));
        expect(find.byType(LaundrySortingProfileDialog), findsNothing);
      }
      expect(find.text('Regroupement proposé'), findsOneWidget);
      final data = await tester.runAsync(() => pressing.getSortingData());
      expect(data!.plan.groups.single.quantity, 4);
      expect(
        data.lots.every((l) => l.profile!.verifiedByUserId == testPressing.id),
        isTrue,
      );
      expect(
        (await tester.runAsync(() => admin.getStatusHistory('R1')))!.length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('admin entry opens same real sorting data', (tester) async {
    await open(tester, LaundryPage(repository: admin));
    await tap(tester, find.text('Tri intelligent'));
    expect(find.byType(LaundrySortingPage), findsOneWidget);
    expect(find.text('Chemise blanche · 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final language in ['fr', 'en', 'ar']) {
    testWidgets('sorting and care form fit compact $language with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(
        tester,
        LaundrySortingPage(repository: pressing),
        language: language,
        scale: 1.5,
      );
      expect(
        Directionality.of(tester.element(find.byType(LaundrySortingPage))),
        language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
      final row = find.byKey(const ValueKey('sorting-lot-R1-L1'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final icon = find.descendant(
        of: row,
        matching: find.byIcon(Icons.fact_check_outlined),
      );
      await tap(tester, icon);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'resident cannot open sorting data even through direct navigation',
    (tester) async {
      await open(
        tester,
        LaundrySortingPage(repository: admin.forUser(testResident)),
      );
      expect(find.byType(LaundrySortingProfileDialog), findsNothing);
      expect(find.byIcon(Icons.fact_check_outlined), findsNothing);
      expect(
        find.textContaining('Un compte pressing ou administrateur est requis'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
