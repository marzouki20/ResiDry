import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  static String get serverClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';

  static bool get isConfigured => serverClientId.trim().isNotEmpty;

  static Future<GoogleSignInAccount> signIn() async {
    await (_initialization ??= _googleSignIn.initialize(
      serverClientId: serverClientId.trim(),
    ));
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('Google sign-in is unavailable on this platform.');
    }
    return _googleSignIn.authenticate();
  }

  static Future<void> signOut() async {
    final initialization = _initialization;
    if (initialization == null) return;

    await initialization;
    await _googleSignIn.signOut();
  }
}
