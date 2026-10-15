import 'package:sqflite/sqflite.dart';

/// Test double for repository rules, NOT a substitute for real SQLite tests.
class MemoryDatabase extends MemoryExecutor implements Database {
  MemoryDatabase()
    : super(<String, List<Map<String, Object?>>>{
        'laundry_items': [],
        'laundry_status_history': [],
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
    try {
      return await action(MemoryTransaction(rows, failHistory: failHistory));
    } catch (_) {
      rows
        ..clear()
        ..addAll(snapshot);
      rethrow;
    }
  }
}

class MemoryTransaction extends MemoryExecutor implements Transaction {
  MemoryTransaction(super.rows, {required this.failHistory});
  final bool failHistory;
  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    if (failHistory && table == 'laundry_status_history') {
      throw StateError('Simulated history write failure');
    }
    return super.insert(table, values);
  }
}

class MemoryExecutor implements DatabaseExecutor {
  MemoryExecutor(this.rows);
  final Map<String, List<Map<String, Object?>>> rows;

  bool matches(Map<String, Object?> row, String? where, List<Object?>? args) {
    if (where == null) return true;
    final columns = where
        .split(' AND ')
        .map((clause) => clause.split(' = ').first)
        .toList();
    for (var i = 0; i < columns.length; i++) {
      if (row[columns[i]] != args![i]) return false;
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
    if (table == 'laundry_status_history') row['id'] = rows[table]!.length + 1;
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
      rows['laundry_status_history']!.removeWhere(
        (row) => ids.contains(row['laundry_id']),
      );
    }
    return selected.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
