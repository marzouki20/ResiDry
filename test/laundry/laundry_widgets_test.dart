// Relative imports are required by this module's project instructions.
// ignore_for_file: avoid_relative_lib_imports

import '../../lib/features/laundry/laundry_dev_main.dart';
import '../../lib/features/laundry/data/models/laundry_role.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/theme/app_theme.dart';
import '../../lib/features/laundry/data/models/laundry_item.dart';
import '../../lib/features/laundry/data/repositories/laundry_repository.dart';
import '../../lib/features/laundry/presentation/driver_laundry_page.dart';
import '../../lib/features/laundry/presentation/laundry_admin_dialog.dart';
import '../../lib/features/laundry/presentation/laundry_page.dart';
import '../../lib/features/laundry/presentation/laundry_routes.dart';
import '../../lib/features/laundry/presentation/pressing_laundry_page.dart';
import '../../lib/features/laundry/presentation/resident_laundry_page.dart';
import 'support/memory_database.dart';

void main() {
  late LaundryRepository repository;
  setUp(() {
    final db = MemoryDatabase();
    repository = LaundryRepository(databaseProvider: () async => db);
  });

  LaundryItem item(String id, LaundryStatus status, {int residentId = 1}) =>
      LaundryItem(
        id: id,
        residentId: residentId,
        residentName: 'Résident $residentId',
        serviceType: 'Lavage',
        status: status,
        price: 15,
      );

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('standalone administrator page has working navigation shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LaundryPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(LaundryAdminDialog), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
  });

  testWidgets('embedded administrator page uses its parent navigation shell', (
    tester,
  ) async {
    await open(tester, LaundryPage(repository: repository, showAppBar: false));
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.byType(LaundryAdminDialog), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('resident sees only own requests and deposited edit controls', (
    tester,
  ) async {
    await repository.add(item('OWN', LaundryStatus.deposited));
    await repository.add(item('OTHER', LaundryStatus.deposited, residentId: 2));
    await open(
      tester,
      ResidentLaundryPage(
        residentId: 1,
        residentName: 'Ahmed',
        repository: repository,
      ),
    );
    expect(find.text('#OWN'), findsOneWidget);
    expect(find.text('#OTHER'), findsNothing);
    expect(find.text('Modifier'), findsOneWidget);
    await tester.ensureVisible(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Repassage');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect((await repository.getById('OWN'))!.price, 15);
    expect(find.textContaining('DT'), findsNothing);
    expect(find.text('Service : Repassage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resident dialog validates input and disposes on cancellation', (
    tester,
  ) async {
    await open(
      tester,
      ResidentLaundryPage(
        residentId: 1,
        residentName: 'Ahmed',
        repository: repository,
      ),
    );
    await tester.tap(find.text('Nouvelle demande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(await repository.getAll(), isEmpty);
  });

  testWidgets('driver sees ready/delivered only and can complete delivery', (
    tester,
  ) async {
    await repository.add(item('READY', LaundryStatus.ready));
    await repository.add(item('HIDDEN', LaundryStatus.deposited));
    await open(tester, DriverLaundryPage(repository: repository, userId: 8));
    expect(find.text('Commande #READY'), findsOneWidget);
    expect(find.text('Commande #HIDDEN'), findsNothing);
    expect(find.text('Ajouter'), findsNothing);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
    expect(find.textContaining('DT'), findsNothing);
    await tester.ensureVisible(find.text('Marquer comme livré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme livré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer la livraison'));
    await tester.pumpAndSettle();
    expect(
      (await repository.getById('READY'))!.status,
      LaundryStatus.delivered,
    );
    expect(find.text('Marquer comme livré'), findsNothing);
    expect(find.text('Statut : Livré'), findsOneWidget);
  });

  testWidgets('pressing starts and completes treatment without CRUD controls', (
    tester,
  ) async {
    await repository.add(item('PRESS', LaundryStatus.deposited));
    await open(tester, PressingLaundryPage(repository: repository, userId: 7));
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
    await tester.ensureVisible(find.text('Commencer le traitement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer le traitement'));
    await tester.pumpAndSettle();
    expect(
      (await repository.getById('PRESS'))!.status,
      LaundryStatus.processing,
    );
    await tester.ensureVisible(find.text('Marquer comme prêt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme prêt'));
    await tester.pumpAndSettle();
    expect((await repository.getById('PRESS'))!.status, LaundryStatus.ready);
    expect(find.text('Marquer comme livré'), findsNothing);
  });

  testWidgets('administrator uses injected repository and filters statuses', (
    tester,
  ) async {
    await repository.add(item('ADMIN', LaundryStatus.deposited));
    await open(tester, LaundryPage(repository: repository));
    expect(find.text('#ADMIN'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Prêt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Prêt'));
    await tester.pumpAndSettle();
    expect(find.text('#ADMIN'), findsNothing);
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.byType(LaundryAdminDialog), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('all four route builders open the correct screen', (
    tester,
  ) async {
    final routes = [
      () => LaundryRoutes.residentPage(
        residentId: 1,
        residentName: 'Ahmed',
        repository: repository,
      ),
      () => LaundryRoutes.driverPage(repository: repository),
      () => LaundryRoutes.pressingPage(repository: repository),
      () => LaundryRoutes.adminPage(repository: repository),
    ];
    final types = [
      ResidentLaundryPage,
      DriverLaundryPage,
      PressingLaundryPage,
      LaundryPage,
    ];
    for (var i = 0; i < routes.length; i++) {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          navigatorKey: navigator,
          home: const Scaffold(),
        ),
      );
      navigator.currentState!.push(routes[i]());
      await tester.pumpAndSettle();
      expect(find.byType(types[i]), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'development dropdown opens all four roles without nested scaffolds',
    (tester) async {
      await tester.pumpWidget(LaundryDevApp(repository: repository));
      await tester.pumpAndSettle();
      final types = {
        LaundryRole.resident: ResidentLaundryPage,
        LaundryRole.driver: DriverLaundryPage,
        LaundryRole.pressing: PressingLaundryPage,
        LaundryRole.admin: LaundryPage,
      };
      for (final entry in types.entries) {
        await tester.tap(find.byType(DropdownButtonFormField<LaundryRole>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key.label).last);
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('resident creates, reviews history and deletes a request', (
    tester,
  ) async {
    await open(
      tester,
      ResidentLaundryPage(
        residentId: 1,
        residentName: 'Ahmed',
        repository: repository,
      ),
    );
    await tester.tap(find.text('Nouvelle demande'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Lavage');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved = (await repository.getAll()).single;
    expect(saved.residentId, 1);
    expect(saved.price, 0);
    expect(saved.priceConfirmed, isFalse);
    expect(find.textContaining('DT'), findsNothing);
    await tester.ensureVisible(find.text('Historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Création → Déposé'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(await repository.getAll(), isEmpty);
    expect(find.textContaining('aucune demande'), findsOneWidget);
  });

  testWidgets(
    'resident never sees an administrator quote, including in dialogs and history',
    (tester) async {
      await repository.add(
        item(
          'QUOTED',
          LaundryStatus.deposited,
        ).copyWith(price: 87.65, priceConfirmed: true),
      );
      await open(
        tester,
        ResidentLaundryPage(
          residentId: 1,
          residentName: 'Ahmed',
          repository: repository,
        ),
      );
      expect(find.textContaining('DT'), findsNothing);
      expect(find.textContaining('87.65'), findsNothing);
      await tester.ensureVisible(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Prix'), findsNothing);
      expect(find.textContaining('DT'), findsNothing);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Historique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();
      expect(find.textContaining('DT'), findsNothing);
      expect(find.textContaining('87.65'), findsNothing);
    },
  );

  testWidgets('administrator can explicitly confirm a free service', (
    tester,
  ) async {
    await repository.addForResident(
      item('FREE', LaundryStatus.deposited),
      residentId: 1,
    );
    await open(tester, LaundryPage(repository: repository));
    expect(find.text('À tarifer'), findsOneWidget);
    await tester.ensureVisible(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(3), '0');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved = (await repository.getById('FREE'))!;
    expect(saved.price, 0);
    expect(saved.priceConfirmed, isTrue);
    expect(find.text('0.00 DT'), findsOneWidget);
  });

  testWidgets('driver can cancel delivery and keep the ready request', (
    tester,
  ) async {
    await repository.add(item('READY', LaundryStatus.ready));
    await open(tester, DriverLaundryPage(repository: repository));
    await tester.ensureVisible(find.text('Marquer comme livré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme livré'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect((await repository.getById('READY'))!.status, LaundryStatus.ready);
    expect((await repository.getStatusHistory('READY')).length, 1);
  });

  testWidgets(
    'pressing prioritizes older deposits and search narrows the queue',
    (tester) async {
      await repository.add(
        LaundryItem(
          id: 'NEW',
          residentName: 'Ahmed',
          serviceType: 'Lavage',
          status: LaundryStatus.deposited,
          price: 0,
          createdAt: DateTime.utc(2026, 10, 15),
        ),
      );
      await repository.add(
        LaundryItem(
          id: 'OLD',
          residentName: 'Sara',
          serviceType: 'Repassage',
          status: LaundryStatus.deposited,
          price: 0,
          createdAt: DateTime.utc(2026, 10, 14),
        ),
      );
      await open(tester, PressingLaundryPage(repository: repository));
      expect(find.text('Commande #OLD'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sara');
      await tester.pumpAndSettle();
      expect(find.text('Commande #OLD'), findsOneWidget);
      expect(find.text('Commande #NEW'), findsNothing);
    },
  );

  testWidgets(
    'administrator excludes unconfirmed amounts from totals and can filter them',
    (tester) async {
      await repository.add(
        item(
          'CONFIRMED',
          LaundryStatus.deposited,
        ).copyWith(price: 25, priceConfirmed: true),
      );
      await repository.add(
        item('PENDING', LaundryStatus.deposited).copyWith(price: 100),
      );
      await open(tester, LaundryPage(repository: repository));
      expect(find.text('Total des tarifs validés : 25.00 DT'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Tarifs à valider'));
      await tester.pumpAndSettle();
      expect(find.text('#PENDING'), findsOneWidget);
      expect(find.text('#CONFIRMED'), findsNothing);
    },
  );

  testWidgets('database failure shows retry and recovers', (tester) async {
    final db = MemoryDatabase();
    var fail = true;
    final recoverable = LaundryRepository(
      databaseProvider: () async {
        if (fail) throw StateError('Unavailable database');
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
  });
}
