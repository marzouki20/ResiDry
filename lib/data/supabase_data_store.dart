import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_connection.dart';
import '../models/residence.dart';

class SupabaseDataStore {
  SupabaseDataStore._();

  static final _client = SupabaseConnection.client;

  static Future<void> upsertUserProfile({
    required User user,
    required String name,
    required String email,
  }) {
    final normalizedName = name.trim().toUpperCase();
    final normalizedEmail = email.trim().toUpperCase();
    return _client.from('users').upsert({
      'id': user.id,
      'username': name.trim(),
      'normalizedusername': normalizedName,
      'email': email.trim().toLowerCase(),
      'normalizedemail': normalizedEmail,
      'emailconfirmed': user.emailConfirmedAt != null,
    }, onConflict: 'id');
  }

  static Future<List<Residence>> listResidences() async {
    final rows = await _client.from('residences').select().order('name');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((row) => Residence.fromMap(row))
        .toList();
  }
}
