import '../../domain/models/laundry_sorting.dart';

LaundrySortingProfile readSortingProfile(Map<String, Object?> row) =>
    LaundrySortingProfile(
      color: row['sorting_color'] == null
          ? null
          : LaundryColorFamily.values.byName(row['sorting_color'] as String),
      fabric: row['sorting_fabric'] == null
          ? null
          : LaundryFabric.values.byName(row['sorting_fabric'] as String),
      cycle: row['sorting_cycle'] == null
          ? null
          : LaundryWashCycle.values.byName(row['sorting_cycle'] as String),
      maxTemperatureC: row['sorting_max_temperature_c'] as int?,
      dyeTransferRisk: row['sorting_dye_transfer_risk'] == null
          ? LaundryDyeTransferRisk.unknown
          : LaundryDyeTransferRisk.values.byName(
              row['sorting_dye_transfer_risk'] as String,
            ),
      washSeparately: row['sorting_wash_separately'] == null
          ? null
          : row['sorting_wash_separately'] == 1,
      verifiedByUserId: row['sorting_verified_by_user_id'] as int?,
      verifiedAt: row['sorting_verified_at'] == null
          ? null
          : DateTime.parse(row['sorting_verified_at'] as String),
    );

/// One authorized SQLite snapshot, including the revisions used to reject stale edits.
class LaundrySortingData {
  LaundrySortingData({
    required Iterable<LaundrySortingLot> lots,
    required this.plan,
    required Map<String, int> revisions,
    required Iterable<String> requestsWithoutLots,
  }) : lots = List.unmodifiable(lots),
       revisions = Map.unmodifiable(revisions),
       requestsWithoutLots = List.unmodifiable(requestsWithoutLots);
  final List<LaundrySortingLot> lots;
  final LaundrySortingPlan plan;
  final Map<String, int> revisions;
  final List<String> requestsWithoutLots;
}
