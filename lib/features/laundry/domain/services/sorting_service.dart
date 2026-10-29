import '../../../../models/laundry_item.dart';
import '../models/laundry_sorting.dart';

/// Conservative, deterministic compatibility rules. No textile properties are
/// inferred from garment names, no machine capacity or customer consent assumed.
class SortingService {
  const SortingService();

  LaundrySortingPlan propose(
    Iterable<LaundrySortingLot> lots, {
    required DateTime now,
  }) {
    final inputs = lots.toList()
      ..sort((a, b) {
        final request = a.requestId.compareTo(b.requestId);
        return request == 0 ? a.lineId.compareTo(b.lineId) : request;
      });
    final seen = <(String, String)>{};
    final candidates = <String, List<LaundrySortingLot>>{};
    final reviews = <LaundrySortingReview>[];
    for (final lot in inputs) {
      if (lot.requestId.trim().isEmpty ||
          lot.lineId.trim().isEmpty ||
          lot.garment.trim().isEmpty ||
          lot.quantity <= 0 ||
          (lot.weightGrams != null && lot.weightGrams! <= 0) ||
          !seen.add((lot.requestId, lot.lineId))) {
        throw ArgumentError('Each lot must be valid and occur only once.');
      }
      final reasons = _reviewReasons(lot, now);
      if (reasons.isNotEmpty) {
        reviews.add(LaundrySortingReview(lot: lot, reasons: reasons));
        continue;
      }
      final profile = lot.profile!;
      // Exact equality is intentional: no substitution of wash programmes or
      // inference that two different care temperatures are interchangeable.
      // Keep customers' requests separate until an explicit mixing policy exists.
      final key =
          '${lot.requestId}:${profile.color!.name}:${profile.fabric!.name}:'
          '${profile.cycle!.name}:${profile.maxTemperatureC}';
      candidates.putIfAbsent(key, () => []).add(lot);
    }
    final groups = candidates.values.map((members) {
      final profile = members.first.profile!;
      return LaundrySortingGroup(
        color: profile.color!,
        fabric: profile.fabric!,
        cycle: profile.cycle!,
        maxTemperatureC: profile.maxTemperatureC!,
        lots: members,
      );
    });
    return LaundrySortingPlan(groups: groups, reviews: reviews);
  }

  List<LaundrySortingReason> _reviewReasons(
    LaundrySortingLot lot,
    DateTime now,
  ) {
    final profile = lot.profile;
    return [
      if (lot.status != LaundryStatus.deposited)
        LaundrySortingReason.treatmentAlreadyStarted,
      if (lot.serviceId != 'washing') LaundrySortingReason.notAWashingService,
      if (profile == null ||
          profile.verifiedByUserId == null ||
          profile.verifiedByUserId! <= 0 ||
          profile.verifiedAt == null ||
          profile.verifiedAt!.isAfter(now))
        LaundrySortingReason.careNotVerified,
      if (profile?.color == null) LaundrySortingReason.unknownColor,
      // "Blend" and "other" do not establish the actual fibre composition.
      if (profile?.fabric == null ||
          profile?.fabric == LaundryFabric.blend ||
          profile?.fabric == LaundryFabric.other)
        LaundrySortingReason.unknownFabric,
      if (profile?.cycle == null) LaundrySortingReason.unknownCycle,
      if (profile?.maxTemperatureC == null ||
          profile!.maxTemperatureC! < 1 ||
          profile.maxTemperatureC! > 95)
        LaundrySortingReason.unknownTemperature,
      if (profile == null ||
          profile.dyeTransferRisk == LaundryDyeTransferRisk.unknown)
        LaundrySortingReason.unknownDyeTransferRisk,
      if (profile?.washSeparately == null)
        LaundrySortingReason.unknownSeparationRequirement,
      if (lot.instructions.trim().isNotEmpty)
        LaundrySortingReason.specialInstructions,
      if (profile?.dyeTransferRisk == LaundryDyeTransferRisk.high)
        LaundrySortingReason.dyeTransferRisk,
      if (profile?.washSeparately == true)
        LaundrySortingReason.separateWashRequired,
      if (profile?.cycle == LaundryWashCycle.handWash)
        LaundrySortingReason.handWashOnly,
      if (profile?.cycle == LaundryWashCycle.doNotWash)
        LaundrySortingReason.washingProhibited,
    ];
  }
}
