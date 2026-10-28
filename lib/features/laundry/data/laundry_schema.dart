import 'package:sqflite/sqflite.dart';

/// Runs in AppDatabase's upgrade transaction. Only Laundry objects are changed.
class LaundrySchema {
  LaundrySchema._();
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
