import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/presentation/laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/driver_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/pressing_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/pages/resident_laundry_page.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_design.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/memory_database.dart';
import 'support/test_accounts.dart';

void main() {
  late LaundryRepository repository;
  setUp(() async {
    final db = MemoryDatabase();
    db.rows['users']!.addAll(testAccounts.map((user) => user.toMap()));
    repository = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
    for (final status in LaundryStatus.values) {
      await repository.add(
        LaundryItem(
          id: 'LINGE-${status.name}-0001',
          residentId: testResident.id,
          residentName: testResident.name,
          serviceType: 'Lavage et repassage',
          status: status,
          price: 15,
          priceConfirmed: true,
          createdAt: DateTime.utc(2026, 10, 24, 9),
        ),
      );
    }
  });

  Widget page(String role) => switch (role) {
    'admin' => LaundryPage(repository: repository, currentUser: testAdmin),
    'resident' => ResidentLaundryPage(
      repository: repository,
      currentUser: testResident,
    ),
    'pressing' => Scaffold(
      appBar: AppBar(title: const Text('Pressing')),
      body: PressingLaundryPage(
        repository: repository,
        currentUser: testPressing,
      ),
    ),
    _ => Scaffold(
      appBar: AppBar(title: const Text('Livraison')),
      body: DriverLaundryPage(repository: repository, currentUser: testDriver),
    ),
  };

  Widget app(String role, Locale locale, {double scale = 1, Key? captureKey}) =>
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: page(role),
        ),
      );

  for (final role in ['admin', 'resident', 'pressing', 'driver']) {
    for (final language in ['fr', 'en', 'ar']) {
      testWidgets(
        '$role: $language layout supports compact width and enlarged text',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(app(role, Locale(language), scale: 1.6));
          await tester.pumpAndSettle();
          final card = find.byWidgetPredicate(
            (widget) =>
                widget is LaundryRequestCard &&
                widget.item.status ==
                    (role == 'driver'
                        ? LaundryStatus.ready
                        : LaundryStatus.deposited),
          );
          await tester.scrollUntilVisible(
            card,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final context = tester.element(card);
          expect(
            Directionality.of(context),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(
            find.text(
              laundryStatusText(
                context,
                role == 'driver'
                    ? LaundryStatus.ready
                    : LaundryStatus.deposited,
              ),
            ),
            findsWidgets,
          );
          if (role == 'resident' || role == 'driver') {
            expect(find.textContaining('DT'), findsNothing);
          }
          if (role == 'driver' || role == 'pressing') {
            expect(find.byIcon(Icons.edit_outlined), findsNothing);
            expect(find.byIcon(Icons.delete_outline), findsNothing);
          }
        },
      );
    }
  }

  for (final role in ['admin', 'resident']) {
    for (final language in ['fr', 'en', 'ar']) {
      testWidgets(
        '$role form: $language fits enlarged text and an open keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpWidget(app(role, Locale(language), scale: 1.6));
          await tester.pumpAndSettle();
          final create = role == 'admin'
              ? find.byType(FloatingActionButton)
              : find.byType(FilledButton).first;
          await tester.ensureVisible(create);
          await tester.tap(create);
          await tester.pumpAndSettle();
          final fields = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          );
          expect(fields, findsNWidgets(4));
          await tester.ensureVisible(fields.first);
          await tester.showKeyboard(fields.first);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (role == 'resident') {
            expect(find.textContaining('DT'), findsNothing);
          }
        },
      );
    }
  }

  testWidgets('wide admin keeps its cards readable without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app('admin', const Locale('fr')));
    await tester.pumpAndSettle();
    expect(find.byType(LaundrySectionHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture local design previews', (tester) async {
    final previousShadows = debugDisableShadows;
    final previousHighlight = FocusManager.instance.highlightStrategy;
    debugDisableShadows = false;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    try {
      // Flutter's normal widget-test font is Ahem. Load the SDK fonts only for
      // optional visual previews, without adding fonts or dependencies to the app.
      await tester.runAsync(() async {
        final configFile = File('.dart_tool/package_config.json');
        final config =
            jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
        final packages = config['packages'] as List<dynamic>;
        final flutter = packages.cast<Map<String, dynamic>>().firstWhere(
          (p) => p['name'] == 'flutter',
        );
        final packageDir = Directory.fromUri(
          configFile.absolute.uri.resolve(flutter['rootUri'] as String),
        );
        final fontDir =
            '${packageDir.parent.parent.path}/bin/cache/artifacts/material_fonts';
        final roboto = FontLoader('Roboto');
        for (final name in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
          roboto.addFont(
            File('$fontDir/$name').readAsBytes().then(ByteData.sublistView),
          );
        }
        await roboto.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File('$fontDir/materialicons-regular.otf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        await icons.load();
      });
      tester.view.physicalSize = const Size(390, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> capture(GlobalKey key, String filename) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final picture = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File('.dart_tool/$filename.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            picture.dispose();
          }
        });
      }

      for (final role in ['admin', 'resident', 'pressing', 'driver']) {
        final captureKey = GlobalKey();
        await tester.pumpWidget(
          app(role, const Locale('fr'), captureKey: captureKey),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(captureKey, 'laundry_${role}_preview');
      }
      await repository
          .forUser(testPressing)
          .transitionStatus(
            'LINGE-deposited-0001',
            expectedStatus: LaundryStatus.deposited,
            newStatus: LaundryStatus.processing,
          );
      final historyKey = GlobalKey();
      await tester.pumpWidget(
        app('resident', const Locale('fr'), captureKey: historyKey),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Historique').first, 180);
      await tester.ensureVisible(find.text('Historique').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historique').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(historyKey, 'laundry_history_preview');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final formKey = GlobalKey();
      await tester.pumpWidget(
        app('resident', const Locale('fr'), captureKey: formKey),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nouvelle demande'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Champ obligatoire'), findsOneWidget);
      await capture(formKey, 'laundry_validation_preview');
    } finally {
      debugDisableShadows = previousShadows;
      FocusManager.instance.highlightStrategy = previousHighlight;
    }
  }, skip: !const bool.fromEnvironment('LAUNDRY_CAPTURE_PREVIEWS'));
}
