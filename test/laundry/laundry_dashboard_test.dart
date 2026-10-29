import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/driver_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_dashboard_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/pressing_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_design.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin;
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
    await admin.add(
      LaundryItem(
        id: 'DELIVERED',
        residentId: 1,
        residentName: '',
        serviceType: 'Lavage',
        status: LaundryStatus.delivered,
        price: 15.125,
        priceConfirmed: true,
      ),
    );
    await admin.add(
      LaundryItem(
        id: 'OTHER',
        residentId: 2,
        residentName: '',
        serviceType: 'Repassage',
        status: LaundryStatus.deposited,
        price: 99,
      ),
    );
  });
  tearDown(() async => db.close());

  Future<void> settleSqlite(WidgetTester tester) async {
    // Allow the real SQLite worker to respond outside Flutter's fake clock.
    for (var attempt = 0; attempt < 80; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
    fail('SQLite screen did not settle');
  }

  Future<void> open(
    WidgetTester tester,
    Widget page, {
    Locale locale = const Locale('fr'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: page,
      ),
    );
    await settleSqlite(tester);
  }

  for (final user in [testAdmin, testResident, testPressing, testDriver]) {
    testWidgets(
      '${user.role} opens a dashboard with real SQLite data and correct financial scope',
      (tester) async {
        final repository = admin.forUser(user);
        final Widget page = user == testAdmin
            ? LaundryPage(repository: repository)
            : user == testResident
            ? ResidentLaundryPage(repository: repository)
            : Scaffold(
                body: user == testDriver
                    ? DriverLaundryPage(repository: repository)
                    : PressingLaundryPage(repository: repository),
              );
        await open(tester, page);
        await tester.ensureVisible(find.text('Tableau de bord'));
        await tester.tap(find.text('Tableau de bord'));
        await settleSqlite(tester);
        expect(find.byType(LaundryDashboardPage), findsOneWidget);
        expect(find.text('Demandes'), findsOneWidget);
        if (user == testAdmin) {
          await tester.scrollUntilVisible(find.text('15.125 DT'), 200);
          expect(find.text('15.125 DT'), findsOneWidget);
        } else {
          expect(find.text('15.125 DT'), findsNothing);
        }
        await tester.scrollUntilVisible(
          find.text('Services les plus demandés'),
          250,
          scrollable: find
              .descendant(
                of: find.byType(LaundryDashboardPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.scrollUntilVisible(find.text('Lavage'), 150);
        expect(find.text('Lavage'), findsOneWidget);
        if (user == testAdmin || user == testPressing) {
          await tester.scrollUntilVisible(find.text('Repassage'), 150);
        }
        expect(
          find.text('Repassage'),
          user == testAdmin || user == testPressing
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('refresh recalculates statistics after a real repository write', (
    tester,
  ) async {
    await open(tester, LaundryDashboardPage(repository: admin));
    expect(find.text('Demandes'), findsOneWidget);
    await tester.runAsync(
      () => admin.add(
        LaundryItem(
          id: 'NEW',
          residentId: 1,
          residentName: '',
          serviceType: 'Nettoyage à sec',
          status: LaundryStatus.deposited,
          price: 0,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Actualiser'));
    await settleSqlite(tester);
    expect(find.text('3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nettoyage à sec'), 250);
    expect(find.text('Nettoyage à sec'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'pressing can switch between real age priority and status sorting',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await admin.delete('DELIVERED');
        await admin.add(
          LaundryItem(
            id: 'OLDEST',
            residentId: 1,
            residentName: '',
            serviceType: 'Older processing',
            status: LaundryStatus.processing,
            price: 0,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        );
      });
      await open(
        tester,
        Scaffold(
          body: PressingLaundryPage(repository: admin.forUser(testPressing)),
        ),
      );
      List<String> displayedIds() => tester
          .widgetList<LaundryRequestCard>(find.byType(LaundryRequestCard))
          .map((card) => card.item.id)
          .toList();
      expect(displayedIds(), ['OLDEST', 'OTHER']);
      expect(find.textContaining('Tri : retard'), findsNWidgets(2));
      await tester.tap(find.text('Par statut'));
      await tester.pumpAndSettle();
      expect(displayedIds(), ['OTHER', 'OLDEST']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final language in ['fr', 'en', 'ar']) {
    testWidgets('dashboard fits compact $language layout with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: LaundryDashboardPage(repository: admin),
        ),
      );
      await settleSqlite(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'failed report shows retry rather than fabricated zero statistics',
    (tester) async {
      await tester.runAsync(
        () => db.update(
          'users',
          {'role': 'unknown'},
          where: 'id = ?',
          whereArgs: [testAdmin.id],
        ),
      );
      await open(tester, LaundryDashboardPage(repository: admin));
      expect(find.text('Statistiques indisponibles'), findsOneWidget);
      expect(find.text('Demandes'), findsNothing);
      await tester.runAsync(
        () => db.update(
          'users',
          {'role': testAdmin.role},
          where: 'id = ?',
          whereArgs: [testAdmin.id],
        ),
      );
      await tester.tap(find.text('Réessayer'));
      await settleSqlite(tester);
      expect(find.text('Statistiques indisponibles'), findsNothing);
      expect(find.text('Demandes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
