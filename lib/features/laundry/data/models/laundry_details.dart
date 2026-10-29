import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_status_change.dart';
import '../../domain/models/laundry_quote.dart';
import '../../domain/models/laundry_workload.dart';

String basisCode(LaundryPricingBasis basis) =>
    basis == LaundryPricingBasis.perItem ? 'per_item' : 'per_kg';
LaundryPricingBasis readBasis(String code) => switch (code) {
  'per_item' => LaundryPricingBasis.perItem,
  'per_kg' => LaundryPricingBasis.perKilogram,
  _ => throw FormatException('Unknown pricing basis: $code'),
};

class LaundryServiceType {
  const LaundryServiceType({
    required this.id,
    required this.fr,
    required this.en,
    required this.ar,
  });
  final String id, fr, en, ar;
  String label(String language) => switch (language) {
    'ar' => ar,
    'en' => en,
    _ => fr,
  };
  factory LaundryServiceType.fromMap(Map<String, Object?> row) =>
      LaundryServiceType(
        id: row['id'] as String,
        fr: row['label_fr'] as String,
        en: row['label_en'] as String,
        ar: row['label_ar'] as String,
      );
}

class LaundryTariff {
  const LaundryTariff({required this.rate, this.estimatedMinutes});
  final LaundryRate rate;

  /// Configured treatment time for one homogeneous lot, not a machine capacity.
  final int? estimatedMinutes;
  factory LaundryTariff.fromMap(Map<String, Object?> row) => LaundryTariff(
    rate: LaundryRate(
      id: row['id'] as String,
      serviceCode: row['service_id'] as String,
      basis: readBasis(row['pricing_basis'] as String),
      unitPriceMillimes: row['unit_price_millimes'] as int,
      validFrom: DateTime.parse(row['valid_from'] as String),
      validUntil: row['valid_until'] == null
          ? null
          : DateTime.parse(row['valid_until'] as String),
    ),
    estimatedMinutes: row['estimated_minutes'] as int?,
  );
}

class LaundryLine {
  const LaundryLine({
    required this.id,
    required this.garment,
    required this.serviceId,
    required this.quantity,
    this.basis = LaundryPricingBasis.perKilogram,
    this.weightGrams,
    this.instructions = '',
    this.totalMillimes,
    this.unitPriceMillimes,
    this.tariffId,
    this.estimatedMinutes,
  });
  final String id, garment, serviceId, instructions;
  final int quantity;
  final LaundryPricingBasis basis;
  final int? weightGrams, totalMillimes, unitPriceMillimes, estimatedMinutes;
  final String? tariffId;
  factory LaundryLine.fromMap(
    Map<String, Object?> row, {
    bool hidePrices = false,
  }) => LaundryLine(
    id: row['id'] as String,
    garment: row['garment_type'] as String,
    serviceId: row['service_id'] as String,
    quantity: row['quantity'] as int,
    basis: readBasis(row['pricing_basis'] as String),
    weightGrams: row['weight_grams'] as int?,
    instructions: row['instructions'] as String,
    totalMillimes: hidePrices ? null : row['total_millimes'] as int?,
    unitPriceMillimes: hidePrices ? null : row['unit_price_millimes'] as int?,
    tariffId: hidePrices ? null : row['pricing_rule_id'] as String?,
    estimatedMinutes: row['estimated_minutes'] as int?,
  );
}

/// Additional Laundry data wraps the team's existing model, without duplicating it.
class LaundryDetails {
  LaundryDetails({
    required this.item,
    List<LaundryLine> lines = const [],
    this.dueAt,
    this.urgency = LaundryUrgency.normal,
    this.revision = 0,
    List<LaundryStatusChange> history = const [],
    Map<int, String> actorNames = const {},
  }) : lines = List.unmodifiable(lines),
       history = List.unmodifiable(history),
       actorNames = Map.unmodifiable(actorNames);
  final LaundryItem item;
  final List<LaundryLine> lines;
  final DateTime? dueAt;
  final LaundryUrgency urgency;
  final int revision;
  final List<LaundryStatusChange> history;
  final Map<int, String> actorNames;
  int? get estimatedMinutes =>
      lines.isEmpty || lines.any((line) => line.estimatedMinutes == null)
      ? null
      : lines.fold<int>(0, (sum, line) => sum + line.estimatedMinutes!);
  DateTime? get processingStart {
    final events =
        history.where((h) => h.newStatus == LaundryStatus.processing).toList()
          ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    return events.isEmpty ? null : events.last.changedAt;
  }

  LaundryWorkload workload(DateTime now) {
    Duration? remaining;
    if (estimatedMinutes != null && item.status == LaundryStatus.deposited) {
      remaining = Duration(minutes: estimatedMinutes!);
    } else if (estimatedMinutes != null &&
        item.status == LaundryStatus.processing &&
        processingStart != null) {
      final elapsed = now.difference(processingStart!);
      final value =
          Duration(minutes: estimatedMinutes!) -
          (elapsed.isNegative ? Duration.zero : elapsed);
      // Once the estimate is exceeded, remaining work is unknown, not zero.
      if (!value.isNegative) remaining = value;
    }
    return LaundryWorkload(
      item: item,
      treatmentDueAt: dueAt,
      urgency: urgency,
      estimatedRemainingTreatment: remaining,
    );
  }
}
