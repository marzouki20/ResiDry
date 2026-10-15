import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttttttteee/app.dart';
import 'package:ttttttteee/core/localization/app_locale.dart';
import 'package:ttttttteee/features/auth/presentation/auth_screen.dart';

void main() {
  testWidgets('language selection switches to French and persists the choice', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppLocaleController();

    await tester.pumpWidget(OrbitApp(localeController: controller));

    expect(
      find.text('Choose your language\nChoisissez votre langue\nاختر لغتك'),
      findsOneWidget,
    );
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(controller.locale, const Locale('fr'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'fr');
  });

  testWidgets('language selection switches to Arabic with RTL layout', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppLocaleController();

    await tester.pumpWidget(OrbitApp(localeController: controller));

    await tester.ensureVisible(find.text('العربية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(controller.locale, const Locale('ar'));
    expect(
      Directionality.of(tester.element(find.byType(AuthScreen))),
      TextDirection.rtl,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_language'), 'ar');
  });

  testWidgets('auth screens navigate between sign in, reset, and sign up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrbitApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);

    await tester.ensureVisible(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.textContaining('Terms of Service'), findsOneWidget);
  });
}
