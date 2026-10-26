import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../database/supabase_connection.dart';
import '../../casiers/presentation/admin/admin_interface.dart';
import '../../casiers/presentation/resident/resident_interface.dart';
import '../../laundry_companies/presentation/home_page.dart';
import '../../orders/presentation/home_page.dart';
import '../data/auth_session_store.dart';
import '../data/google_auth_service.dart';
import 'auth_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/verify_email_page.dart';
import 'widgets/auth_footer.dart';
import 'widgets/auth_illustration.dart';
import 'widgets/hcaptcha_challenge.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.sessionStore});

  final AuthSessionStore? sessionStore;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final _sessionStore = widget.sessionStore ?? AuthSessionStore();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _resetPasswordController = TextEditingController();

  AuthPage _page = AuthPage.signIn;
  String? _pendingEmail;
  String _pendingRole = 'Résident';
  bool _pendingRememberMe = false;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  bool _isRestoringSession = true;
  bool _rememberMe = false;
  String _selectedRole = 'Résident';

  @override
  void initState() {
    super.initState();
    _restoreRememberedSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    _resetPasswordController.dispose();
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
        child: _isRestoringSession
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
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
          onGoogleSignIn: _continueWithGoogle,
          rememberMe: _rememberMe,
          onRememberMeChanged: (value) => setState(() => _rememberMe = value),
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
          onGoogleSignIn: _continueWithGoogle,
          isSubmitting: _isSubmitting,
        );
      case AuthPage.forgotPassword:
        return ForgotPasswordPage(
          key: const ValueKey('forgot-password'),
          emailController: _emailController,
          isSubmitting: _isSubmitting,
          onSendResetCode: _sendPasswordReset,
          onBackToSignIn: () => _showPage(AuthPage.signIn),
        );
      case AuthPage.verifyEmail:
        return VerifyEmailPage(
          key: const ValueKey('verify-email'),
          email: _pendingEmail ?? '',
          codeController: _verificationCodeController,
          isSubmitting: _isSubmitting,
          onVerify: _verifySignupEmail,
          onResend: _resendSignupCode,
        );
      case AuthPage.resetPassword:
        return ResetPasswordPage(
          key: const ValueKey('reset-password'),
          email: _pendingEmail ?? '',
          codeController: _verificationCodeController,
          passwordController: _resetPasswordController,
          passwordVisible: _passwordVisible,
          isSubmitting: _isSubmitting,
          onTogglePassword: () =>
              setState(() => _passwordVisible = !_passwordVisible),
          onResetPassword: _resetPassword,
          onResendCode: _sendPasswordReset,
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
    if (!_isValidEmail(email)) {
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
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.authStorage.setRememberMe(_rememberMe);
      final response = await SupabaseConnection.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': _selectedRole},
        captchaToken: captchaToken,
      );
      if (response.session == null) {
        _pendingEmail = email;
        _pendingRole = _selectedRole;
        _pendingRememberMe = _rememberMe;
        _verificationCodeController.clear();
        _showPage(AuthPage.verifyEmail);
        _showMessage(
          'We sent a verification code to $email. Enter it to finish creating your account.',
        );
        return;
      }

      await _updateRememberedSession(email, _rememberMe);
      if (mounted) {
        _openHome(name, _selectedRole);
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message);
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
    final rememberMe = _rememberMe;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.authStorage.setRememberMe(rememberMe);
      final response = await SupabaseConnection.client.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
      final user = response.user;
      if (user == null) {
        _showMessage('Could not sign in. Please try again.');
        return;
      }

      if (mounted) {
        await _updateRememberedSession(email, rememberMe);
      }

      if (mounted) {
        _openHome(_userName(user, email), _userRole(user));
      }
    } on AuthException catch (error) {
      if (mounted) {
        if (error.code == 'email_not_confirmed') {
          _pendingEmail = email;
          _pendingRememberMe = rememberMe;
          _verificationCodeController.clear();
          _showPage(AuthPage.verifyEmail);
          _showMessage(
            'Verify your email with the code already sent, or request a new code.',
          );
        } else {
          _showMessage(error.message);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifySignupEmail() async {
    final email = _pendingEmail;
    final token = _verificationCodeController.text.trim();
    if (email == null) {
      _showMessage(
        'Start account creation again to request a verification code.',
      );
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(token)) {
      _showMessage('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.authStorage.setRememberMe(_pendingRememberMe);
      final response = await SupabaseConnection.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
        captchaToken: captchaToken,
      );
      final user = response.user;
      if (user == null) {
        _showMessage('Email verification did not return an account session.');
        return;
      }

      await _updateRememberedSession(email, _pendingRememberMe);
      if (mounted) {
        _openHome(
          _userName(user, email),
          _userRole(user, fallback: _pendingRole),
        );
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendSignupCode() async {
    final email = _pendingEmail;
    if (email == null) return;

    setState(() => _isSubmitting = true);
    try {
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.client.auth.resend(
        type: OtpType.signup,
        email: email,
        captchaToken: captchaToken,
      );
      if (mounted) _showMessage('A new verification code was sent to $email.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.client.auth.resetPasswordForEmail(
        email,
        captchaToken: captchaToken,
      );
      _pendingEmail = email;
      _verificationCodeController.clear();
      _resetPasswordController.clear();
      _showPage(AuthPage.resetPassword);
      _showMessage('If an account exists, a password reset code was sent.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _pendingEmail;
    final token = _verificationCodeController.text.trim();
    final password = _resetPasswordController.text;
    if (email == null) {
      _showMessage('Request a password reset code first.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(token)) {
      _showMessage('Enter the 6-digit code from your email.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Your password must be at least 6 characters.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      await SupabaseConnection.authStorage.setRememberMe(false);
      final response = await SupabaseConnection.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
        captchaToken: captchaToken,
      );
      if (response.user == null) {
        _showMessage('The reset code could not be verified.');
        return;
      }

      await SupabaseConnection.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await SupabaseConnection.client.auth.signOut();
      await SupabaseConnection.authStorage.setRememberMe(false);
      await _forgetRememberedSession();
      _pendingEmail = null;
      _showPage(AuthPage.signIn);
      _showMessage('Password updated. Sign in with your new password.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (!GoogleAuthService.isConfigured) {
      _showMessage(
        'Google sign-in needs a web OAuth client ID. See the setup instructions in README.md.',
      );
      return;
    }
    if (_page == AuthPage.signUp && !_acceptedTerms) {
      _showMessage('Please accept the terms to create an account.');
      return;
    }

    final pageAtStart = _page;
    final roleAtStart = _selectedRole;
    final rememberMeAtStart = _rememberMe;
    setState(() => _isSubmitting = true);
    try {
      final account = await GoogleAuthService.signIn();
      final email = account.email.trim().toLowerCase();
      if (email.isEmpty) {
        _showMessage('Google did not provide an email address.');
        return;
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        _showMessage('Google did not provide an authentication token.');
        return;
      }

      final captchaToken = await _requestCaptchaToken();
      if (captchaToken == null) return;
      final rememberSession =
          pageAtStart == AuthPage.signIn && rememberMeAtStart;
      await SupabaseConnection.authStorage.setRememberMe(rememberSession);
      final response = await SupabaseConnection.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        captchaToken: captchaToken,
      );
      final user = response.user;
      if (user == null) {
        _showMessage('Could not sign in with Google. Please try again.');
        return;
      }

      final displayName = account.displayName?.trim();
      final name = _userName(
        user,
        displayName == null || displayName.isEmpty
            ? email.split('@').first
            : displayName,
      );
      final role = _userRole(
        user,
        fallback: pageAtStart == AuthPage.signUp ? roleAtStart : 'Résident',
      );
      await SupabaseConnection.client.auth.updateUser(
        UserAttributes(data: {'name': name, 'role': role}),
      );

      await _updateRememberedSession(
        email,
        pageAtStart == AuthPage.signIn && rememberMeAtStart,
      );
      if (mounted) {
        _openHome(name, role);
      }
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _showMessage('Google sign-in failed: ${error.code.name}.');
      }
    } on UnsupportedError catch (error) {
      _showMessage(error.message ?? 'Google sign-in is unavailable.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _restoreRememberedSession() async {
    try {
      final email = await _sessionStore.getRememberedEmail();
      if (email != null) {
        final user = SupabaseConnection.client.auth.currentUser;
        if (user == null || user.email?.toLowerCase() != email.toLowerCase()) {
          await _forgetRememberedSession();
        } else if (mounted) {
          _openHome(_userName(user, email), _userRole(user));
        }
      }
    } on AuthException catch (error) {
      _showMessage('Could not restore your saved session: ${error.message}');
    } on PlatformException {
      _showMessage('Could not read your saved sign-in preference.');
    } on MissingPluginException {
      _showMessage('Saved sign-in storage is unavailable on this device.');
    } finally {
      if (mounted) {
        setState(() => _isRestoringSession = false);
      }
    }
  }

  Future<void> _rememberEmail(String email) async {
    try {
      await _sessionStore.rememberEmail(email);
    } on PlatformException {
      _showMessage('You are signed in, but Remember me could not be saved.');
    } on MissingPluginException {
      _showMessage(
        'You are signed in, but Remember me storage is unavailable.',
      );
    }
  }

  Future<void> _forgetRememberedSession() async {
    try {
      await _sessionStore.forgetEmail();
    } on PlatformException {
      _showMessage('Could not clear the saved sign-in preference.');
    } on MissingPluginException {
      _showMessage('Saved sign-in storage is unavailable on this device.');
    }
  }

  Future<void> _updateRememberedSession(String email, bool remember) async {
    if (remember) {
      await _rememberEmail(email);
    } else {
      await _forgetRememberedSession();
    }
  }

  void _openHome(String name, String role) {
    final navigator = Navigator.of(context);
    void onLogout() => _signOut(navigator);
    final homePage = role == 'Livreur'
        ? OrdersHomePage(userName: name, onLogout: onLogout)
        : role == 'Administrateur'
        ? AdminInterface(userName: name, onLogout: onLogout)
        : role == 'Résident'
        ? ResidentInterface(userName: name, onLogout: onLogout)
        : LaundryCompanyHomePage(
            userName: name,
            userRole: role,
            onLogout: onLogout,
          );

    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => homePage),
    );
  }

  Future<void> _signOut(NavigatorState navigator) async {
    var signOutMessage = '';
    try {
      await _sessionStore.forgetEmail();
    } on PlatformException {
      signOutMessage = 'Could not clear the saved sign-in preference.';
    } on MissingPluginException {
      signOutMessage = 'Saved sign-in storage is unavailable on this device.';
    }

    try {
      await SupabaseConnection.client.auth.signOut();
      await SupabaseConnection.authStorage.setRememberMe(false);
    } on AuthException catch (error) {
      signOutMessage = 'Could not sign out: ${error.message}';
    }

    try {
      await GoogleAuthService.signOut();
    } on GoogleSignInException catch (error) {
      signOutMessage = 'Google sign-out failed: ${error.code.name}.';
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (_) => false,
    );
    if (signOutMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.maybeOf(navigator.context)
            ?.showSnackBar(SnackBar(content: Text(signOutMessage)));
      });
    }
  }

  String _userName(User user, String fallback) {
    final name = user.userMetadata?['name'];
    return name is String && name.trim().isNotEmpty ? name : fallback;
  }

  String _userRole(User user, {String fallback = 'Résident'}) {
    final role = user.userMetadata?['role'];
    return role is String && role.trim().isNotEmpty ? role : fallback;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<String?> _requestCaptchaToken() async {
    try {
      return await HCaptchaChallenge.show(context);
    } on StateError catch (error) {
      _showMessage(error.message.toString());
      return null;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
