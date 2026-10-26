import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  AuthSessionStore({SharedPreferencesAsync? preferences})
    : _providedPreferences = preferences;

  static const _rememberedEmailKey = 'remembered_email';

  final SharedPreferencesAsync? _providedPreferences;

  late final _preferences = _providedPreferences ?? SharedPreferencesAsync();

  Future<String?> getRememberedEmail() {
    return _preferences.getString(_rememberedEmailKey);
  }

  Future<void> rememberEmail(String email) {
    return _preferences.setString(_rememberedEmailKey, email);
  }

  Future<void> forgetEmail() {
    return _preferences.remove(_rememberedEmailKey);
  }
}
