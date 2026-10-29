import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'laundry_storage.dart';

/// Version 14 converts only Laundry data. Called in AppDatabase's transaction;
/// any failed verification restores the complete pre-migration schema/data.
class LaundryCompactSchema {
  LaundryCompactSchema._();
  static const tables = {
    'laundry_items',
    'laundry_services',
    'laundry_complaints',
    'laundry_events',
  };
  static const oldTables = {
    'laundry_items',
    'laundry_service_types',
    'laundry_pricing_rules',
    'laundry_request_lines',
    'laundry_status_history',
    'laundry_complaints',
    'laundry_complaint_events',
    'laundry_complaint_attachments',
  };
  static const itemsJsonSql =
      "ALTER TABLE laundry_items ADD COLUMN lines_json TEXT NOT NULL DEFAULT '[]'";
  static const servicesSql = '''CREATE TABLE laundry_services (
    id TEXT PRIMARY KEY NOT NULL,
    label_fr TEXT NOT NULL, label_en TEXT NOT NULL, label_ar TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
    created_at TEXT NOT NULL, pricing_rules_json TEXT NOT NULL DEFAULT '[]'
  )''';
  static const complaintsSql = '''CREATE TABLE laundry_complaints (
    id TEXT PRIMARY KEY NOT NULL,
    laundry_id TEXT NOT NULL REFERENCES laundry_items(id) ON DELETE RESTRICT,
    resident_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    line_id TEXT, garment_snapshot TEXT,
    reason TEXT NOT NULL CHECK(reason IN ('damaged','missing','poorCleaning','treatmentDelay','other')),
    description TEXT NOT NULL CHECK(length(trim(description)) BETWEEN 10 AND 2000),
    status TEXT NOT NULL DEFAULT 'submitted' CHECK(status IN ('submitted','reviewing','resolved','rejected')),
    decision_reason TEXT CHECK(decision_reason IS NULL OR length(trim(decision_reason)) BETWEEN 10 AND 2000),
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    revision INTEGER NOT NULL DEFAULT 1 CHECK(revision > 0),
    resident_seen_revision INTEGER NOT NULL DEFAULT 1 CHECK(resident_seen_revision >= 0 AND resident_seen_revision <= revision),
    photos_metadata_json TEXT NOT NULL DEFAULT '[]',
    photo_1 BLOB CHECK(photo_1 IS NULL OR (typeof(photo_1) = 'blob' AND length(photo_1) BETWEEN 1 AND 2097152)),
    photo_2 BLOB CHECK(photo_2 IS NULL OR (typeof(photo_2) = 'blob' AND length(photo_2) BETWEEN 1 AND 2097152)),
    photo_3 BLOB CHECK(photo_3 IS NULL OR (typeof(photo_3) = 'blob' AND length(photo_3) BETWEEN 1 AND 2097152)),
    UNIQUE(id,laundry_id),
    CHECK(photo_2 IS NULL OR photo_1 IS NOT NULL),
    CHECK(photo_3 IS NULL OR photo_2 IS NOT NULL),
    CHECK(status NOT IN ('resolved','rejected') OR decision_reason IS NOT NULL)
  )''';
  static const eventsSql = '''CREATE TABLE laundry_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL CHECK(event_type IN ('laundry_status','complaint_status')),
    source_id INTEGER NOT NULL,
    laundry_id TEXT NOT NULL REFERENCES laundry_items(id) ON DELETE CASCADE,
    complaint_id TEXT,
    old_status TEXT, new_status TEXT NOT NULL,
    actor_id INTEGER REFERENCES users(id) ON DELETE RESTRICT,
    note TEXT NOT NULL DEFAULT '' CHECK(length(note) <= 2000),
    revision INTEGER, created_at TEXT NOT NULL,
    FOREIGN KEY(complaint_id,laundry_id) REFERENCES laundry_complaints(id,laundry_id) ON DELETE CASCADE,
    UNIQUE(event_type,source_id), UNIQUE(complaint_id,revision),
    CHECK((event_type = 'laundry_status' AND complaint_id IS NULL AND revision IS NULL
      AND new_status IN ('deposited','processing','ready','delivered')
      AND (old_status IS NULL OR old_status IN ('deposited','processing','ready','delivered')))
    OR (event_type = 'complaint_status' AND complaint_id IS NOT NULL AND actor_id IS NOT NULL AND revision IS NOT NULL AND revision > 0
      AND new_status IN ('submitted','reviewing','resolved','rejected')
      AND (old_status IS NOT NULL OR new_status = 'submitted')
      AND (old_status IS NULL OR old_status IN ('submitted','reviewing','resolved','rejected'))))
  )''';

  static Future<void> upgradeV14(DatabaseExecutor db) async {
    final existing = (await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    )).map((r) => r['name'] as String).toSet();
    if (tables.every(existing.contains) &&
        !existing.contains('laundry_request_lines')) {
      return;
    }
    if (!oldTables.every(existing.contains) ||
        existing.contains('laundry_services') ||
        existing.contains('laundry_events')) {
      throw StateError('Unexpected Laundry schema: conversion cancelled');
    }
    final removed = oldTables.difference({'laundry_items'});
    // Refuse to break a teammate's FK or view. Never disable foreign keys.
    for (final table in existing.difference(oldTables)) {
      final quoted = table.replaceAll('"', '""');
      final keys = await db.rawQuery('PRAGMA foreign_key_list("$quoted")');
      if (keys.any((r) => removed.contains(r['table']))) {
        throw StateError(
          'Another module references a Laundry table: conversion cancelled',
        );
      }
    }
    for (final view in await db.query(
      'sqlite_master',
      columns: ['sql'],
      where: 'type = ?',
      whereArgs: ['view'],
    )) {
      if (removed.any(
        (name) => RegExp(
          '\\b$name\\b',
          caseSensitive: false,
        ).hasMatch(view['sql'] as String? ?? ''),
      )) {
        throw StateError(
          'A view references a Laundry table: conversion cancelled',
        );
      }
    }
    final unknown = existing.where(
      (name) => name.startsWith('laundry_') && !oldTables.contains(name),
    );
    if (unknown.isNotEmpty) {
      throw StateError('Unknown Laundry table: conversion cancelled');
    }
    final beforeIssues = await db.rawQuery('PRAGMA foreign_key_check');
    if (beforeIssues.any((r) => oldTables.contains(r['table']))) {
      throw StateError('Invalid Laundry references: conversion cancelled');
    }
    final items = await db.query('laundry_items');
    final complaints = await db.query('laundry_complaints');
    await db.execute(itemsJsonSql);
    await db.execute(servicesSql);
    await db.execute(
      complaintsSql.replaceFirst(
        'laundry_complaints (',
        'laundry_complaints_v14 (',
      ),
    );
    await db.execute(
      eventsSql.replaceFirst(
        'REFERENCES laundry_complaints(',
        'REFERENCES laundry_complaints_v14(',
      ),
    );
    for (final item in items) {
      final lines = await db.query(
        'laundry_request_lines',
        where: 'laundry_id = ?',
        whereArgs: [item['id']],
        orderBy: 'id ASC',
      );
      await db.update(
        'laundry_items',
        {'lines_json': jsonEncode(lines)},
        where: 'id = ?',
        whereArgs: [item['id']],
      );
      _equalLists(lines, await LaundryStorage.lines(db, item['id'] as String));
      final after = (await db.query(
        'laundry_items',
        where: 'id = ?',
        whereArgs: [item['id']],
      )).single;
      _equalMap(item, {
        for (final entry in after.entries)
          if (entry.key != 'lines_json') entry.key: entry.value,
      });
    }
    for (final service in await db.query('laundry_service_types')) {
      final rates = await db.query(
        'laundry_pricing_rules',
        where: 'service_id = ?',
        whereArgs: [service['id']],
      );
      await db.insert('laundry_services', {
        ...service,
        'pricing_rules_json': jsonEncode(rates),
      });
      final savedService = (await db.query(
        'laundry_services',
        where: 'id = ?',
        whereArgs: [service['id']],
      )).single;
      _equalMap(service, {
        for (final entry in savedService.entries)
          if (entry.key != 'pricing_rules_json') entry.key: entry.value,
      });
      _equalLists(
        rates,
        LaundryStorage.decodeRows(savedService['pricing_rules_json']),
      );
    }
    for (final complaint in complaints) {
      final photos = await db.query(
        'laundry_complaint_attachments',
        where: 'complaint_id = ?',
        whereArgs: [complaint['id']],
        orderBy: 'id ASC',
      );
      if (photos.length > 3) {
        throw StateError('More than three existing photos: no data removed');
      }
      final metadata = [
        for (final photo in photos)
          {
            for (final entry in photo.entries)
              if (entry.key != 'content') entry.key: entry.value,
          },
      ];
      await db.insert('laundry_complaints_v14', {
        ...complaint,
        'photos_metadata_json': jsonEncode(metadata),
        for (var i = 0; i < 3; i++)
          'photo_${i + 1}': i < photos.length ? photos[i]['content'] : null,
      });
      final after = (await db.query(
        'laundry_complaints_v14',
        where: 'id = ?',
        whereArgs: [complaint['id']],
      )).single;
      _equalMap(complaint, {
        for (final entry in after.entries)
          if (complaint.containsKey(entry.key)) entry.key: entry.value,
      });
      for (var i = 0; i < photos.length; i++) {
        _equalMap(photos[i], {
          ...metadata[i],
          'content': after['photo_${i + 1}'],
        });
      }
    }
    final history = await db.query('laundry_status_history');
    final events = await db.query('laundry_complaint_events');
    var nextPhysicalId =
        [...history, ...events].fold<int>(
          0,
          (maximum, row) =>
              (row['id'] as int) > maximum ? row['id'] as int : maximum,
        ) +
        1;
    for (final row in history) {
      await LaundryStorage.addHistory(db, row, migrationId: nextPhysicalId++);
    }
    final byComplaint = {for (final c in complaints) c['id']: c};
    for (final row in events) {
      await db.insert('laundry_events', {
        'id': nextPhysicalId++,
        'event_type': 'complaint_status',
        'source_id': row['id'],
        'laundry_id': byComplaint[row['complaint_id']]!['laundry_id'],
        'complaint_id': row['complaint_id'],
        'old_status': row['old_status'],
        'new_status': row['new_status'],
        'actor_id': row['actor_id'],
        'note': row['note'],
        'revision': row['revision'],
        'created_at': row['created_at'],
      });
    }
    for (final item in items) {
      _equalLists(
        history.where((r) => r['laundry_id'] == item['id']).toList()
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int)),
        await LaundryStorage.history(db, item['id'] as String),
      );
    }
    for (final complaint in complaints) {
      _equalLists(
        events.where((r) => r['complaint_id'] == complaint['id']).toList()
          ..sort(
            (a, b) => (a['revision'] as int).compareTo(b['revision'] as int),
          ),
        await LaundryStorage.complaintEvents(db, complaint['id'] as String),
      );
    }
    // Exact allow-list; none of the team's tables are rebuilt or dropped.
    for (final table in [
      'laundry_complaint_events',
      'laundry_complaint_attachments',
      'laundry_complaints',
    ]) {
      await db.execute('DROP TABLE $table');
    }
    await db.execute(
      'ALTER TABLE laundry_complaints_v14 RENAME TO laundry_complaints',
    );
    for (final table in [
      'laundry_status_history',
      'laundry_request_lines',
      'laundry_pricing_rules',
      'laundry_service_types',
    ]) {
      await db.execute('DROP TABLE $table');
    }
    await db.execute(
      'CREATE INDEX idx_laundry_events_request ON laundry_events(event_type,laundry_id,source_id)',
    );
    await db.execute(
      'CREATE INDEX idx_complaints_resident ON laundry_complaints(resident_id,updated_at)',
    );
    await db.execute(
      'CREATE INDEX idx_complaints_request ON laundry_complaints(laundry_id)',
    );
    await db.execute(
      "CREATE UNIQUE INDEX idx_complaints_active ON laundry_complaints(laundry_id,resident_id,reason) WHERE status IN ('submitted','reviewing')",
    );
    final afterIssues = await db.rawQuery('PRAGMA foreign_key_check');
    if (afterIssues.any((r) => tables.contains(r['table'])) ||
        jsonEncode(beforeIssues) != jsonEncode(afterIssues)) {
      throw StateError('Foreign key verification failed: conversion cancelled');
    }
    final count =
        (await db.query(
              'sqlite_master',
              columns: ['name'],
              where: 'type = ?',
              whereArgs: ['table'],
            ))
            .map((r) => r['name'])
            .where((n) => (n as String).startsWith('laundry_'))
            .toSet();
    if (count.length != 4 || !count.containsAll(tables)) {
      throw StateError('Four Laundry tables expected');
    }
  }

  static void _equalLists(
    List<Map<String, Object?>> before,
    List<Map<String, Object?>> after,
  ) {
    if (before.length != after.length) {
      throw StateError('Laundry row count changed');
    }
    for (var i = 0; i < before.length; i++) {
      _equalMap(before[i], after[i]);
    }
  }

  static void _equalMap(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    if (before.length != after.length) {
      throw StateError('Laundry field count changed');
    }
    for (final entry in before.entries) {
      final a = entry.value, b = after[entry.key];
      if (a is List<int> && b is List<int>) {
        if (a.length != b.length) throw StateError('Photo bytes changed');
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) throw StateError('Photo bytes changed');
        }
      } else if (a != b) {
        throw StateError('Laundry value changed: ${entry.key}');
      }
    }
  }
}
