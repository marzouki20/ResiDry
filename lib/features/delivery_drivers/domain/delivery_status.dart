/// Stable mission states used by persistence and business rules.
abstract final class DeliveryStatus {
  static const readyForPickup = 'À récupérer';
  static const outboundTransit = 'En transit';
  static const atLaundry = 'En lavage';
  static const returnTransit = 'En transit retour';
  static const depositedInLocker = 'Déposé au casier';
  static const delivered = 'Livré';

  static const values = <String>{
    readyForPickup,
    outboundTransit,
    atLaundry,
    returnTransit,
    depositedInLocker,
    delivered,
  };

  static bool isCompleted(String status) =>
      status == depositedInLocker || status == delivered;
}

/// Controls the only status transitions accepted by the delivery module.
abstract final class DeliveryMissionPolicy {
  static const _nextStatus = <String, String>{
    DeliveryStatus.readyForPickup: DeliveryStatus.outboundTransit,
    DeliveryStatus.outboundTransit: DeliveryStatus.atLaundry,
    DeliveryStatus.atLaundry: DeliveryStatus.returnTransit,
    DeliveryStatus.returnTransit: DeliveryStatus.depositedInLocker,
    DeliveryStatus.depositedInLocker: DeliveryStatus.delivered,
  };

  static String nextStatus(String currentStatus) {
    final next = _nextStatus[currentStatus];
    if (next == null) {
      throw StateError('La mission est déjà terminée.');
    }
    return next;
  }
}
