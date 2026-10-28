import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/core/theme/app_theme.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_history_dialog.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_history_sheet.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/memory_database.dart';
import 'support/test_accounts.dart';

void main() {
  for (final language in ['fr', 'en', 'ar']) {
    testWidgets(
      'history uses central actor names and fits compact $language with large text',
      (tester) async {
        final db = MemoryDatabase();
        db.rows['users']!.addAll(testAccounts.map((u) => u.toMap()));
        final admin = LaundryRepository(
          currentUser: testAdmin,
          databaseProvider: () async => db,
        );
        final item = LaundryItem(
          id: 'TRACE-001',
          residentId: 1,
          residentName: '',
          serviceType: 'Lavage',
          status: LaundryStatus.deposited,
          price: 0,
        );
        await admin.add(item);
        await admin
            .forUser(testPressing)
            .transitionStatus(
              item.id,
              expectedStatus: LaundryStatus.deposited,
              newStatus: LaundryStatus.processing,
            );
        await db.update(
          'users',
          {'name': 'Atelier actualisé'},
          where: 'id = ?',
          whereArgs: [7],
        );
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
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showLaundryHistory(
                    context,
                    admin.forUser(testResident),
                    item,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(LaundryHistorySheet), findsOneWidget);
        final name = find.text('Atelier actualisé');
        await tester.ensureVisible(name);
        await tester.pumpAndSettle();
        expect(name, findsOneWidget);
        expect(
          Directionality.of(tester.element(name)),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.textContaining('DT'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
