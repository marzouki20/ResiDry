library residry.orders.data.sqlite_order_repository;

import 'package:sqflite/sqflite.dart';

import 'order_repository.dart';
import '../../../../database/database.dart';
import '../domain/models/alerte_commande.dart';
import '../domain/models/garment.dart';
import '../domain/models/rfid_read_event.dart';
import '../domain/models/rfid_tag.dart';

class SqliteOrderRepository implements OrderRepository {
  SqliteOrderRepository({DatabaseProvider? databaseProvider})
      : _databaseProvider =
            databaseProvider ?? (() => AppDatabase.instance.database);

  final DatabaseProvider _databaseProvider;

  @override
  Future<List<Garment>> getGarmentsByCommande(String commandeId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'garments',
      where: 'commande_id = ?',
      whereArgs: [commandeId],
    );
    return rows.map(Garment.fromMap).toList(growable: false);
  }

  @override
  Future<Garment?> getGarmentById(String id) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'garments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Garment.fromMap(rows.first);
  }

  @override
  Future<int> insertGarment(Garment garment) async {
    final database = await _databaseProvider();
    return database.insert('garments', garment.toMap());
  }

  @override
  Future<int> updateGarment(Garment garment, String id) async {
    final database = await _databaseProvider();
    return database.update(
      'garments',
      garment.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> deleteGarment(String id) async {
    final database = await _databaseProvider();
    return database.delete('garments', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RfidTag>> getRfidTagsByCommande(String commandeId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'rfid_tags',
      where: 'commande_id = ?',
      whereArgs: [commandeId],
    );
    return rows.map(RfidTag.fromMap).toList(growable: false);
  }

  @override
  Future<RfidTag?> getRfidTagById(String tagId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'rfid_tags',
      where: 'tag_id = ?',
      whereArgs: [tagId],
      limit: 1,
    );
    return rows.isEmpty ? null : RfidTag.fromMap(rows.first);
  }

  @override
  Future<int> insertRfidTag(RfidTag tag) async {
    final database = await _databaseProvider();
    return database.insert(
      'rfid_tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<int> updateRfidTag(RfidTag tag, String tagId) async {
    final database = await _databaseProvider();
    return database.update(
      'rfid_tags',
      tag.toMap(),
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
  }

  @override
  Future<List<RfidReadEvent>> getRfidReadEventsByTag(String tagId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'rfid_read_events',
      where: 'tag_id = ?',
      whereArgs: [tagId],
      orderBy: 'lu_le DESC',
    );
    return rows.map(RfidReadEvent.fromMap).toList(growable: false);
  }

  @override
  Future<List<RfidReadEvent>> getRfidReadEventsByCommande(
    String commandeId,
  ) async {
    final database = await _databaseProvider();
    final rows = await database.rawQuery('''
      SELECT r.* FROM rfid_read_events r
      JOIN rfid_tags t ON r.tag_id = t.tag_id
      WHERE t.commande_id = ?
      ORDER BY r.lu_le DESC
    ''', [commandeId]);
    return rows.map(RfidReadEvent.fromMap).toList(growable: false);
  }

  @override
  Future<int> insertRfidReadEvent(RfidReadEvent event) async {
    final database = await _databaseProvider();
    return database.insert('rfid_read_events', event.toMap());
  }

  @override
  Future<List<AlerteCommande>> getUnreadAlerts() async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'alertes_commandes',
      where: 'est_lue = 0',
      orderBy: 'date_creation DESC',
    );
    return rows.map(AlerteCommande.fromMap).toList(growable: false);
  }

  @override
  Future<List<AlerteCommande>> getAlertsByCommande(String commandeId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'alertes_commandes',
      where: 'commande_id = ?',
      whereArgs: [commandeId],
      orderBy: 'date_creation DESC',
    );
    return rows.map(AlerteCommande.fromMap).toList(growable: false);
  }

  @override
  Future<int> insertAlerteCommande(AlerteCommande alerte) async {
    final database = await _databaseProvider();
    return database.insert('alertes_commandes', alerte.toMap());
  }

  @override
  Future<int> markAlertRead(int alertId) async {
    final database = await _databaseProvider();
    return database.update(
      'alertes_commandes',
      {'est_lue': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  @override
  Future<int> deleteAlerteCommande(int alertId) async {
    final database = await _databaseProvider();
    return database.delete(
      'alertes_commandes',
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }
}

typedef DatabaseProvider = Future<Database> Function();
