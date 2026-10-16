import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../database/database.dart';
import '../domain/tunisia_governorates.dart';
import '../domain/vehicle_capacity_evidence.dart';

class DriverProfileRepository {
  DriverProfileRepository(
      {Future<Database> Function()? databaseProvider,
      Future<Directory> Function()? evidenceDirectoryProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database),
        _evidenceDirectoryProvider =
            evidenceDirectoryProvider ?? getApplicationSupportDirectory;
  final Future<Database> Function() _databaseProvider;
  final Future<Directory> Function() _evidenceDirectoryProvider;

  Future<Set<String>> getZones(String driverId) async {
    final database = await _databaseProvider();
    final rows = await database.query('driver_service_zones',
        columns: ['governorate_code'],
        where: 'driver_id = ?',
        whereArgs: [driverId]);
    return rows.map((row) => row['governorate_code']! as String).toSet();
  }

  Future<bool> hasProfile(String email) async {
    final database = await _databaseProvider();
    final rows = await database.query('delivery_drivers',
        columns: ['id'],
        where: 'email = ? AND archived_at IS NULL',
        whereArgs: [email],
        limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> save(
      {required String email,
      required String name,
      required String vehicle,
      required double capacityKg,
      VehicleCapacityEvidence? evidence,
      required Set<String> governorateCodes}) async {
    final validCodes = tunisiaGovernorates.map((item) => item.code).toSet();
    if (governorateCodes.isEmpty ||
        !validCodes.containsAll(governorateCodes) ||
        !capacityKg.isFinite ||
        capacityKg <= 0 ||
        capacityKg > 10000) {
      throw ArgumentError('Invalid driver profile');
    }
    if (evidence?.isComplete != true) {
      throw ArgumentError(
          'Complete vehicle details and confirmed photo are required');
    }
    final database = await _databaseProvider();
    if (evidence?.assess(capacityKg) == CapacityAssessment.exceedsLimit) {
      throw ArgumentError('Declared capacity exceeds evidence');
    }
    File? savedPhoto;
    File? savedBackPhoto;
    if (evidence != null && evidence.imagePath.isNotEmpty) {
      final root = await _evidenceDirectoryProvider();
      final directory = await Directory('${root.path}/capacity-evidence')
          .create(recursive: true);
      savedPhoto = await File(evidence.imagePath).copy(
          '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    }
    try {
      if (evidence != null && evidence.backImagePath.isNotEmpty) {
        savedBackPhoto = await File(evidence.backImagePath).copy(
            '${savedPhoto!.parent.path}/${DateTime.now().microsecondsSinceEpoch}-back.jpg');
      }
      await database.transaction((transaction) async {
        final users = await transaction.query('users',
            columns: ['id', 'phone'],
            where: 'email = ? AND role = ?',
            whereArgs: [email, 'Livreur'],
            limit: 1);
        if (users.isEmpty) throw StateError('Driver account not found');
        final existing = await transaction.query('delivery_drivers',
            columns: ['id'], where: 'email = ?', whereArgs: [email], limit: 1);
        final id = existing.isEmpty
            ? 'LIV-U-${users.first['id']}'
            : existing.first['id']! as String;
        final area = tunisiaGovernorates
            .where((g) => governorateCodes.contains(g.code))
            .map((g) => g.name)
            .join(', ');
        final values = <String, Object?>{
          'name': name,
          if ((users.first['phone'] as String? ?? '').isNotEmpty)
            'phone': users.first['phone'],
          'vehicle_type': vehicle,
          'capacity_kg': capacityKg,
          'capacity_assessment': (evidence?.assess(capacityKg) ??
                  CapacityAssessment.reviewRequired)
              .name,
          'assigned_zone': area,
          'archived_at': null
        };
        if (existing.isEmpty) {
          await transaction.insert('delivery_drivers', {
            ...values,
            'id': id,
            'email': email,
            'phone': users.first['phone'] ?? '',
            'status': 'En service',
            'rating': 0,
            'deliveries_completed': 0
          });
        } else {
          await transaction.update('delivery_drivers', values,
              where: 'id = ?', whereArgs: [id]);
        }
        await transaction.delete('driver_service_zones',
            where: 'driver_id = ?', whereArgs: [id]);
        for (final code in governorateCodes) {
          await transaction.insert('driver_service_zones',
              {'driver_id': id, 'governorate_code': code});
        }
        await transaction.delete('vehicle_capacity_checks',
            where: 'driver_id = ?', whereArgs: [id]);
        if (evidence != null) {
          await transaction.insert('vehicle_capacity_checks', {
            'driver_id': id,
            'brand': evidence.brand,
            'model': evidence.model,
            'vehicle_year': evidence.year,
            'photo_path': savedPhoto?.path ?? '',
            'photo_source': evidence.source,
            'back_photo_path': savedBackPhoto?.path ?? '',
            'registration_text': evidence.registrationText,
            'payload_kg': evidence.payloadKg,
            'reserve_kg': evidence.reserveKg,
            'declared_kg': capacityKg,
            'owner_confirmed': evidence.ownerConfirmed ? 1 : 0,
            'assessment': evidence.assess(capacityKg).name,
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      });
    } catch (_) {
      if (savedBackPhoto != null && await savedBackPhoto.exists()) {
        await savedBackPhoto.delete();
      }
      if (savedPhoto != null && await savedPhoto.exists()) {
        await savedPhoto.delete();
      }
      rethrow;
    }
  }

  Future<Map<String, Object?>?> getEvidence(String driverId) async {
    final database = await _databaseProvider();
    final rows = await database.query('vehicle_capacity_checks',
        where: 'driver_id = ?', whereArgs: [driverId]);
    return rows.isEmpty ? null : rows.single;
  }

  Future<void> reviewEvidence(
      {required String driverId,
      required String recordedAt,
      required String reviewer,
      required bool approved,
      double? payloadKg,
      double? reserveKg}) async {
    if (reviewer.trim().isEmpty) throw ArgumentError('Reviewer is required');
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      final rows = await transaction.query('vehicle_capacity_checks',
          where: 'driver_id = ? AND recorded_at = ?',
          whereArgs: [driverId, recordedAt]);
      if (rows.isEmpty) throw StateError('Evidence changed; reload it');
      if (approved &&
          (!VehicleCapacityEvidence.fromMap(rows.single).isComplete ||
              !await File(rows.single['photo_path']! as String).exists())) {
        throw ArgumentError(
            'Complete vehicle evidence is required for approval');
      }
      final declared = (rows.single['declared_kg']! as num).toDouble();
      if (approved &&
          (payloadKg == null ||
              reserveKg == null ||
              !payloadKg.isFinite ||
              !reserveKg.isFinite ||
              payloadKg <= 0 ||
              payloadKg > 10000 ||
              reserveKg < 0 ||
              declared + reserveKg > payloadKg)) {
        throw ArgumentError('Capacity exceeds the confirmed available payload');
      }
      final status = approved ? 'approved' : 'rejected';
      final reviewedAt = DateTime.now().toUtc().toIso8601String();
      await transaction.insert('vehicle_capacity_review_events', {
        'driver_id': driverId,
        'evidence_recorded_at': recordedAt,
        'photo_path': rows.single['photo_path'],
        'back_photo_path': rows.single['back_photo_path'] ?? '',
        'reviewed_at': reviewedAt,
        'reviewer': reviewer,
        'decision': status,
        'payload_kg': payloadKg,
        'reserve_kg': reserveKg,
      });
      await transaction.update(
          'vehicle_capacity_checks',
          {
            'admin_review_status': status,
            'reviewed_by': reviewer,
            'reviewed_at': reviewedAt,
            if (approved) 'payload_kg': payloadKg,
            if (approved) 'reserve_kg': reserveKg,
          },
          where: 'driver_id = ?',
          whereArgs: [driverId]);
      await transaction.update(
          'delivery_drivers', {'capacity_assessment': status},
          where: 'id = ?', whereArgs: [driverId]);
    });
  }
}
