import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RememberMeAuthStorage extends LocalStorage {
  RememberMeAuthStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _rememberMeKey = 'supabase_remember_me';
  static const _sessionKey = 'sb-wzodfazdmtzvtnffvdvt-auth-token';

  final SharedPreferencesAsync _preferences;
  bool _rememberMe = false;

  @override
  Future<void> initialize() async {
    _rememberMe = await _preferences.getBool(_rememberMeKey) ?? false;
    if (!_rememberMe) {
      await removePersistedSession();
    }
  }

  Future<void> setRememberMe(bool rememberMe) async {
    _rememberMe = rememberMe;
    await _preferences.setBool(_rememberMeKey, rememberMe);
    if (!rememberMe) {
      await removePersistedSession();
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (!_rememberMe) return false;
    return await _preferences.getString(_sessionKey) != null;
  }

  @override
  Future<String?> accessToken() {
    if (!_rememberMe) return Future.value(null);
    return _preferences.getString(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_rememberMe) {
      await _preferences.setString(_sessionKey, persistSessionString);
    } else {
      await removePersistedSession();
    }
  }

  @override
  Future<void> removePersistedSession() {
    return _preferences.remove(_sessionKey);
  }
}
