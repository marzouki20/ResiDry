import 'package:sqflite/sqflite.dart';

/// Historical stages 11-13, kept to upgrade existing installations. Version 14
/// finishes the conversion into the four tables in LaundryCompactSchema.
class LaundrySchema {
  LaundrySchema._();
  static Future<void> upgradeV13(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS laundry_complaints (
      id TEXT PRIMARY KEY NOT NULL,
      laundry_id TEXT NOT NULL REFERENCES laundry_items(id) ON DELETE RESTRICT,
      resident_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      line_id TEXT REFERENCES laundry_request_lines(id) ON DELETE SET NULL,
      garment_snapshot TEXT,
      reason TEXT NOT NULL CHECK(reason IN ('damaged','missing','poorCleaning','treatmentDelay','other')),
      description TEXT NOT NULL CHECK(length(trim(description)) BETWEEN 10 AND 2000),
      status TEXT NOT NULL DEFAULT 'submitted' CHECK(status IN ('submitted','reviewing','resolved','rejected')),
      decision_reason TEXT CHECK(decision_reason IS NULL OR length(trim(decision_reason)) BETWEEN 10 AND 2000),
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      revision INTEGER NOT NULL DEFAULT 1 CHECK(revision > 0),
      resident_seen_revision INTEGER NOT NULL DEFAULT 1 CHECK(resident_seen_revision >= 0 AND resident_seen_revision <= revision),
      CHECK(status NOT IN ('resolved','rejected') OR decision_reason IS NOT NULL)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS laundry_complaint_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      complaint_id TEXT NOT NULL REFERENCES laundry_complaints(id) ON DELETE CASCADE,
      old_status TEXT CHECK(old_status IN ('submitted','reviewing','resolved','rejected')),
      new_status TEXT NOT NULL CHECK(new_status IN ('submitted','reviewing','resolved','rejected')),
      actor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      note TEXT NOT NULL DEFAULT '' CHECK(length(note) <= 2000),
      revision INTEGER NOT NULL CHECK(revision > 0), created_at TEXT NOT NULL,
      CHECK(old_status IS NOT NULL OR new_status = 'submitted'),
      UNIQUE(complaint_id,revision)
    )''');
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS laundry_complaint_attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      complaint_id TEXT NOT NULL REFERENCES laundry_complaints(id) ON DELETE CASCADE,
      mime_type TEXT NOT NULL CHECK(mime_type IN ('image/jpeg','image/png','image/webp')),
      content BLOB NOT NULL CHECK(typeof(content) = 'blob' AND length(content) BETWEEN 1 AND 2097152),
      created_at TEXT NOT NULL
    )''',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_complaints_resident ON laundry_complaints(resident_id,updated_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_complaints_request ON laundry_complaints(laundry_id)',
    );
    await db.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_complaints_active ON laundry_complaints(laundry_id,resident_id,reason) WHERE status IN ('submitted','reviewing')",
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_complaint_attachments ON laundry_complaint_attachments(complaint_id)',
    );
  }

  static Future<void> upgradeV12(DatabaseExecutor db) async {
    final columns = (await db.rawQuery(
      'PRAGMA table_info(laundry_request_lines)',
    )).map((row) => row['name']).toSet();
    const additions = {
      'sorting_color': "TEXT CHECK(sorting_color IN ('white','light','dark'))",
      'sorting_fabric': "TEXT CHECK(sorting_fabric IN ('cotton','linen','synthetic','wool','silk','blend','other'))",
      'sorting_cycle': "TEXT CHECK(sorting_cycle IN ('normal','delicate','handWash','doNotWash'))",
      'sorting_max_temperature_c': "INTEGER CHECK(sorting_max_temperature_c IS NULL OR (typeof(sorting_max_temperature_c) = 'integer' AND sorting_max_temperature_c BETWEEN 1 AND 95))",
      'sorting_dye_transfer_risk':
          "TEXT CHECK(sorting_dye_transfer_risk IN ('unknown','low','high'))",
      'sorting_wash_separately':
          'INTEGER CHECK(sorting_wash_separately IN (0,1))',
      'sorting_verified_by_user_id':
          'INTEGER REFERENCES users(id) ON DELETE RESTRICT',
      'sorting_verified_at': 'TEXT CHECK((sorting_verified_at IS NULL) = (sorting_verified_by_user_id IS NULL))',
    };
    for (final entry in additions.entries) {
      if (!columns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE laundry_request_lines ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  static Future<void> upgradeV11(DatabaseExecutor db) async {
    final columns = (await db.rawQuery('PRAGMA table_info(laundry_items)'))
        .map((row) => row['name'])
        .toSet();
    const additions = {
      'treatment_due_at': 'TEXT',
      'urgency': "TEXT CHECK(urgency IN ('normal','urgent'))",
      'revision': 'INTEGER NOT NULL DEFAULT 0 CHECK(revision >= 0)',
      'updated_at': 'TEXT',
    };
    for (final entry in additions.entries) {
      if (!columns.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE laundry_items ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
    await db.execute('''CREATE TABLE IF NOT EXISTS laundry_service_types (
      id TEXT PRIMARY KEY NOT NULL,
      label_fr TEXT NOT NULL, label_en TEXT NOT NULL, label_ar TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
      created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS laundry_pricing_rules (
      id TEXT PRIMARY KEY NOT NULL,
      service_id TEXT NOT NULL REFERENCES laundry_service_types(id) ON DELETE RESTRICT,
      pricing_basis TEXT NOT NULL CHECK(pricing_basis IN ('per_item','per_kg')),
      unit_price_millimes INTEGER NOT NULL CHECK(unit_price_millimes >= 0),
      estimated_minutes INTEGER CHECK(estimated_minutes IS NULL OR estimated_minutes > 0),
      valid_from TEXT NOT NULL, valid_until TEXT,
      created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
      created_at TEXT NOT NULL,
      CHECK(valid_until IS NULL OR valid_until > valid_from),
      UNIQUE(service_id,pricing_basis,valid_from)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS laundry_request_lines (
      id TEXT PRIMARY KEY NOT NULL,
      laundry_id TEXT NOT NULL REFERENCES laundry_items(id) ON DELETE CASCADE,
      garment_type TEXT NOT NULL CHECK(length(trim(garment_type)) > 0),
      service_id TEXT NOT NULL REFERENCES laundry_service_types(id) ON DELETE RESTRICT,
      quantity INTEGER NOT NULL CHECK(quantity > 0),
      weight_grams INTEGER CHECK(weight_grams IS NULL OR weight_grams > 0),
      instructions TEXT NOT NULL DEFAULT '',
      pricing_basis TEXT NOT NULL CHECK(pricing_basis IN ('per_item','per_kg')),
      pricing_rule_id TEXT REFERENCES laundry_pricing_rules(id) ON DELETE RESTRICT,
      unit_price_millimes INTEGER CHECK(unit_price_millimes IS NULL OR unit_price_millimes >= 0),
      total_millimes INTEGER CHECK(total_millimes IS NULL OR total_millimes >= 0),
      estimated_minutes INTEGER CHECK(estimated_minutes IS NULL OR estimated_minutes > 0),
      created_at TEXT NOT NULL
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_laundry_deadline ON laundry_items(status,treatment_due_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_laundry_lines_parent ON laundry_request_lines(laundry_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_laundry_rates_service ON laundry_pricing_rules(service_id,pricing_basis,valid_from)',
    );
    final now = DateTime.now().toUtc().toIso8601String();
    // Vocabulary, not invented tariffs, durations, requests or user accounts.
    for (final entry in const [
      ['washing', 'Lavage', 'Washing', 'غسيل'],
      ['ironing', 'Repassage', 'Ironing', 'كيّ'],
      ['dry_cleaning', 'Nettoyage à sec', 'Dry cleaning', 'تنظيف جاف'],
    ]) {
      await db.insert('laundry_service_types', {
        'id': entry[0],
        'label_fr': entry[1],
        'label_en': entry[2],
        'label_ar': entry[3],
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
