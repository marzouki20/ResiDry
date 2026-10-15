import 'package:ttttttteee/core/validation/tunisian_phone.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/auth/presentation/auth_screen.dart';
import 'package:ttttttteee/models/user.dart';

void main() {
  test('national and international Tunisian formats reject invalid prefixes',
      () {
    for (final prefix in ['2', '3', '4', '5', '7', '9']) {
      final number = '${prefix}1234567';
      expect(TunisianPhone.isValidNational(number), isTrue);
      expect(TunisianPhone.toInternational(number), '+216$number');
      expect(TunisianPhone.isValidInternational('+216$number'), isTrue);
    }
    for (final number in [
      '',
      '01234567',
      '11234567',
      '61234567',
      '81234567',
      '5512345',
      '551234567',
      '55abc456',
      '+21655123456',
      '55 123 456'
    ]) {
      expect(TunisianPhone.isValidNational(number), isFalse, reason: number);
    }
    expect(TunisianPhone.isValidInternational('+3312345678'), isFalse);
    expect(TunisianPhone.isValidInternational('+21611234567'), isFalse);
  });
  test(
      'account persistence rejects invalid driver phone before database access',
      () async {
    for (final phone in [null, '+21611234567', '55123456']) {
      await expectLater(
          AppDatabase.instance.createUser({
            'role': 'Livreur',
            'phone': phone,
          }),
          throwsArgumentError);
    }
  });
  test('user phone survives map serialization', () {
    const user = User(
        name: 'Driver',
        email: 'driver@test.tn',
        password: 'test123',
        role: 'Livreur',
        phone: '+21655123456');
    expect(User.fromMap(user.toMap()).phone, '+21655123456');
    final old = user.toMap()..remove('phone');
    expect(User.fromMap(old).phone, isNull);
  });
  testWidgets('phone is required only for drivers and accepts eight digits',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    final phone = find.byKey(const ValueKey('driver-phone-field'));
    expect(phone, findsNothing);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver').last);
    await tester.pumpAndSettle();
    expect(phone, findsOneWidget);
    expect(tester.widget<TextField>(phone).decoration!.prefixText, '+216 ');
    await tester.ensureVisible(find.text('Create account').first);
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Enter 8 digits starting with 2, 3, 4, 5, 7 or 9. Example: 55123456.'),
        findsOneWidget);
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '11123456');
    await tester.ensureVisible(find.text('Create account').first);
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Enter 8 digits starting with 2, 3, 4, 5, 7 or 9. Example: 55123456.'),
        findsOneWidget);
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '55123456');
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Enter 8 digits starting with 2, 3, 4, 5, 7 or 9. Example: 55123456.'),
        findsNothing);
    await tester.enterText(phone, '5512345679');
    expect(tester.widget<TextField>(phone).controller!.text, '55123456');
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resident').last);
    await tester.pumpAndSettle();
    expect(phone, findsNothing);
  });
}
