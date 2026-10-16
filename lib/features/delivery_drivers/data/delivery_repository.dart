import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';

abstract interface class DeliveryRepository {
  Future<List<DeliveryDriver>> getDrivers();

  Future<List<DeliveryOrder>> getMissions({String? driverName});

  Future<void> assignMission({
    required String missionId,
    required String driverId,
  });

  Future<DeliveryOrder> advanceMission(String missionId);
}
