import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_picker_button.dart';
import '../../../database/database.dart';
import '../../../models/user.dart';
import '../../../core/backend/backend_client.dart';
import '../../delivery_drivers/presentation/application_status_screen.dart';
import '../../../core/validation/tunisian_phone.dart';
import '../../casiers/presentation/admin/admin_interface.dart';
import '../../delivery_drivers/presentation/driver_interface.dart';
import '../../delivery_drivers/presentation/driver_onboarding_page.dart';
import '../../delivery_drivers/data/driver_profile_repository.dart';
import '../../laundry_companies/data/sample_laundry_data.dart';
import '../../laundry_companies/presentation/company_interface.dart';
import '../../residents/presentation/residents_home_page.dart';
import '../../residents/mock/residents_mock_data.dart';
import '../../lockers/presentation/home_page.dart';
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
  final _phoneController = TextEditingController();
  String? _phoneError;
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
    _phoneController.dispose();
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
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
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
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                tooltip: context.tr(
                  en: 'Change language',
                  fr: 'Changer de langue',
                  ar: 'تغيير اللغة',
                ),
                onPressed: _showLanguagePicker,
                icon: const Icon(Icons.language_rounded),
              ),
            ),
            PositionedDirectional(
              top: 4,
              start: 8,
              child: IconButton(
                tooltip: context.tr(en: 'Back', fr: 'Retour', ar: 'رجوع'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_page != AuthPage.signIn) {
                          _showPage(AuthPage.signIn);
                        } else if (!await Navigator.of(context).maybePop()) {
                          await SystemNavigator.pop();
                        }
                      },
              ),
            ),
          ],
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
          phoneController: _phoneController,
          phoneError: _phoneError,
          onPhoneChanged: (_) => setState(() => _phoneError = null),
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() {
            _selectedRole = role;
            _phoneError = null;
          }),
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
    if (_selectedRole == 'Livreur' &&
        !TunisianPhone.isValidNational(_phoneController.text)) {
      setState(() => _phoneError = context.tr(
          en: 'Enter 8 digits starting with 2, 3, 4, 5, 7 or 9. Example: 55123456.',
          fr: 'Saisissez 8 chiffres commençant par 2, 3, 4, 5, 7 ou 9. Exemple : 55123456.',
          ar: 'أدخل 8 أرقام تبدأ بـ 2 أو 3 أو 4 أو 5 أو 7 أو 9. مثال: 55123456.'));
      return;
    }
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage(context.tr(
        en: 'Please fill in your name, email, and password.',
        fr: 'Veuillez saisir votre nom, votre e-mail et votre mot de passe.',
        ar: 'يرجى إدخال الاسم والبريد الإلكتروني وكلمة المرور.',
      ));
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage(context.tr(
        en: 'Please enter a valid email address.',
        fr: 'Veuillez saisir une adresse e-mail valide.',
        ar: 'يرجى إدخال عنوان بريد إلكتروني صحيح.',
      ));
      return;
    }
    if (password.length < 8) {
      _showMessage(context.tr(
        en: 'Your password must be at least 8 characters.',
        fr: 'Le mot de passe doit contenir au moins 8 caractères.',
        ar: 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.',
      ));
      return;
    }
    if (!_acceptedTerms) {
      _showMessage(context.tr(
        en: 'Please accept the terms to create an account.',
        fr: 'Veuillez accepter les conditions pour créer un compte.',
        ar: 'يرجى الموافقة على الشروط لإنشاء الحساب.',
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (BackendClient.enabled) {
        final account = await BackendClient.authenticate('/api/auth/register', {
          'name': name,
          'email': email,
          'password': password,
          'role': BackendClient.roles[_selectedRole],
          'phone': _selectedRole == 'Livreur'
              ? TunisianPhone.toInternational(_phoneController.text)
              : null,
        });
        if (mounted) _openBackendHome(account);
        return;
      }
      final database = AppDatabase.instance;
      final existingUser = await database.findUserByEmail(email);
      if (!mounted) return;
      if (existingUser != null) {
        _showMessage(context.tr(
          en: 'An account with this email already exists.',
          fr: 'Un compte existe déjà avec cette adresse e-mail.',
          ar: 'يوجد حساب مرتبط بهذا البريد الإلكتروني.',
        ));
        return;
      }

      final user = User(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
        phone: _selectedRole == 'Livreur'
            ? TunisianPhone.toInternational(_phoneController.text)
            : null,
      );
      await database.createUser(user.toMap());
      if (_selectedRole == 'Résident') {
        final nameParts = name.split(RegExp(r'\s+'));
        await database.createResident(
          ResidentProfile(
            firstName: nameParts.first,
            lastName:
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            email: email,
            phone: '',
            residenceName: '',
            residenceAddress: '',
            city: '',
            postalCode: '',
            apartmentNumber: '',
            floor: '',
            status: 'Active',
          ),
        );
      }
      if (mounted) {
        if (_selectedRole == 'Livreur') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  DriverOnboardingPage(userName: name, userEmail: email),
            ),
          );
        } else {
          _openHome(name, _selectedRole, email: email);
        }
      }
    } on BackendException catch (error) {
      if (mounted) _showBackendError(error);
    } on DatabaseException {
      if (mounted) {
        _showMessage(context.tr(
          en: 'Could not create your account. Please try again.',
          fr: 'Impossible de créer le compte. Veuillez réessayer.',
          ar: 'تعذر إنشاء الحساب. يرجى المحاولة مرة أخرى.',
        ));
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
      _showMessage(context.tr(
        en: 'Please enter your email and password.',
        fr: 'Veuillez saisir votre e-mail et votre mot de passe.',
        ar: 'يرجى إدخال البريد الإلكتروني وكلمة المرور.',
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (BackendClient.enabled) {
        final account = await BackendClient.authenticate(
            '/api/auth/login', {'email': email, 'password': password});
        if (mounted) _openBackendHome(account);
        return;
      }
      final userMap = await AppDatabase.instance.findUserByEmail(email);
      if (!mounted) return;
      if (userMap == null) {
        _showMessage(context.tr(
          en: 'No account was found with this email.',
          fr: 'Aucun compte ne correspond à cette adresse e-mail.',
          ar: 'لم يتم العثور على حساب بهذا البريد الإلكتروني.',
        ));
        return;
      }

      final user = User.fromMap(userMap);
      if (user.password != password) {
        _showMessage(context.tr(
          en: 'The password is incorrect.',
          fr: 'Le mot de passe est incorrect.',
          ar: 'كلمة المرور غير صحيحة.',
        ));
        return;
      }

      if (user.role == 'Livreur') {
        final configured =
            await DriverProfileRepository().hasProfile(user.email);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
            builder: (_) => configured
                ? DriverInterface(userName: user.name, userEmail: user.email)
                : DriverOnboardingPage(
                    userName: user.name, userEmail: user.email)));
      } else if (mounted) {
        _openHome(user.name, user.role, email: user.email);
      }
    } on BackendException catch (error) {
      if (mounted) _showBackendError(error);
    } on DatabaseException {
      if (mounted) {
        _showMessage(context.tr(
          en: 'Could not sign in. Please try again.',
          fr: 'Impossible de se connecter. Veuillez réessayer.',
          ar: 'تعذر تسجيل الدخول. يرجى المحاولة مرة أخرى.',
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openBackendHome(Map<String, dynamic> account) {
    if (account['role'] == 'DRIVER') {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => const ApplicationStatusScreen()));
    } else {
      final role = BackendClient.roles.entries
          .firstWhere((entry) => entry.value == account['role'])
          .key;
      _openHome(account['name'] as String, role,
          email: account['email'] as String?);
    }
  }

  void _showBackendError(BackendException error) {
    if (error.code == 'email_already_registered' || error.code == 'conflict') {
      _showMessage(context.tr(
          en: 'This email is already registered or conflicts with an existing account. Choose Sign in to use your account.',
          fr: 'Cette adresse e-mail est déjà utilisée ou entre en conflit avec un compte existant. Choisissez Se connecter pour utiliser votre compte.',
          ar: 'هذا البريد مسجل بالفعل أو يتعارض مع حساب موجود. اختر تسجيل الدخول لاستخدام حسابك.'));
      return;
    }
    if (error.code == 'connection_failed') {
      _showMessage(context.tr(
          en: 'Could not reach the ResiDry server. Check that the backend is running and the phone is connected.',
          fr: 'Impossible de joindre le serveur ResiDry. Vérifiez que le backend est démarré et que le téléphone est connecté.',
          ar: 'تعذر الاتصال بخادم ريزيدراي. تحقق من تشغيل الخادم واتصال الهاتف.'));
      return;
    }
    if (error.code == 'invalid_request') {
      _showMessage(context.tr(
          en: 'The server rejected the entered information. Check your email, password and 8-digit Tunisian phone number.',
          fr: 'Le serveur a refusé les informations saisies. Vérifiez l’e-mail, le mot de passe et les 8 chiffres du numéro tunisien.',
          ar: 'رفض الخادم المعلومات المدخلة. تحقق من البريد وكلمة المرور ورقم الهاتف التونسي ذي 8 أرقام.'));
      return;
    }
    _showMessage(error.code == 'invalid_credentials'
        ? context.tr(
            en: 'Email or password is incorrect.',
            fr: 'Adresse e-mail ou mot de passe incorrect.',
            ar: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.')
        : error.code == 'role_not_allowed'
            ? context.tr(
                en:
                    'Administrator accounts are created by an authorized operator.',
                fr:
                    'Les comptes administrateurs sont créés par un opérateur autorisé.',
                ar: 'يتم إنشاء حسابات المسؤولين بواسطة مشغل مخول.')
            : context.tr(
                en: 'Account request failed. Check your information and connection.',
                fr: 'Échec de la demande. Vérifiez vos informations et votre connexion.',
                ar: 'فشل الطلب. تحقق من بياناتك واتصالك.'));
  }

  void _openHome(String name, String role, {String? email}) {
    final homePage = role == 'Livreur'
        ? DriverOnboardingPage(userName: name, userEmail: email)
        : role == 'Administrateur'
            ? AdminInterface(userName: name)
            : role == 'Résident'
                ? ResidentsHomePage(userName: name, userEmail: email)
                : role == 'Société de lavage'
                    ? SocieteInterface(userName: name)
                    : HomePage(userName: name, userRole: role);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => homePage),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showLanguagePicker() => showAppLanguagePicker(context);
}
