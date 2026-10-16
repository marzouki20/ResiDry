import 'package:sqflite/sqflite.dart';

import '../../../../database/database.dart';
import '../../../../models/user.dart';

/// Reads central accounts. Never creates accounts or tables.
class LaundryUserDirectory {
  LaundryUserDirectory({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => AppDatabase.instance.database);
  final Future<Database> Function() _databaseProvider;

  Future<User?> getUserById(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _databaseProvider();
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.single);
  }

  Future<List<User>> getResidents({DatabaseExecutor? executor}) async {
    final db = executor ?? await _databaseProvider();
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['Résident'],
      orderBy: 'name ASC, id ASC',
    );
    return rows.map(User.fromMap).toList();
  }
}
