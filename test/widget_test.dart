import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ttttttteee/features/auth/data/auth_session_store.dart';
import 'package:ttttttteee/features/auth/presentation/auth_screen.dart';

class _MemoryAuthSessionStore extends AuthSessionStore {
  String? _email;

  @override
  Future<String?> getRememberedEmail() async => _email;

  @override
  Future<void> rememberEmail(String email) async {
    _email = email;
  }

  @override
  Future<void> forgetEmail() async {
    _email = null;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('auth screens navigate between sign in, reset, and sign up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(sessionStore: _MemoryAuthSessionStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Send reset code'), findsOneWidget);

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

  testWidgets('Google sign-in reports missing OAuth configuration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(sessionStore: _MemoryAuthSessionStore())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(
      find.textContaining('Google sign-in needs a web OAuth client ID'),
      findsOneWidget,
    );
  });
}
