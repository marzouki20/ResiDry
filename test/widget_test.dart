import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/app.dart';

void main() {
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

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
  });
}
