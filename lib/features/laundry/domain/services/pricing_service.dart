import '../models/laundry_quote.dart';

/// Integer arithmetic, half-up rounding to a millime, no invented tariffs.
class PricingService {
  const PricingService();

  static const _maxExactInteger = 9007199254740991;

  LaundryQuote calculate({
    required String serviceCode,
    required LaundryPricingBasis basis,
    required Iterable<LaundryRate> rates,
    required DateTime now,
    int? quantity,
    int? weightGrams,
  }) {
    if (serviceCode.trim().isEmpty ||
        (quantity != null && quantity <= 0) ||
        (weightGrams != null && weightGrams <= 0)) {
      throw ArgumentError('Service, quantity and weight must be valid.');
    }
    final instant = now.toUtc();
    final matching = rates
        .where(
          (rate) =>
              rate.serviceCode == serviceCode &&
              rate.basis == basis &&
              rate.appliesAt(instant),
        )
        .toList();

    LaundryQuote unavailable(LaundryQuoteIssue issue) => LaundryQuote(
      serviceCode: serviceCode,
      basis: basis,
      evaluatedAt: instant,
      quantity: quantity,
      weightGrams: weightGrams,
      issue: issue,
    );

    if (matching.isEmpty) return unavailable(LaundryQuoteIssue.missingRate);
    if (matching.length != 1) {
      return unavailable(LaundryQuoteIssue.ambiguousRate);
    }
    if (basis == LaundryPricingBasis.perItem && quantity == null) {
      return unavailable(LaundryQuoteIssue.missingQuantity);
    }
    if (basis == LaundryPricingBasis.perKilogram && weightGrams == null) {
      return unavailable(LaundryQuoteIssue.missingWeight);
    }

    final rate = matching.single;
    final units = basis == LaundryPricingBasis.perItem
        ? quantity!
        : weightGrams!;
    // Keep results exact on native Dart and future JavaScript adapters alike.
    final rounding = basis == LaundryPricingBasis.perKilogram ? 500 : 0;
    if (units > _maxExactInteger ||
        rate.unitPriceMillimes > (_maxExactInteger - rounding) ~/ units) {
      throw RangeError('The amount exceeds the supported exact integer range.');
    }
    final product = rate.unitPriceMillimes * units;
    final total = basis == LaundryPricingBasis.perItem
        ? product
        : (product + rounding) ~/ 1000;
    return LaundryQuote(
      serviceCode: serviceCode,
      basis: basis,
      evaluatedAt: instant,
      rateId: rate.id,
      unitPriceMillimes: rate.unitPriceMillimes,
      quantity: quantity,
      weightGrams: weightGrams,
      totalMillimes: total,
    );
  }
}
