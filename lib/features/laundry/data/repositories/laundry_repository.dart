import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../../database/database.dart';
import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_role.dart';
import '../../../../models/laundry_status_change.dart';
import '../../../../models/user.dart';
import '../laundry_storage.dart';
import 'laundry_user_directory.dart';
import '../models/laundry_report.dart';
import '../models/laundry_details.dart';
import '../../domain/models/laundry_quote.dart';
import '../../domain/services/pricing_service.dart';
import '../../domain/models/laundry_workload.dart';
import '../../domain/services/planning_service.dart';
import '../../domain/services/laundry_statistics_service.dart';
import '../models/laundry_sorting_data.dart';
import '../../domain/models/laundry_sorting.dart';
import '../../domain/services/sorting_service.dart';
import '../models/laundry_complaint_data.dart';
import '../services/complaint_photo_service.dart';
import '../../domain/models/laundry_complaint.dart';
import '../../domain/services/complaint_service.dart';

part 'laundry_essential_operations.dart';
part 'laundry_sorting_operations.dart';
part 'laundry_complaint_operations.dart';

class LaundryException implements Exception {
  const LaundryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Bound to an authenticated account; rechecks the stored role on every operation.
class LaundryRepository {
  LaundryRepository({
    this.currentUser,
    DateTime Function()? clock,
    Future<Database> Function()? databaseProvider,
    LaundryUserDirectory? userDirectory,
  }) : _clock = clock ?? DateTime.now,
       _databaseProvider =
           databaseProvider ?? (() => AppDatabase.instance.database),
       _users =
           userDirectory ??
           LaundryUserDirectory(databaseProvider: databaseProvider);
  final User? currentUser;
  final DateTime Function() _clock;
  final Future<Database> Function() _databaseProvider;
  final LaundryUserDirectory _users;

  LaundryRepository forUser(User? user) => user == null
      ? this
      : LaundryRepository(
          currentUser: user,
          clock: _clock,
          databaseProvider: _databaseProvider,
          userDirectory: _users,
        );
  static const _staff = {
    LaundryRole.admin,
    LaundryRole.pressing,
    LaundryRole.driver,
  };
  static const _allRoles = {..._staff, LaundryRole.resident};

  Future<T> _authorized<T>(
    Set<LaundryRole> roles,
    Future<T> Function(Transaction db, User actor, LaundryRole role) action,
  ) async {
    if (currentUser?.id == null) {
      throw const LaundryException('Connectez-vous pour accéder au linge.');
    }
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final actor = await _users.getUserById(currentUser!.id!, executor: txn);
      final role = actor == null ? null : laundryRoleFromUserRole(actor.role);
      if (actor == null || role == null || !roles.contains(role)) {
        throw const LaundryException(
          'Votre compte ne permet pas cette opération.',
        );
      }
      return action(txn, actor, role);
    });
  }

  Future<List<User>> getResidents() => _authorized({
    LaundryRole.admin,
  }, (db, actor, role) => _users.getResidents(executor: db));
  Future<User> getCurrentUser() =>
      _authorized(_allRoles, (db, actor, role) async => actor);

  /// One consistent SQLite snapshot, with the same ownership and financial
  /// permissions as the lists. Missing planning inputs remain unknown.
  Future<LaundryReport> getReport({DateTime? evaluatedAt}) =>
      _authorized(_allRoles, (db, actor, role) async {
        final now = (evaluatedAt ?? _clock()).toUtc();
        var rows = await db.query(
          'laundry_items',
          where: role == LaundryRole.resident ? 'resident_id = ?' : null,
          whereArgs: role == LaundryRole.resident ? [actor.id] : null,
          orderBy: 'created_at DESC, id DESC',
        );
        if (role == LaundryRole.driver) {
          rows = rows
              .where(
                (row) =>
                    row['status'] == 'ready' || row['status'] == 'delivered',
              )
              .toList();
        }
        final details = await _details(db, rows, role);
        final history = {
          for (final request in details) request.item.id: request.history,
        };
        final workloads = details
            .map((request) => request.workload(now))
            .toList();
        final services = (await LaundryStorage.services(db))
            .map(LaundryServiceType.fromMap)
            .toList();
        final serviceNames = {
          for (final service in services) service.id: service.fr,
        };
        return LaundryReport(
          workloads: workloads,
          details: {for (final request in details) request.item.id: request},
          history: history,
          priorities: const PlanningService().prioritize(workloads, now: now),
          statistics: const LaundryStatisticsService().summarize(
            workloads,
            now: now,
            historyByLaundryId: history,
            servicesByLaundryId: {
              for (final request in details.where((d) => d.lines.isNotEmpty))
                request.item.id: request.lines
                    .map((l) => serviceNames[l.serviceId] ?? l.serviceId)
                    .toList(),
            },
            includeFinancials: role == LaundryRole.admin,
          ),
          evaluatedAt: now,
        );
      });

  Future<List<LaundryItem>> _resolve(
    DatabaseExecutor db,
    List<Map<String, Object?>> rows, {
    bool hidePrices = false,
  }) async {
    final names = <int, String>{};
    final result = <LaundryItem>[];
    for (final row in rows) {
      var item = LaundryItem.fromMap(row);
      if (item.residentId != null) {
        final id = item.residentId!;
        if (!names.containsKey(id)) {
          names[id] =
              (await _users.getUserById(id, executor: db))?.name ??
              'Compte indisponible';
        }
        item = item.copyWith(residentName: names[id]);
      }
      result.add(
        hidePrices ? item.copyWith(price: 0, priceConfirmed: false) : item,
      );
    }
    return result;
  }

  Future<List<LaundryItem>> getAll() =>
      _authorized(_staff, (db, actor, role) async {
        var rows = await db.query(
          'laundry_items',
          orderBy: 'created_at DESC, id DESC',
        );
        if (role == LaundryRole.driver) {
          rows = rows
              .where(
                (row) =>
                    row['status'] == 'ready' || row['status'] == 'delivered',
              )
              .toList();
        }
        return _resolve(db, rows, hidePrices: role == LaundryRole.driver);
      });

  Future<List<LaundryItem>> getByResidentId(int residentId) =>
      _authorized({LaundryRole.resident}, (db, actor, role) async {
        if (residentId != actor.id) {
          throw const LaundryException('Cette demande ne vous appartient pas.');
        }
        return _resolve(
          db,
          await db.query(
            'laundry_items',
            where: 'resident_id = ?',
            whereArgs: [actor.id],
            orderBy: 'created_at DESC, id DESC',
          ),
          hidePrices: true,
        );
      });

  void _checkRead(LaundryItem item, User actor, LaundryRole role) {
    if ((role == LaundryRole.resident && item.residentId != actor.id) ||
        (role == LaundryRole.driver &&
            item.status != LaundryStatus.ready &&
            item.status != LaundryStatus.delivered)) {
      throw const LaundryException('Cette demande ne vous est pas accessible.');
    }
  }

  Future<LaundryItem?> getById(String id) => _authorized(_allRoles, (
    db,
    actor,
    role,
  ) async {
    final item = await _find(db, id);
    if (item == null) return null;
    _checkRead(item, actor, role);
    return (await _resolve(
      db,
      [item.toMap()],
      hidePrices: role == LaundryRole.resident || role == LaundryRole.driver,
    )).single;
  });

  Future<LaundryItem?> _find(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'laundry_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : LaundryItem.fromMap(rows.single);
  }

  Future<LaundryItem> _require(DatabaseExecutor db, String id) async {
    final item = await _find(db, id);
    if (item == null) {
      throw const LaundryException('Cette demande n’existe plus.');
    }
    return item;
  }

  Future<User> _resident(DatabaseExecutor db, int? id) async {
    final user = id == null ? null : await _users.getUserById(id, executor: db);
    if (user == null || user.role != 'Résident') {
      throw const LaundryException('Sélectionnez un compte résident existant.');
    }
    return user;
  }

  void _validate(LaundryItem item) {
    if (item.id.trim().isEmpty ||
        item.serviceType.trim().isEmpty ||
        !item.price.isFinite ||
        item.price < 0) {
      throw const LaundryException('Vérifiez les informations de la demande.');
    }
  }

  void _checkAuthor(User actor, int? changedByUserId) {
    if (changedByUserId != null && changedByUserId != actor.id) {
      throw const LaundryException('L’auteur doit être le compte connecté.');
    }
  }

  Future<int> add(LaundryItem item, {int? changedByUserId}) =>
      _authorized({LaundryRole.admin}, (db, actor, role) async {
        _checkAuthor(actor, changedByUserId);
        return _insert(db, item, await _resident(db, item.residentId), actor);
      });
  Future<int> _insert(
    Transaction db,
    LaundryItem item,
    User resident,
    User actor,
  ) async {
    _validate(item);
    final row = item.toMap()
      ..['resident_id'] = resident.id
      ..['resident_name'] = resident.name;
    final result = await db.insert('laundry_items', row);
    await _record(db, item.id, null, item.status, actor.id!);
    return result;
  }

  Future<int> addForResident(LaundryItem item, {required int residentId}) =>
      _authorized({LaundryRole.resident}, (db, actor, role) async {
        if (residentId != actor.id ||
            (item.residentId != null && item.residentId != actor.id) ||
            item.status != LaundryStatus.deposited) {
          throw const LaundryException('Création de demande non autorisée.');
        }
        return _insert(
          db,
          item.copyWith(price: 0, priceConfirmed: false),
          actor,
          actor,
        );
      });
  Future<int> update(LaundryItem item, {int? changedByUserId}) => _authorized(
    {LaundryRole.admin},
    (db, actor, role) async {
      _checkAuthor(actor, changedByUserId);
      _validate(item);
      final current = await _require(db, item.id);
      if ((await LaundryStorage.lines(db, item.id)).isNotEmpty) {
        throw const LaundryException(
          'Modifiez les articles avec le formulaire détaillé.',
        );
      }
      if (item.residentId != null) await _resident(db, item.residentId);
      if (current.residentId != null && item.residentId == null) {
        throw const LaundryException('Un compte résident doit rester associé.');
      }
      final row = item.toMap()
        ..['resident_name'] = current.residentNameSnapshot
        ..['created_at'] = current.createdAt.toUtc().toIso8601String();
      row['revision'] =
          ((await db.query(
                    'laundry_items',
                    where: 'id = ?',
                    whereArgs: [item.id],
                  )).single['revision']
                  as int? ??
              0) +
          1;
      final result = await db.update(
        'laundry_items',
        row,
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (item.status != current.status) {
        await _record(db, item.id, current.status, item.status, actor.id!);
      }
      return result;
    },
  );
  void _checkResident(LaundryItem item, User actor) {
    if (item.residentId != actor.id || item.status != LaundryStatus.deposited) {
      throw const LaundryException(
        'Seules vos demandes déposées peuvent être modifiées ou supprimées.',
      );
    }
  }

  Future<int> updateForResident(LaundryItem item, {required int residentId}) =>
      _authorized({LaundryRole.resident}, (db, actor, role) async {
        if (residentId != actor.id) {
          throw const LaundryException('Compte résident non autorisé.');
        }
        _validate(item.copyWith(price: 0));
        final current = await _require(db, item.id);
        _checkResident(current, actor);
        if ((await LaundryStorage.lines(db, item.id)).isNotEmpty) {
          throw const LaundryException(
            'Modifiez les articles avec le formulaire détaillé.',
          );
        }
        return db.update(
          'laundry_items',
          {
            'service_type': item.serviceType,
            'revision':
                ((await db.query(
                          'laundry_items',
                          where: 'id = ?',
                          whereArgs: [item.id],
                        )).single['revision']
                        as int? ??
                    0) +
                1,
            if (item.serviceType != current.serviceType) 'price_confirmed': 0,
          },
          where: 'id = ? AND resident_id = ? AND status = ?',
          whereArgs: [item.id, actor.id, 'deposited'],
        );
      });
  Future<int> delete(String id) =>
      _authorized({LaundryRole.admin}, (db, actor, role) async {
        await _ensureNoComplaint(db, id);
        return db.delete('laundry_items', where: 'id = ?', whereArgs: [id]);
      });
  Future<int> deleteForResident(String id, {required int residentId}) =>
      _authorized({LaundryRole.resident}, (db, actor, role) async {
        if (residentId != actor.id) {
          throw const LaundryException('Compte résident non autorisé.');
        }
        _checkResident(await _require(db, id), actor);
        await _ensureNoComplaint(db, id);
        return db.delete(
          'laundry_items',
          where: 'id = ? AND resident_id = ? AND status = ?',
          whereArgs: [id, actor.id, 'deposited'],
        );
      });
  Future<void> transitionStatus(
    String id, {
    required LaundryStatus expectedStatus,
    required LaundryStatus newStatus,
    LaundryRole? role,
    int? changedByUserId,
  }) => _authorized({LaundryRole.pressing, LaundryRole.driver}, (
    db,
    actor,
    actualRole,
  ) async {
    _checkAuthor(actor, changedByUserId);
    if (role != null && role != actualRole) {
      throw const LaundryException('Rôle non autorisé.');
    }
    final allowed = actualRole == LaundryRole.pressing
        ? (expectedStatus == LaundryStatus.deposited &&
                  newStatus == LaundryStatus.processing) ||
              (expectedStatus == LaundryStatus.processing &&
                  newStatus == LaundryStatus.ready)
        : expectedStatus == LaundryStatus.ready &&
              newStatus == LaundryStatus.delivered;
    if (!allowed) {
      throw const LaundryException('Transition non autorisée pour ce rôle.');
    }
    final current = await _require(db, id);
    if (current.status != expectedStatus) {
      throw const LaundryException(
        'Le statut a changé. Actualisez les demandes.',
      );
    }
    final count = await db.update(
      'laundry_items',
      {
        'status': newStatus.name,
        'revision':
            ((await db.query(
                      'laundry_items',
                      where: 'id = ?',
                      whereArgs: [id],
                    )).single['revision']
                    as int? ??
                0) +
            1,
        'updated_at': _clock().toUtc().toIso8601String(),
      },
      where: 'id = ? AND status = ?',
      whereArgs: [id, expectedStatus.name],
    );
    if (count != 1) {
      throw const LaundryException(
        'Le statut a changé. Actualisez les demandes.',
      );
    }
    await _record(db, id, current.status, newStatus, actor.id!);
  });
  Future<List<LaundryStatusChange>> getStatusHistory(
    String id, {
    int? residentId,
  }) => _authorized(_allRoles, (db, actor, role) async {
    final item = await _require(db, id);
    _checkRead(item, actor, role);
    if (residentId != null &&
        (residentId != actor.id || item.residentId != actor.id)) {
      throw const LaundryException('Cette demande ne vous appartient pas.');
    }
    return (await LaundryStorage.history(
      db,
      id,
    )).map(LaundryStatusChange.fromMap).toList();
  });
  Future<void> _record(
    Transaction db,
    String id,
    LaundryStatus? oldStatus,
    LaundryStatus newStatus,
    int userId,
  ) async {
    await LaundryStorage.addHistory(db, {
      'laundry_id': id,
      'old_status': oldStatus?.name,
      'new_status': newStatus.name,
      'changed_by_user_id': userId,
      'changed_at': _clock().toUtc().toIso8601String(),
    });
  }
}
