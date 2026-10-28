import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/laundry_dev_main.dart';
import 'package:ttttttteee/features/laundry/presentation/widgets/laundry_language_button.dart';

import 'support/memory_database.dart';
import 'support/test_accounts.dart';

void main() {
  late MemoryDatabase db;
  late LaundryRepository admin;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = MemoryDatabase();
    db.rows['users']!.addAll(testAccounts.map((user) => user.toMap()));
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
    );
  });

  for (final actor in [testResident, testPressing, testDriver, testAdmin]) {
    testWidgets('language selection preserves account ${actor.id}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = admin.forUser(actor);
      await tester.pumpWidget(LaundryDevApp(repository: repository));
      await tester.pumpAndSettle();
      for (final entry in {
        'Français': 'fr',
        'العربية': 'ar',
        'English': 'en',
      }.entries) {
        await tester.tap(
          find.descendant(
            of: find.byType(LaundryLanguageButton),
            matching: find.byType(OutlinedButton),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, entry.key));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(LaundryLanguageButton));
        expect(Localizations.localeOf(context).languageCode, entry.value);
        expect(
          Directionality.of(context),
          entry.value == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(
          (await SharedPreferences.getInstance()).getString('app_language'),
          entry.value,
        );
        expect((await repository.getCurrentUser()).id, actor.id);
        expect(db.rows['laundry_items'], isEmpty);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('launcher restores saved Arabic after reopening', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ar'});
    for (var launch = 0; launch < 2; launch++) {
      await tester.pumpWidget(LaundryDevApp(repository: admin));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(LaundryLanguageButton));
      expect(Localizations.localeOf(context).languageCode, 'ar');
      expect(Directionality.of(context), TextDirection.rtl);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
