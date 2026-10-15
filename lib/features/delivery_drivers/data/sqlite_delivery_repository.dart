import 'package:sqflite/sqflite.dart';

import '../../../../database/database.dart';
import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';
import '../domain/delivery_status.dart';
import 'delivery_repository.dart';

typedef DatabaseProvider = Future<Database> Function();

class SqliteDeliveryRepository implements DeliveryRepository {
  SqliteDeliveryRepository({DatabaseProvider? databaseProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database);

  final DatabaseProvider _databaseProvider;

  @override
  Future<List<DeliveryDriver>> getDrivers() async {
    final database = await _databaseProvider();
    final rows = await database.rawQuery('''
      SELECT d.*, c.recorded_at AS application_submitted_at,
             c.admin_review_status AS application_review_status
      FROM delivery_drivers d
      LEFT JOIN vehicle_capacity_checks c ON c.driver_id = d.id
      WHERE d.archived_at IS NULL
      ORDER BY d.name COLLATE NOCASE
    ''');
    return rows.map(DeliveryDriver.fromMap).toList(growable: false);
  }

  @override
  Future<List<DeliveryOrder>> getMissions({String? driverName}) async {
    final database = await _databaseProvider();
    final rows = await database.rawQuery('''
      SELECT m.*, d.name AS driver_name
      FROM delivery_missions m
      LEFT JOIN delivery_drivers d ON d.id = m.assigned_driver_id
      ${driverName == null ? '' : 'WHERE d.name = ?'}
      ORDER BY m.scheduled_at ASC, m.id ASC
    ''', driverName == null ? null : [driverName]);
    return rows.map(DeliveryOrder.fromMap).toList(growable: false);
  }

  @override
  Future<void> assignMission({
    required String missionId,
    required String driverId,
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      final driverRows = await transaction.query(
        'delivery_drivers',
        columns: ['id', 'status', 'capacity_assessment', 'capacity_kg'],
        where: 'id = ? AND archived_at IS NULL',
        whereArgs: [driverId],
        limit: 1,
      );
      if (driverRows.isEmpty) {
        throw StateError('Livreur introuvable.');
      }
      if (driverRows.first['status'] == 'Hors service') {
        throw StateError(
            'Un livreur hors service ne peut pas recevoir de mission.');
      }

      if (driverRows.first['capacity_assessment'] != 'approved') {
        throw StateError(
            'Vehicle approval is required before assigning missions.');
      }
      final capacity = (driverRows.first['capacity_kg'] as num?)?.toDouble();
      final missions = await transaction
          .query('delivery_missions', where: 'id = ?', whereArgs: [missionId]);
      if (missions.isEmpty) throw StateError('Mission introuvable.');
      final weight = (missions.single['weight_kg'] as num).toDouble();
      final loads = await transaction.query('delivery_missions',
          columns: ['weight_kg'],
          where: 'assigned_driver_id = ? AND id != ? AND status != ?',
          whereArgs: [driverId, missionId, DeliveryStatus.delivered]);
      final reserved = loads.fold<double>(
          0, (total, row) => total + (row['weight_kg'] as num).toDouble());
      if (capacity == null ||
          !capacity.isFinite ||
          capacity <= 0 ||
          !weight.isFinite ||
          weight <= 0 ||
          reserved + weight > capacity) {
        throw StateError('Assignment exceeds the approved vehicle capacity.');
      }
      final updated = await transaction.update(
        'delivery_missions',
        {
          'assigned_driver_id': driverId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [missionId, DeliveryStatus.readyForPickup],
      );
      if (updated != 1) {
        throw StateError(
          'Seule une mission en attente peut être assignée.',
        );
      }
      await _insertEvent(
        transaction,
        missionId: missionId,
        eventType: 'MISSION_ASSIGNED',
        details: driverId,
      );
    });
  }

  @override
  Future<DeliveryOrder> advanceMission(String missionId) async {
    final database = await _databaseProvider();
    return database.transaction((transaction) async {
      final rows = await transaction.query(
        'delivery_missions',
        where: 'id = ?',
        whereArgs: [missionId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Mission introuvable.');
      }
      final currentStatus = rows.first['status']! as String;
      final nextStatus = DeliveryMissionPolicy.nextStatus(currentStatus);
      final updated = await transaction.update(
        'delivery_missions',
        {
          'status': nextStatus,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [missionId, currentStatus],
      );
      if (updated != 1) {
        throw StateError('La mission a été modifiée par une autre opération.');
      }
      await _insertEvent(
        transaction,
        missionId: missionId,
        eventType: 'STATUS_CHANGED',
        details: '$currentStatus → $nextStatus',
      );

      final result = await transaction.rawQuery('''
        SELECT m.*, d.name AS driver_name
        FROM delivery_missions m
        LEFT JOIN delivery_drivers d ON d.id = m.assigned_driver_id
        WHERE m.id = ?
      ''', [missionId]);
      return DeliveryOrder.fromMap(result.single);
    });
  }

  Future<void> _insertEvent(
    DatabaseExecutor database, {
    required String missionId,
    required String eventType,
    required String details,
  }) {
    return database.insert('delivery_events', {
      'mission_id': missionId,
      'event_type': eventType,
      'details': details,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
