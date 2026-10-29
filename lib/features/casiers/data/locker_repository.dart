import '../../../database/supabase_connection.dart';
import '../presentation/widgets/casier_components.dart';

class LockerRepository {
  LockerRepository._();

  static final _client = SupabaseConnection.client;

  static Future<List<LockerRecord>> list() async {
    final rows = await _client.from('lockers').select().order('id');
    final users = await _client.from('users').select('id, username');
    final namesById = <String, String>{
      for (final user in users as List)
        user['id'].toString(): user['username'] as String? ?? 'Non attribué',
    };

    return (rows as List).map((row) {
      final data = row as Map<String, dynamic>;
      return LockerRecord(
        id: data['id'].toString(),
        resident: data['resident_id'] == null
            ? 'Non attribué'
            : namesById[data['resident_id'].toString()] ?? 'Non attribué',
        apartment: data['apartment'] as String? ?? '',
        maxWeight: (data['max_weight_kg'] as num?)?.toDouble() ?? 10,
        lockerType: data['locker_type'] as String? ?? 'Standard',
        climateMonitoring: data['climate_monitoring'] as bool? ?? true,
        rfidEnabled: data['rfid_enabled'] as bool? ?? true,
        electronicLock: data['electronic_lock'] as bool? ?? true,
        weight: (data['weight_kg'] as num?)?.toDouble() ?? 0,
        temperature: (data['temperature_c'] as num?)?.round() ?? 0,
        humidity: (data['humidity_pct'] as num?)?.round() ?? 0,
        doorOpen: data['door_open'] as bool? ?? false,
        locked: data['locked'] as bool? ?? true,
        connected: data['connected'] as bool? ?? false,
        status: _uiStatus(data['status'] as String?),
      );
    }).toList();
  }

  static Future<void> save(LockerRecord locker) async {
    String? residentId;
    if (locker.resident != 'Non attribué') {
      final user = await _client
          .from('users')
          .select('id')
          .eq('username', locker.resident)
          .maybeSingle();
      residentId = user?['id']?.toString();
    }

    await _client.from('lockers').upsert({
      'id': locker.id,
      'resident_id': residentId,
      'apartment': locker.apartment,
      'max_weight_kg': locker.maxWeight,
      'locker_type': locker.lockerType,
      'climate_monitoring': locker.climateMonitoring,
      'rfid_enabled': locker.rfidEnabled,
      'electronic_lock': locker.electronicLock,
      'weight_kg': locker.weight,
      'temperature_c': locker.temperature,
      'humidity_pct': locker.humidity,
      'door_open': locker.doorOpen,
      'locked': locker.locked,
      'connected': locker.connected,
      'status': _databaseStatus(locker.status),
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  static Future<void> delete(String id) =>
      _client.from('lockers').delete().eq('id', id);

  static String _databaseStatus(String status) => switch (status) {
    'Disponible' => 'available',
    'Maintenance' => 'maintenance',
    'Hors ligne' => 'offline',
    'Anomalie' => 'maintenance',
    _ => 'occupied',
  };

  static String _uiStatus(String? status) => switch (status) {
    'available' => 'Disponible',
    'maintenance' => 'Maintenance',
    'offline' => 'Hors ligne',
    'reserved' => 'Réservé',
    _ => 'Normal',
  };
}
