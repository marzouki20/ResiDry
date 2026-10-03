import 'package:flutter/material.dart';

import 'auth_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/brand_mark.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthPage _page = AuthPage.signIn;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;

  void _showPage(AuthPage page) {
    setState(() {
      _page = page;
      _passwordVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        BrandMark(
                          onTap: () => _showPage(AuthPage.signIn),
                        ),
                        const SizedBox(height: 42),
                        const AuthIllustration(),
                        const SizedBox(height: 34),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _buildPage(),
                        ),
                        const SizedBox(height: 28),
                        AuthFooter(
                          page: _page,
                          onSignIn: () => _showPage(AuthPage.signIn),
                          onSignUp: () => _showPage(AuthPage.signUp),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case AuthPage.signIn:
        return SignInPage(
          key: const ValueKey('sign-in'),
          passwordVisible: _passwordVisible,
          onTogglePassword: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          onForgotPassword: () => _showPage(AuthPage.forgotPassword),
        );
      case AuthPage.signUp:
        return SignUpPage(
          key: const ValueKey('sign-up'),
          passwordVisible: _passwordVisible,
          acceptedTerms: _acceptedTerms,
          onTogglePassword: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          onToggleTerms: (value) =>
              setState(() => _acceptedTerms = value ?? false),
        );
      case AuthPage.forgotPassword:
        return ForgotPasswordPage(
          key: const ValueKey('forgot-password'),
          onBackToSignIn: () => _showPage(AuthPage.signIn),
        );
    }
  }
}
