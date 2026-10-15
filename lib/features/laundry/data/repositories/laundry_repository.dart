import 'package:sqflite/sqflite.dart';

import '../database/laundry_database.dart';
import '../models/laundry_item.dart';
import '../models/laundry_role.dart';
import '../models/laundry_status_change.dart';

class LaundryException implements Exception {
  const LaundryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LaundryRepository {
  LaundryRepository({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => LaundryDatabase.instance.database);

  final Future<Database> Function() _databaseProvider;

  Future<List<LaundryItem>> getAll() async {
    final db = await _databaseProvider();
    return (await db.query(
      'laundry_items',
      orderBy: 'created_at DESC, id DESC',
    )).map(LaundryItem.fromMap).toList();
  }

  Future<List<LaundryItem>> getByResidentId(int residentId) async {
    final db = await _databaseProvider();
    return (await db.query(
          'laundry_items',
          where: 'resident_id = ?',
          whereArgs: [residentId],
          orderBy: 'created_at DESC, id DESC',
        ))
        .map(LaundryItem.fromMap)
        // Keep the existing model type, but exclude financial values from this
        // resident-facing read. Staff use getAll()/getById() for full records.
        .map((item) => item.copyWith(price: 0, priceConfirmed: false))
        .toList();
  }

  Future<LaundryItem?> getById(String id) async =>
      _find(await _databaseProvider(), id);

  Future<LaundryItem?> _find(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'laundry_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : LaundryItem.fromMap(rows.single);
  }

  void _validate(LaundryItem item) {
    if (item.id.trim().isEmpty ||
        item.residentName.trim().isEmpty ||
        item.serviceType.trim().isEmpty ||
        !item.price.isFinite ||
        item.price < 0) {
      throw const LaundryException('Vérifiez les informations de la demande.');
    }
  }

  Future<int> add(LaundryItem item, {int? changedByUserId}) async {
    _validate(item);
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final result = await txn.insert('laundry_items', item.toMap());
      await _record(txn, item.id, null, item.status, changedByUserId);
      return result;
    });
  }

  Future<int> addForResident(LaundryItem item, {required int residentId}) {
    if (item.residentId != residentId ||
        item.status != LaundryStatus.deposited) {
      throw const LaundryException('Création de demande non autorisée.');
    }
    // A resident supplies a service, never a quote. Ignore any supplied amount.
    return add(
      item.copyWith(price: 0, priceConfirmed: false),
      changedByUserId: residentId,
    );
  }

  /// Administrator CRUD. Resident and operational screens use restricted methods.
  Future<int> update(LaundryItem item, {int? changedByUserId}) async {
    _validate(item);
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final current = await _require(txn, item.id);
      final result = await txn.update(
        'laundry_items',
        item.copyWith().toMap()
          ..['created_at'] = current.createdAt.toUtc().toIso8601String(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (current.status != item.status) {
        await _record(
          txn,
          item.id,
          current.status,
          item.status,
          changedByUserId,
        );
      }
      return result;
    });
  }

  Future<int> updateForResident(
    LaundryItem item, {
    required int residentId,
  }) async {
    // Validate the editable resident input without trusting any supplied price.
    _validate(item.copyWith(price: 0));
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final current = await _require(txn, item.id);
      _checkResident(current, residentId);
      // A different service needs a new quote. Preserve the previous amount for
      // administrator review; the resident cannot alter it or confirm it.
      return txn.update(
        'laundry_items',
        {
          'service_type': item.serviceType,
          if (item.serviceType != current.serviceType) 'price_confirmed': 0,
        },
        where: 'id = ? AND resident_id = ? AND status = ?',
        whereArgs: [item.id, residentId, LaundryStatus.deposited.name],
      );
    });
  }

  Future<int> delete(String id) async {
    final db = await _databaseProvider();
    return db.delete('laundry_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteForResident(String id, {required int residentId}) async {
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      _checkResident(await _require(txn, id), residentId);
      return txn.delete(
        'laundry_items',
        where: 'id = ? AND resident_id = ? AND status = ?',
        whereArgs: [id, residentId, LaundryStatus.deposited.name],
      );
    });
  }

  void _checkResident(LaundryItem item, int residentId) {
    if (item.residentId != residentId ||
        item.status != LaundryStatus.deposited) {
      throw const LaundryException(
        'Seules vos demandes déposées peuvent être modifiées ou supprimées.',
      );
    }
  }

  Future<LaundryItem> _require(DatabaseExecutor txn, String id) async {
    final item = await _find(txn, id);
    if (item == null) {
      throw const LaundryException('Cette demande n’existe plus.');
    }
    return item;
  }

  /// Check the persisted status inside the SAME transaction as the write/history.
  Future<void> transitionStatus(
    String id, {
    required LaundryStatus expectedStatus,
    required LaundryStatus newStatus,
    required LaundryRole role,
    int? changedByUserId,
  }) async {
    final allowed = switch (role) {
      LaundryRole.pressing =>
        (expectedStatus == LaundryStatus.deposited &&
                newStatus == LaundryStatus.processing) ||
            (expectedStatus == LaundryStatus.processing &&
                newStatus == LaundryStatus.ready),
      LaundryRole.driver =>
        expectedStatus == LaundryStatus.ready &&
            newStatus == LaundryStatus.delivered,
      _ => false,
    };
    if (!allowed) {
      throw const LaundryException('Transition non autorisée pour ce rôle.');
    }
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final current = await _require(txn, id);
      if (current.status != expectedStatus) {
        throw const LaundryException(
          'Le statut a changé. Actualisez les demandes.',
        );
      }
      final count = await txn.update(
        'laundry_items',
        {'status': newStatus.name},
        where: 'id = ? AND status = ?',
        whereArgs: [id, expectedStatus.name],
      );
      if (count != 1) {
        throw const LaundryException(
          'Le statut a changé. Actualisez les demandes.',
        );
      }
      await _record(txn, id, current.status, newStatus, changedByUserId);
    });
  }

  Future<List<LaundryStatusChange>> getStatusHistory(
    String id, {
    int? residentId,
  }) async {
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final current = await _require(txn, id);
      if (residentId != null && current.residentId != residentId) {
        throw const LaundryException('Cette demande ne vous appartient pas.');
      }
      return (await txn.query(
        'laundry_status_history',
        where: 'laundry_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      )).map(LaundryStatusChange.fromMap).toList();
    });
  }

  Future<void> _record(
    DatabaseExecutor txn,
    String id,
    LaundryStatus? oldStatus,
    LaundryStatus newStatus,
    int? userId,
  ) async {
    await txn.insert('laundry_status_history', {
      'laundry_id': id,
      'old_status': oldStatus?.name,
      'new_status': newStatus.name,
      'changed_by_user_id': userId,
      'changed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
