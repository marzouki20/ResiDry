enum LaundryPricingBasis { perItem, perKilogram }

enum LaundryQuoteIssue {
  missingRate,
  ambiguousRate,
  missingQuantity,
  missingWeight,
}

/// A configured tariff, not an account or another persistence model.
class LaundryRate {
  LaundryRate({
    required this.id,
    required this.serviceCode,
    required this.basis,
    required this.unitPriceMillimes,
    required DateTime validFrom,
    DateTime? validUntil,
  }) : validFrom = validFrom.toUtc(),
       validUntil = validUntil?.toUtc() {
    if (id.trim().isEmpty ||
        serviceCode.trim().isEmpty ||
        unitPriceMillimes < 0) {
      throw ArgumentError(
        'A tariff needs an ID, service and nonnegative price.',
      );
    }
    if (validUntil != null && !validUntil.isAfter(validFrom)) {
      throw ArgumentError('The tariff validity interval must be positive.');
    }
  }

  final String id;
  final String serviceCode;
  final LaundryPricingBasis basis;
  final int unitPriceMillimes;
  final DateTime validFrom;
  final DateTime? validUntil;

  bool appliesAt(DateTime instant) =>
      !instant.isBefore(validFrom) &&
      (validUntil == null || instant.isBefore(validUntil!));
}

/// An estimate only: confirmation and authorization belong to the repository.
class LaundryQuote {
  const LaundryQuote({
    required this.serviceCode,
    required this.basis,
    required this.evaluatedAt,
    this.rateId,
    this.unitPriceMillimes,
    this.quantity,
    this.weightGrams,
    this.totalMillimes,
    this.issue,
  });

  final String serviceCode;
  final LaundryPricingBasis basis;
  final DateTime evaluatedAt;
  final String? rateId;
  final int? unitPriceMillimes;
  final int? quantity;
  final int? weightGrams;
  final int? totalMillimes;
  final LaundryQuoteIssue? issue;

  bool get canCalculate => issue == null && totalMillimes != null;
}
