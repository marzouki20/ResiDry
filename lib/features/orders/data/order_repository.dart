library residry.orders.data.order_repository;

import '../domain/models/alerte_commande.dart';
import '../domain/models/garment.dart';
import '../domain/models/rfid_read_event.dart';
import '../domain/models/rfid_tag.dart';

abstract class OrderRepository {
  Future<List<Garment>> getGarmentsByCommande(String commandeId);
  Future<Garment?> getGarmentById(String id);
  Future<int> insertGarment(Garment garment);
  Future<int> updateGarment(Garment garment, String id);
  Future<int> deleteGarment(String id);

  Future<List<RfidTag>> getRfidTagsByCommande(String commandeId);
  Future<RfidTag?> getRfidTagById(String tagId);
  Future<int> insertRfidTag(RfidTag tag);
  Future<int> updateRfidTag(RfidTag tag, String tagId);

  Future<List<RfidReadEvent>> getRfidReadEventsByTag(String tagId);
  Future<List<RfidReadEvent>> getRfidReadEventsByCommande(String commandeId);
  Future<int> insertRfidReadEvent(RfidReadEvent event);

  Future<List<AlerteCommande>> getUnreadAlerts();
  Future<List<AlerteCommande>> getAlertsByCommande(String commandeId);
  Future<int> insertAlerteCommande(AlerteCommande alerte);
  Future<int> markAlertRead(int alertId);
  Future<int> deleteAlerteCommande(int alertId);
}
