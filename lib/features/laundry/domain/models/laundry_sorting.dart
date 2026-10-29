import '../../../../models/laundry_item.dart';

enum LaundryColorFamily { white, light, dark }

enum LaundryFabric { cotton, linen, synthetic, wool, silk, blend, other }

enum LaundryWashCycle { normal, delicate, handWash, doNotWash }

enum LaundryDyeTransferRisk { unknown, low, high }

/// Observations checked against the actual garment's care label.
/// Missing values stay unknown; a garment name is never parsed as evidence.
class LaundrySortingProfile {
  const LaundrySortingProfile({
    this.color,
    this.fabric,
    this.cycle,
    this.maxTemperatureC,
    this.dyeTransferRisk = LaundryDyeTransferRisk.unknown,
    this.washSeparately,
    this.verifiedByUserId,
    this.verifiedAt,
  });

  final LaundryColorFamily? color;
  final LaundryFabric? fabric;
  final LaundryWashCycle? cycle;
  final int? maxTemperatureC;
  final LaundryDyeTransferRisk dyeTransferRisk;
  final bool? washSeparately;
  final int? verifiedByUserId;
  final DateTime? verifiedAt;
}

/// References an existing request and homogeneous lot, never a new user/order.
class LaundrySortingLot {
  const LaundrySortingLot({
    required this.requestId,
    required this.lineId,
    required this.garment,
    required this.serviceId,
    required this.status,
    required this.quantity,
    this.weightGrams,
    this.instructions = '',
    this.profile,
  });

  final String requestId, lineId, garment, serviceId, instructions;
  final LaundryStatus status;
  final int quantity;
  final int? weightGrams;
  final LaundrySortingProfile? profile;
}

enum LaundrySortingReason {
  treatmentAlreadyStarted,
  notAWashingService,
  careNotVerified,
  unknownColor,
  unknownFabric,
  unknownCycle,
  unknownTemperature,
  unknownDyeTransferRisk,
  unknownSeparationRequirement,
  specialInstructions,
  dyeTransferRisk,
  separateWashRequired,
  handWashOnly,
  washingProhibited,
}

class LaundrySortingReview {
  LaundrySortingReview({
    required this.lot,
    required Iterable<LaundrySortingReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final LaundrySortingLot lot;
  final List<LaundrySortingReason> reasons;
}

/// A compatibility suggestion, not a machine programme or capacity reservation.
/// Different requests remain traceable through each lot's requestId/lineId.
class LaundrySortingGroup {
  LaundrySortingGroup({
    required this.color,
    required this.fabric,
    required this.cycle,
    required this.maxTemperatureC,
    required Iterable<LaundrySortingLot> lots,
  }) : lots = List.unmodifiable(lots);

  final LaundryColorFamily color;
  final LaundryFabric fabric;
  final LaundryWashCycle cycle;
  final int maxTemperatureC;
  final List<LaundrySortingLot> lots;

  bool get canCombine => lots.length > 1;
  int get quantity => lots.fold(0, (sum, lot) => sum + lot.quantity);
  int? get weightGrams => lots.any((lot) => lot.weightGrams == null)
      ? null
      : lots.fold<int>(0, (sum, lot) => sum + lot.weightGrams!);
}

class LaundrySortingPlan {
  LaundrySortingPlan({
    required Iterable<LaundrySortingGroup> groups,
    required Iterable<LaundrySortingReview> reviews,
  }) : groups = List.unmodifiable(groups),
       reviews = List.unmodifiable(reviews);

  final List<LaundrySortingGroup> groups;
  final List<LaundrySortingReview> reviews;
}
