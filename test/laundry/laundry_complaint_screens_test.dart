import 'support/laundry_rows.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_complaint.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_complaint_details_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/laundry_complaints_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/complaint_form.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/complaint_decision_dialog.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/complaint_fixtures.dart';
import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  late Database db;
  late LaundryRepository admin, resident;
  const description =
      'Une chemise blanche est déchirée après réception du linge.';
  setUp(() async {
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
    resident = admin.forUser(testResident);
    await resident.saveRequest(
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
            id: 'LINE',
            garment: 'Chemise blanche',
            serviceId: 'washing',
            quantity: 3,
          ),
        ],
      ),
    );
    final pressing = admin.forUser(testPressing);
    await pressing.transitionStatus(
      'R1',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
    );
    await pressing.transitionStatus(
      'R1',
      expectedStatus: LaundryStatus.processing,
      newStatus: LaundryStatus.ready,
    );
    await admin
        .forUser(testDriver)
        .transitionStatus(
          'R1',
          expectedStatus: LaundryStatus.ready,
          newStatus: LaundryStatus.delivered,
        );
  });
  tearDown(() async => db.close());
  Future<void> settle(WidgetTester tester) async {
    for (var n = 0; n < 180; n++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
    fail('SQLite UI did not settle');
  }

  Future<void> open(
    WidgetTester tester,
    Widget page, {
    String language = 'fr',
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        locale: Locale(language),
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
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
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<String> createCase(WidgetTester tester) async =>
      (await tester.runAsync(
        () => resident.createComplaint(
          laundryId: 'R1',
          reason: ComplaintReason.damaged,
          description: description,
        ),
      ))!;

  testWidgets(
    'resident submits photos admin resolves and resident sees actual decision and unread indicator',
    (tester) async {
      final photo = await tester.runAsync(complaintTestPhoto);
      await open(
        tester,
        LaundryComplaintsPage(
          repository: resident,
          laundryId: 'R1',
          pickPhoto: (_) async => photo,
        ),
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Nouvelle réclamation'),
      );
      expect(find.byType(ComplaintForm), findsOneWidget);
      await tap(tester, find.widgetWithText(FilledButton, 'Envoyer'));
      expect(
        find.text('Entre 10 et 2000 caractères sont nécessaires.'),
        findsOneWidget,
      );
      expect(
        (await tester.runAsync(() => resident.getComplaintInbox()))!.complaints,
        isEmpty,
      );
      await tester.enterText(find.byType(TextFormField), description);
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(OutlinedButton, 'Galerie'));
      expect(find.byType(Image), findsOneWidget);
      await tap(tester, find.widgetWithText(FilledButton, 'Envoyer'));
      expect(find.byType(ComplaintForm), findsNothing);
      expect(find.byType(LaundryComplaintDetailsPage), findsOneWidget);
      final cases = await tester.runAsync(() => resident.getComplaintInbox());
      final id = cases!.complaints.single.id;
      expect(
        (await tester.runAsync(() => resident.getComplaintDetails(id)))!
            .photos
            .single
            .bytes,
        photo!.bytes,
      );
      expect(
        find.widgetWithText(FilledButton, 'Prendre en charge'),
        findsNothing,
      );
      await open(tester, LaundryComplaintsPage(repository: admin));
      await tap(tester, find.text('Vêtement endommagé'));
      await tap(tester, find.widgetWithText(FilledButton, 'Prendre en charge'));
      expect(
        (await tester.runAsync(() => admin.getComplaintDetails(id)))!
            .complaint
            .status,
        ComplaintStatus.reviewing,
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Rendre une décision'),
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirmer la décision'),
      );
      expect(
        find.text('Entre 10 et 2000 caractères sont nécessaires.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'La chemise a été réparée et la solution expliquée au résident.',
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirmer la décision'),
      );
      expect(find.byType(ComplaintDecisionDialog), findsNothing);
      expect(
        (await tester.runAsync(() => admin.getComplaintDetails(id)))!
            .complaint
            .status,
        ComplaintStatus.resolved,
      );
      expect(
        (await tester.runAsync(() => resident.getComplaintInbox()))!
            .unreadCount,
        1,
      );
      await open(tester, LaundryComplaintsPage(repository: resident));
      expect(find.text('Nouvelle réponse'), findsOneWidget);
      await tap(tester, find.text('Vêtement endommagé'));
      expect(
        (await tester.runAsync(() => resident.getComplaintInbox()))!
            .unreadCount,
        0,
      );
      expect(
        (await tester.runAsync(() => resident.getComplaintDetails(id)))!.events
            .map((e) => e.actorId),
        [1, 9, 9],
      );
      expect(
        find.widgetWithText(FilledButton, 'Rendre une décision'),
        findsNothing,
      );
      expect(
        (await tester.runAsync(() => admin.getById('R1')))!.status,
        LaundryStatus.delivered,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'photo cancellation limit removal and form cancellation do not create records',
    (tester) async {
      final photo = await tester.runAsync(complaintTestPhoto);
      var cancelled = true;
      await open(
        tester,
        LaundryComplaintsPage(
          repository: resident,
          laundryId: 'R1',
          pickPhoto: (_) async => cancelled ? null : photo,
        ),
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Nouvelle réclamation'),
      );
      await tap(tester, find.widgetWithText(OutlinedButton, 'Galerie'));
      expect(find.byType(Image), findsNothing);
      cancelled = false;
      for (var i = 0; i < 3; i++) {
        await tap(tester, find.widgetWithText(OutlinedButton, 'Galerie'));
      }
      expect(find.byType(Image), findsNWidgets(3));
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Galerie'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, find.byTooltip('Retirer la photo').first);
      expect(find.byType(Image), findsNWidgets(2));
      await tap(tester, find.widgetWithText(OutlinedButton, 'Appareil photo'));
      expect(find.byType(Image), findsNWidgets(3));
      await tap(tester, find.widgetWithText(TextButton, 'Annuler'));
      expect(
        (await tester.runAsync(() => resident.getComplaintInbox()))!.complaints,
        isEmpty,
      );
      expect(
        await tester.runAsync(
          () => readLaundryRows(db, 'laundry_complaint_attachments'),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'resident entry on delivered request opens complaint form with the same authenticated owner',
    (tester) async {
      await open(tester, ResidentLaundryPage(repository: resident));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Livrées'));
      await tap(tester, find.text('Réclamer'));
      expect(find.byType(LaundryComplaintsPage), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Nouvelle réclamation'),
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.textContaining('DT'), findsNothing);
      await tap(tester, find.widgetWithText(TextButton, 'Annuler'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'admin entry reviews a case and can reject it with a visible reason',
    (tester) async {
      final id = await createCase(tester);
      await tester.runAsync(
        () => admin.advanceComplaint(
          id,
          expectedRevision: 1,
          newStatus: ComplaintStatus.reviewing,
        ),
      );
      await open(tester, LaundryPage(repository: admin));
      await tap(tester, find.text('Réclamations'));
      await tap(tester, find.text('Vêtement endommagé'));
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Rendre une décision'),
      );
      await tap(tester, find.byType(DropdownButtonFormField<ComplaintStatus>));
      await tap(tester, find.text('Refusée').last);
      await tester.enterText(
        find.byType(TextFormField),
        'Le problème décrit ne peut pas être confirmé après examen.',
      );
      await tap(
        tester,
        find.widgetWithText(FilledButton, 'Confirmer la décision'),
      );
      final details = await tester.runAsync(
        () => resident.getComplaintDetails(id),
      );
      expect(details!.complaint.status, ComplaintStatus.rejected);
      expect(details.complaint.decisionReason, contains('examen'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final language in ['fr', 'en', 'ar']) {
    testWidgets(
      'complaint list details and keyboard form fit compact $language layout',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final id = await createCase(tester);
        await open(
          tester,
          LaundryComplaintsPage(repository: resident),
          language: language,
          scale: 1.5,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await open(
          tester,
          LaundryComplaintDetailsPage(repository: resident, complaintId: id),
          language: language,
          scale: 1.5,
        );
        expect(
          Directionality.of(
            tester.element(find.byType(LaundryComplaintDetailsPage)),
          ),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await open(
          tester,
          Scaffold(
            body: ComplaintForm(repository: resident, laundryId: 'R1'),
          ),
          language: language,
          scale: 1.5,
          keyboard: 220,
        );
        await tester.enterText(find.byType(TextFormField), 'test');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'another resident cannot open complaint details or photos by guessing the ID',
    (tester) async {
      final id = await createCase(tester);
      await open(
        tester,
        LaundryComplaintDetailsPage(
          repository: admin.forUser(testOtherResident),
          complaintId: id,
        ),
      );
      expect(find.text('Dossier inaccessible'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'Prendre en charge'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
