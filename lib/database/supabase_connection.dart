import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remember_me_auth_storage.dart';

class SupabaseConnection {
  SupabaseConnection._();

  static final RememberMeAuthStorage authStorage = RememberMeAuthStorage();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _requiredValue('SUPABASE_URL'),
      publishableKey: _requiredValue('SUPABASE_PUBLISHABLE_KEY'),
      authOptions: FlutterAuthClientOptions(localStorage: authStorage),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String _requiredValue(String name) {
    final value = dotenv.env[name]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Set $name in the project .env file.');
    }
    return value;
  }
}
