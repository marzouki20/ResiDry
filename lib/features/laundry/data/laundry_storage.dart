import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Persistence for the four Laundry tables. No account creation and no SQL
/// JSON extension required: lists are encoded/validated by Dart.
class LaundryStorage {
  LaundryStorage._();
  static const complaintColumns = [
    'id',
    'laundry_id',
    'resident_id',
    'line_id',
    'garment_snapshot',
    'reason',
    'description',
    'status',
    'decision_reason',
    'created_at',
    'updated_at',
    'revision',
    'resident_seen_revision',
  ];
  static const sortingColumns = [
    'sorting_color',
    'sorting_fabric',
    'sorting_cycle',
    'sorting_max_temperature_c',
    'sorting_dye_transfer_risk',
    'sorting_wash_separately',
    'sorting_verified_by_user_id',
    'sorting_verified_at',
  ];

  static List<Map<String, Object?>> decodeRows(Object? value) {
    final decoded = jsonDecode(value as String? ?? '[]');
    if (decoded is! List || decoded.any((v) => v is! Map<String, dynamic>)) {
      throw const FormatException('Invalid Laundry list');
    }
    return decoded.map((v) => Map<String, Object?>.from(v as Map)).toList();
  }

  static Future<List<Map<String, Object?>>> lines(
    DatabaseExecutor db,
    String id,
  ) async {
    final rows = await db.query(
      'laundry_items',
      columns: ['lines_json'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return [];
    return decodeRows(rows.single['lines_json'])
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }

  static Future<void> writeLines(
    DatabaseExecutor db,
    String id,
    List<Map<String, Object?>> values,
  ) async {
    final ids = values.map((v) => v['id']).toSet();
    if (ids.length != values.length ||
        values.any(
          (v) =>
              v['id'] is! String ||
              (v['id'] as String).trim().isEmpty ||
              v['laundry_id'] != id,
        )) {
      throw const FormatException('Invalid Laundry lot identifiers');
    }
    // Embedded IDs still stay globally unique, as they were before the merge.
    for (final parent in await db.query(
      'laundry_items',
      columns: ['id', 'lines_json'],
    )) {
      if (parent['id'] == id) continue;
      if (decodeRows(parent['lines_json']).any((v) => ids.contains(v['id']))) {
        throw const FormatException('Laundry lot identifier already used');
      }
    }
    final stored = [
      for (final row in values)
        {...row, for (final key in sortingColumns) key: row[key]},
    ];
    final count = await db.update(
      'laundry_items',
      {'lines_json': jsonEncode(stored)},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Laundry request missing');
    for (final complaint in await db.query(
      'laundry_complaints',
      columns: ['id', 'line_id'],
      where: 'laundry_id = ?',
      whereArgs: [id],
    )) {
      if (complaint['line_id'] != null && !ids.contains(complaint['line_id'])) {
        await db.update(
          'laundry_complaints',
          {'line_id': null},
          where: 'id = ?',
          whereArgs: [complaint['id']],
        );
      }
    }
  }

  static Future<List<Map<String, Object?>>> services(
    DatabaseExecutor db, {
    bool activeOnly = false,
  }) => db.query(
    'laundry_services',
    columns: [
      'id',
      'label_fr',
      'label_en',
      'label_ar',
      'is_active',
      'created_at',
    ],
    where: activeOnly ? 'is_active = ?' : null,
    whereArgs: activeOnly ? [1] : null,
    // Retain the configured display order, including the default service used
    // by existing tariff forms (the migration copies services in this order).
    orderBy: 'rowid ASC',
  );

  static Future<List<Map<String, Object?>>> tariffs(
    DatabaseExecutor db, {
    String? serviceId,
  }) async {
    final rows = await db.query(
      'laundry_services',
      columns: ['id', 'pricing_rules_json'],
      where: serviceId == null ? null : 'id = ?',
      whereArgs: serviceId == null ? null : [serviceId],
    );
    final rates = <Map<String, Object?>>[];
    for (final service in rows) {
      final versions = decodeRows(service['pricing_rules_json']);
      if (versions.any((v) => v['service_id'] != service['id'])) {
        throw const FormatException('Tariff belongs to another service');
      }
      rates.addAll(versions);
    }
    rates.sort(
      (a, b) =>
          (b['valid_from'] as String).compareTo(a['valid_from'] as String),
    );
    return rates;
  }

  static Future<void> writeTariffs(
    DatabaseExecutor db,
    String id,
    List<Map<String, Object?>> values,
  ) async {
    if (values.any((r) => r['service_id'] != id) ||
        values.map((r) => r['id']).toSet().length != values.length) {
      throw const FormatException('Invalid tariff identifiers');
    }
    final count = await db.update(
      'laundry_services',
      {'pricing_rules_json': jsonEncode(values)},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Laundry service missing');
  }

  static Future<List<Map<String, Object?>>> history(
    DatabaseExecutor db,
    String id,
  ) async =>
      (await db.query(
            'laundry_events',
            where: 'event_type = ? AND laundry_id = ?',
            whereArgs: ['laundry_status', id],
            orderBy: 'source_id ASC',
          ))
          .map(
            (r) => {
              'id': r['source_id'],
              'laundry_id': r['laundry_id'],
              'old_status': r['old_status'],
              'new_status': r['new_status'],
              'changed_by_user_id': r['actor_id'],
              'changed_at': r['created_at'],
            },
          )
          .toList();

  static Future<List<Map<String, Object?>>> complaintEvents(
    DatabaseExecutor db,
    String id,
  ) async =>
      (await db.query(
            'laundry_events',
            where: 'event_type = ? AND complaint_id = ?',
            whereArgs: ['complaint_status', id],
            orderBy: 'revision ASC',
          ))
          .map(
            (r) => {
              'id': r['source_id'],
              'complaint_id': r['complaint_id'],
              'old_status': r['old_status'],
              'new_status': r['new_status'],
              'actor_id': r['actor_id'],
              'note': r['note'],
              'revision': r['revision'],
              'created_at': r['created_at'],
            },
          )
          .toList();

  static Future<int> _nextSourceId(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      "SELECT seq AS last_id FROM sqlite_sequence WHERE name = 'laundry_events'",
    );
    final last = rows.isEmpty ? 0 : rows.single['last_id'] as int;
    return (last < 0 ? 0 : last) + 1;
  }

  static Future<void> addHistory(
    DatabaseExecutor db,
    Map<String, Object?> row, {
    int? migrationId,
  }) async {
    final next = await _nextSourceId(db);
    final legacyId = row['id'] as int?;
    await db.insert('laundry_events', {
      if (migrationId != null)
        'id': migrationId
      else if (legacyId != null)
        'id': legacyId > next ? legacyId : next,
      'event_type': 'laundry_status',
      'source_id': legacyId ?? next,
      'laundry_id': row['laundry_id'],
      'complaint_id': null,
      'old_status': row['old_status'],
      'new_status': row['new_status'],
      'actor_id': row['changed_by_user_id'],
      'note': '',
      'revision': null,
      'created_at': row['changed_at'],
    });
  }

  static Future<void> addComplaintEvent(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final parent = await db.query(
      'laundry_complaints',
      columns: ['laundry_id'],
      where: 'id = ?',
      whereArgs: [row['complaint_id']],
    );
    if (parent.length != 1) throw StateError('Complaint missing');
    await db.insert('laundry_events', {
      'event_type': 'complaint_status',
      'source_id': row['id'] ?? await _nextSourceId(db),
      'laundry_id': parent.single['laundry_id'],
      'complaint_id': row['complaint_id'],
      'old_status': row['old_status'],
      'new_status': row['new_status'],
      'actor_id': row['actor_id'],
      'note': row['note'],
      'revision': row['revision'],
      'created_at': row['created_at'],
    });
  }

  static Future<List<Map<String, Object?>>> photos(
    DatabaseExecutor db,
    String id,
  ) async {
    final rows = await db.query(
      'laundry_complaints',
      columns: ['photos_metadata_json', 'photo_1', 'photo_2', 'photo_3'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return [];
    final parent = rows.single;
    final metadata = decodeRows(parent['photos_metadata_json']);
    final count = [
      parent['photo_1'],
      parent['photo_2'],
      parent['photo_3'],
    ].where((v) => v != null).length;
    if (metadata.length > 3 || metadata.length != count) {
      throw const FormatException('Too many complaint photos');
    }
    return [
      for (var i = 0; i < metadata.length; i++)
        {
          ...metadata[i],
          'complaint_id': id,
          'content': parent['photo_${i + 1}'] as List<int>,
        },
    ];
  }

  static Future<void> writePhotos(
    DatabaseExecutor db,
    String id,
    List<Map<String, Object?>> rows,
  ) async {
    if (rows.length > 3) {
      throw const FormatException('Too many complaint photos');
    }
    await db.update(
      'laundry_complaints',
      {
        'photos_metadata_json': jsonEncode([
          for (final photo in rows)
            {
              for (final entry in photo.entries)
                if (entry.key != 'content') entry.key: entry.value,
            },
        ]),
        for (var i = 0; i < 3; i++)
          'photo_${i + 1}': i < rows.length ? rows[i]['content'] : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> addPhotos(
    DatabaseExecutor db,
    String id,
    List<Map<String, Object?>> rows,
  ) async {
    var last = 0;
    for (final parent in await db.query(
      'laundry_complaints',
      columns: ['photos_metadata_json'],
    )) {
      for (final row in decodeRows(parent['photos_metadata_json'])) {
        if ((row['id'] as int) > last) last = row['id'] as int;
      }
    }
    await writePhotos(db, id, [
      for (final row in rows) {...row, 'id': ++last, 'complaint_id': id},
    ]);
  }
}
