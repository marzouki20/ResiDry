import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/laundry_dev_main.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/navigation/laundry_routes.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/driver_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/pressing_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_admin_dialog.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_navigation_access.dart';

import 'support/memory_database.dart';
import 'support/test_accounts.dart';

void main() {
  late MemoryDatabase db;
  late LaundryRepository admin;
  setUp(() {
    db = MemoryDatabase();
    db.rows['users']!.addAll(testAccounts.map((user) => user.toMap()));
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
  });
  LaundryItem item(
    String id, {
    int residentId = 1,
    LaundryStatus status = LaundryStatus.deposited,
    bool confirmed = false,
  }) => LaundryItem(
    id: id,
    residentId: residentId,
    residentName: 'Untrusted',
    serviceType: 'Lavage',
    status: status,
    price: 15,
    priceConfirmed: confirmed,
  );
  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: Scaffold(body: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'standalone admin fits compact screen and opens account selector',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          home: LaundryPage(repository: admin),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Compte résident'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('embedded admin uses its parent scaffold and app bar', (
    tester,
  ) async {
    await open(tester, LaundryPage(repository: admin, showAppBar: false));
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.byType(LaundryAdminDialog), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'admin creates from existing resident account and confirms free service',
    (tester) async {
      await open(tester, LaundryPage(repository: admin));
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Sélectionnez un compte résident.'), findsOneWidget);
      await tester.tap(find.text('Compte résident'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pressing'), findsNothing);
      await tester.tap(find.text('Ahmed · #1').last);
      await tester.pumpAndSettle();
      expect(find.text('Résident : Ahmed'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Repassage');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      final saved = (await admin.getAll()).single;
      expect(saved.residentId, 1);
      expect(saved.residentName, 'Ahmed');
      expect(saved.priceConfirmed, isTrue);
      expect(saved.price, 0);
      expect(
        (await admin.getStatusHistory(saved.id)).single.changedByUserId,
        9,
      );
    },
  );
  testWidgets(
    'resident ignores identity constructor fields and sees only own requests without prices',
    (tester) async {
      await admin.add(item('OWN', confirmed: true));
      await admin.add(item('OTHER', residentId: 2));
      await open(
        tester,
        ResidentLaundryPage(
          currentUser: testResident,
          residentId: 2,
          residentName: 'Fake',
          repository: admin,
        ),
      );
      expect(find.text('Bienvenue, Ahmed'), findsOneWidget);
      expect(find.text('#OWN'), findsOneWidget);
      expect(find.text('#OTHER'), findsNothing);
      expect(find.textContaining('DT'), findsNothing);
      await tester.ensureVisible(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Repassage');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect((await admin.getById('OWN'))!.serviceType, 'Repassage');
      expect((await admin.getById('OWN'))!.price, 15);
      expect((await admin.getById('OWN'))!.priceConfirmed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('resident creates service only, opens history, then deletes', (
    tester,
  ) async {
    await open(
      tester,
      ResidentLaundryPage(currentUser: testResident, repository: admin),
    );
    await tester.tap(find.text('Nouvelle demande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lavage');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved = (await admin.getAll()).single;
    expect(saved.residentId, 1);
    expect(saved.residentName, 'Ahmed');
    expect(find.textContaining('DT'), findsNothing);
    await tester.ensureVisible(find.text('Historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Utilisateur : 1'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(await admin.getAll(), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'resident cannot change a processed request or see unassigned legacy requests',
    (tester) async {
      await admin.add(item('PROCESS', status: LaundryStatus.processing));
      await db.insert(
        'laundry_items',
        LaundryItem(
          id: 'LEGACY',
          residentName: 'Ancien',
          serviceType: 'Lavage',
          status: LaundryStatus.deposited,
          price: 17,
        ).toMap(),
      );
      await open(
        tester,
        ResidentLaundryPage(currentUser: testResident, repository: admin),
      );
      expect(find.text('#PROCESS'), findsOneWidget);
      expect(find.text('#LEGACY'), findsNothing);
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
    },
  );
  testWidgets(
    'pressing performs its workflow with real actor and no CRUD controls',
    (tester) async {
      await admin.add(item('PRESS'));
      await open(
        tester,
        PressingLaundryPage(currentUser: testPressing, repository: admin),
      );
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
      await tester.ensureVisible(find.text('Commencer le traitement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer le traitement'));
      await tester.pumpAndSettle();
      expect((await admin.getById('PRESS'))!.status, LaundryStatus.processing);
      await tester.ensureVisible(find.text('Marquer comme prêt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marquer comme prêt'));
      await tester.pumpAndSettle();
      expect((await admin.getById('PRESS'))!.status, LaundryStatus.ready);
      expect(
        (await admin.getStatusHistory('PRESS')).map((h) => h.changedByUserId),
        [9, 7, 7],
      );
    },
  );
  testWidgets(
    'driver can cancel then confirm delivery without prices or admin controls',
    (tester) async {
      await admin.add(item('READY', status: LaundryStatus.ready));
      await admin.add(item('HIDDEN'));
      await open(
        tester,
        DriverLaundryPage(
          currentUser: testDriver,
          userId: 9999,
          repository: admin,
        ),
      );
      expect(find.text('Commande #READY'), findsOneWidget);
      expect(find.text('Commande #HIDDEN'), findsNothing);
      expect(find.textContaining('DT'), findsNothing);
      expect(find.text('Ajouter'), findsNothing);
      expect(find.text('Modifier'), findsNothing);
      await tester.ensureVisible(find.text('Marquer comme livré'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marquer comme livré'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect((await admin.getById('READY'))!.status, LaundryStatus.ready);
      await tester.tap(find.text('Marquer comme livré'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer la livraison'));
      await tester.pumpAndSettle();
      expect((await admin.getById('READY'))!.status, LaundryStatus.delivered);
      expect((await admin.getStatusHistory('READY')).last.changedByUserId, 8);
    },
  );
  testWidgets('admin totals and filters use only confirmed prices', (
    tester,
  ) async {
    await admin.add(item('CONFIRMED', confirmed: true));
    await admin.add(item('PENDING'));
    await open(tester, LaundryPage(repository: admin));
    expect(find.text('Total des tarifs validés : 15.00 DT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, 'Tarifs à valider'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Tarifs à valider'));
    await tester.pumpAndSettle();
    expect(find.text('#PENDING'), findsOneWidget);
    expect(find.text('#CONFIRMED'), findsNothing);
  });
  testWidgets('unknown and absent accounts cannot obtain Laundry controls', (
    tester,
  ) async {
    await open(
      tester,
      LaundryPage(currentUser: testUnknown, repository: admin),
    );
    expect(find.text('Impossible de charger les demandes.'), findsOneWidget);
    expect(find.text('Ajouter'), findsNothing);
    await open(
      tester,
      ResidentLaundryPage(
        repository: LaundryRepository(databaseProvider: () async => db),
        residentId: 1,
      ),
    );
    expect(find.text('Impossible de charger les demandes.'), findsOneWidget);
    expect(find.text('Nouvelle demande'), findsNothing);
  });
  testWidgets('all four routes retain account identity and a single scaffold', (
    tester,
  ) async {
    final builders = [
      () => LaundryRoutes.residentPage(
        currentUser: testResident,
        repository: admin,
      ),
      () =>
          LaundryRoutes.driverPage(currentUser: testDriver, repository: admin),
      () => LaundryRoutes.pressingPage(
        currentUser: testPressing,
        repository: admin,
      ),
      () => LaundryRoutes.adminPage(currentUser: testAdmin, repository: admin),
    ];
    final types = [
      ResidentLaundryPage,
      DriverLaundryPage,
      PressingLaundryPage,
      LaundryPage,
    ];
    for (var i = 0; i < builders.length; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(builders[i]()),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(types[i]), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Impossible de charger les demandes.'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'company wrapper preserves teammate screen and opens Laundry with its user',
    (tester) async {
      // Use the test repository for the destination separately in route tests;
      // this verifies the non-invasive access control and host preservation.
      await open(
        tester,
        const LaundryNavigationAccess(
          currentUser: testPressing,
          child: Text('Atelier existant'),
        ),
      );
      expect(find.text('Atelier existant'), findsOneWidget);
      expect(find.byTooltip('Gestion du linge'), findsOneWidget);
      await open(
        tester,
        const LaundryNavigationAccess(
          currentUser: testUnknown,
          child: Text('Atelier existant'),
        ),
      );
      expect(find.byTooltip('Gestion du linge'), findsNothing);
    },
  );
  testWidgets(
    'standalone launcher uses real login without development identities',
    (tester) async {
      await tester.pumpWidget(const LaundryDevApp());
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Choisir un utilisateur'), findsNothing);
      expect(find.text('Ahmed'), findsNothing);
    },
  );
  testWidgets(
    'standalone language picker supports French and Arabic without changing accounts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const LaundryDevApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Change language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Changer de langue'), findsOneWidget);
      await tester.tap(find.byTooltip('Changer de langue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      final languageButton = find.byTooltip('تغيير اللغة');
      expect(languageButton, findsOneWidget);
      expect(
        Directionality.of(tester.element(languageButton)),
        TextDirection.rtl,
      );
      expect(find.text('Choisir un utilisateur'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('authenticated dev repositories open each corresponding role', (
    tester,
  ) async {
    final users = [testResident, testDriver, testPressing, testAdmin];
    final types = [
      ResidentLaundryPage,
      DriverLaundryPage,
      PressingLaundryPage,
      LaundryPage,
    ];
    for (var i = 0; i < users.length; i++) {
      await tester.pumpWidget(
        LaundryDevApp(key: ValueKey(i), repository: admin.forUser(users[i])),
      );
      await tester.pumpAndSettle();
      expect(find.byType(types[i]), findsOneWidget);
      expect(find.text('Impossible de charger les demandes.'), findsNothing);
    }
  });
  testWidgets(
    'database failure shows retry and recovers using same authenticated user',
    (tester) async {
      var fail = true;
      final recoverable = LaundryRepository(
        currentUser: testDriver,
        databaseProvider: () async {
          if (fail) throw StateError('Unavailable');
          return db;
        },
      );
      await open(tester, DriverLaundryPage(repository: recoverable));
      expect(find.text('Impossible de charger les demandes.'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Aucune demande trouvée.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
