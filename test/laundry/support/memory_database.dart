import 'package:sqflite/sqflite.dart';

/// Test double for repository rules, NOT a substitute for real SQLite tests.
class MemoryDatabase extends MemoryExecutor implements Database {
  MemoryDatabase()
    : super(<String, List<Map<String, Object?>>>{
        'laundry_items': [],
        'laundry_events': [],
        'users': [],
        'laundry_services': [
          {
            'id': 'washing',
            'label_fr': 'Lavage',
            'label_en': 'Washing',
            'label_ar': 'Washing',
            'is_active': 1,
            'pricing_rules_json': '[]',
          },
          {
            'id': 'ironing',
            'label_fr': 'Repassage',
            'label_en': 'Ironing',
            'label_ar': 'Ironing',
            'is_active': 1,
            'pricing_rules_json': '[]',
          },
          {
            'id': 'dry_cleaning',
            'label_fr': 'Dry cleaning',
            'label_en': 'Dry cleaning',
            'label_ar': 'Dry cleaning',
            'is_active': 1,
            'pricing_rules_json': '[]',
          },
        ],
        'laundry_complaints': [],
      });
  bool failHistory = false;
  int transactions = 0;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async {
    transactions++;
    final snapshot = {
      for (final entry in rows.entries)
        entry.key: entry.value
            .map((row) => Map<String, Object?>.from(row))
            .toList(),
    };
    final sequenceSnapshot = Map<String, int>.from(sequences);
    try {
      return await action(
        MemoryTransaction(rows, sequences: sequences, failHistory: failHistory),
      );
    } catch (_) {
      rows
        ..clear()
        ..addAll(snapshot);
      sequences
        ..clear()
        ..addAll(sequenceSnapshot);
      rethrow;
    }
  }
}

class MemoryTransaction extends MemoryExecutor implements Transaction {
  MemoryTransaction(
    super.rows, {
    required this.failHistory,
    required super.sequences,
  });
  final bool failHistory;
  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    if (failHistory &&
        table == 'laundry_events' &&
        values['event_type'] == 'laundry_status') {
      throw StateError('Simulated history write failure');
    }
    return super.insert(table, values);
  }
}

class MemoryExecutor implements DatabaseExecutor {
  MemoryExecutor(this.rows, {Map<String, int>? sequences})
    : sequences = sequences ?? {};
  final Map<String, List<Map<String, Object?>>> rows;
  final Map<String, int> sequences;

  bool matches(Map<String, Object?> row, String? where, List<Object?>? args) {
    if (where == null) return true;
    final clauses = where.split(' AND ');
    var argIndex = 0;
    for (final clause in clauses) {
      final parts = clause.split(' = ');
      final col = parts[0].trim();
      final val = parts[1].trim();
      if (val == '?') {
        if (argIndex >= (args?.length ?? 0)) return false;
        if (row[col] != args![argIndex++]) return false;
      } else {
        final literal = int.tryParse(val) ?? val.replaceAll("'", "");
        if (row[col] != literal) return false;
      }
    }
    return true;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return rows[table]!
        .where((row) => matches(row, where, whereArgs))
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final row = Map<String, Object?>.from(values);
    if (table == 'laundry_items') {
      row.putIfAbsent('revision', () => 0);
      row.putIfAbsent('lines_json', () => '[]');
    }
    if (table == 'laundry_complaints') {
      row.putIfAbsent('photos_metadata_json', () => '[]');
    }
    if (table == 'laundry_events') {
      row.putIfAbsent('id', () => (sequences[table] ?? 0) + 1);
      if ((row['id'] as int) > (sequences[table] ?? 0)) {
        sequences[table] = row['id'] as int;
      }
    }
    if (rows[table]!.any((existing) => existing['id'] == row['id'])) {
      throw StateError('Duplicate primary key');
    }
    rows[table]!.add(row);
    return rows[table]!.length;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final selected = rows[table]!
        .where((row) => matches(row, where, whereArgs))
        .toList();
    for (final row in selected) {
      row.addAll(values);
    }
    return selected.length;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final selected = rows[table]!
        .where((row) => matches(row, where, whereArgs))
        .toList();
    rows[table]!.removeWhere(selected.contains);
    if (table == 'laundry_items') {
      final ids = selected.map((row) => row['id']).toSet();
      rows['laundry_events']!.removeWhere(
        (row) => ids.contains(row['laundry_id']),
      );
    }
    return selected.length;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (sql.startsWith('SELECT seq AS last_id')) {
      return sequences.containsKey('laundry_events')
          ? [
              {'last_id': sequences['laundry_events']},
            ]
          : [];
    }
    throw UnsupportedError(sql);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
