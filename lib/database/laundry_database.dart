import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Owns laundry.db only; the team's user database is never opened here.
class LaundryDatabase {
  LaundryDatabase._();
  static final LaundryDatabase instance = LaundryDatabase._();

  Database? _database;
  Future<Database>? _opening;
  Future<void>? _closing;

  Future<Database> get database async {
    final closing = _closing;
    if (closing != null) await closing;
    if (_database != null) return _database!;
    // Store the future before awaiting it so concurrent callers share one open.
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final directory = await getDatabasesPath();
      final db = await openDatabase(
        path.join(directory, 'laundry.db'),
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: createTables,
        onUpgrade: upgradeTables,
      );
      _database = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  Future<void> initialize() async {
    await database;
  }

  /// Call only when no repository operations remain in progress.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    try {
      final opening = _opening;
      final db = opening == null ? _database : await opening;
      await db?.close();
    } finally {
      _database = null;
      _closing = null;
    }
  }

  // Future schema changes must increase version and use onUpgrade migrations.
  // Never delete the file or drop tables during normal initialization.
  static Future<void> createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laundry_items (
        id TEXT PRIMARY KEY,
        resident_id INTEGER,
        resident_name TEXT NOT NULL,
        service_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'deposited',
        price REAL NOT NULL DEFAULT 0,
        price_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (price_confirmed IN (0, 1)),
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE laundry_status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        laundry_id TEXT NOT NULL,
        old_status TEXT,
        new_status TEXT NOT NULL,
        changed_by_user_id INTEGER,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (laundry_id) REFERENCES laundry_items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_laundry_resident ON laundry_items(resident_id)',
    );
    await db.execute(
      'CREATE INDEX idx_laundry_status ON laundry_items(status)',
    );
    await db.execute(
      'CREATE INDEX idx_laundry_history ON laundry_status_history(laundry_id, id)',
    );
  }

  /// Keep old amounts, but require administrator validation: version 1 allowed
  /// residents to enter prices, so an existing amount is not a confirmed quote.
  static Future<void> upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE laundry_items ADD COLUMN
        price_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (price_confirmed IN (0, 1))
      ''');
    }
  }
}
