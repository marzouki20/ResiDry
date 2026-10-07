import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../database/database.dart';
import '../../../models/user.dart';
import '../../casiers/presentation/admin/admin_interface.dart';
import '../../lockers/presentation/home_page.dart';
import '../../orders/presentation/home_page.dart';
import '../../residents/presentation/residents_home_page.dart';
import 'auth_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_illustration.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthPage _page = AuthPage.signIn;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String _selectedRole = 'Résident';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                        const AuthIllustration(),
                        const SizedBox(height: 30),
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
          emailController: _emailController,
          passwordController: _passwordController,
          onSignIn: _signIn,
          isSubmitting: _isSubmitting,
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
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
          onSignUp: _signUp,
          isSubmitting: _isSubmitting,
        );
      case AuthPage.forgotPassword:
        return ForgotPasswordPage(
          key: const ValueKey('forgot-password'),
          onBackToSignIn: () => _showPage(AuthPage.signIn),
        );
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in your name, email, and password.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Your password must be at least 6 characters.');
      return;
    }
    if (!_acceptedTerms) {
      _showMessage('Please accept the terms to create an account.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final database = AppDatabase.instance;
      if (await database.findUserByEmail(email) != null) {
        _showMessage('An account with this email already exists.');
        return;
      }

      final user = User(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
      );
      await database.createUser(user.toMap());
      if (mounted) {
        _openHome(name, _selectedRole);
      }
    } on DatabaseException {
      if (mounted) {
        _showMessage('Could not create your account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userMap = await AppDatabase.instance.findUserByEmail(email);
      if (userMap == null) {
        _showMessage('No account was found with this email.');
        return;
      }

      final user = User.fromMap(userMap);
      if (user.password != password) {
        _showMessage('The password is incorrect.');
        return;
      }

      if (mounted) {
        _openHome(user.name, user.role);
      }
    } on DatabaseException {
      if (mounted) {
        _showMessage('Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openHome(String name, String role) {
    final homePage = role == 'Livreur'
        ? OrdersHomePage(userName: name)
        : role == 'Administrateur'
        ? AdminInterface(userName: name)
        : role == 'Résident'
        ? ResidentsHomePage(userName: name)
        : HomePage(userName: name, userRole: role);

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => homePage));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
