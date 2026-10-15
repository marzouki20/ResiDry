enum CapacityAssessment { reviewRequired, consistent, exceedsLimit }

class VehicleCapacityEvidence {
  const VehicleCapacityEvidence(
      {required this.imagePath,
      required this.source,
      required this.brand,
      required this.model,
      required this.year,
      required this.payloadKg,
      required this.reserveKg,
      required this.ownerConfirmed,
      this.backImagePath = '',
      this.registrationText = '',
      this.vehiclePhotoSource = '',
      this.supportingPaths = const {},
      this.verificationId,
      this.verifiedCapacity,
      this.verifiedVehicle,
      this.borrowed = false});
  final String imagePath;
  final String source;
  final String brand;
  final String model;
  final String year;
  final double? payloadKg;
  final double? reserveKg;
  final bool ownerConfirmed;
  final String backImagePath;
  final String registrationText;
  final String vehiclePhotoSource;
  final Map<String, String> supportingPaths;
  final String? verificationId;
  final double? verifiedCapacity;
  final String? verifiedVehicle;
  final bool borrowed;

  bool get hasValidYear {
    final value = int.tryParse(year.trim());
    return value != null && value >= 1900 && value <= DateTime.now().year + 1;
  }

  bool get hasValidReserve =>
      reserveKg != null && reserveKg!.isFinite && reserveKg! >= 0;
  bool get isReadyForSubmission =>
      imagePath.isNotEmpty &&
      backImagePath.isNotEmpty &&
      hasValidReserve &&
      ownerConfirmed;

  /// A complete submission can still require manual review when OCR fails.
  bool get isComplete =>
      brand.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      hasValidYear &&
      hasValidReserve &&
      imagePath.trim().isNotEmpty &&
      ownerConfirmed;

  factory VehicleCapacityEvidence.fromMap(Map<String, Object?> row) =>
      VehicleCapacityEvidence(
        imagePath: row['photo_path']! as String,
        source: row['photo_source']! as String,
        brand: row['brand']! as String,
        model: row['model']! as String,
        year: row['vehicle_year']! as String,
        payloadKg: (row['payload_kg'] as num?)?.toDouble(),
        reserveKg: (row['reserve_kg'] as num?)?.toDouble(),
        ownerConfirmed: row['owner_confirmed'] == 1,
        backImagePath: row['back_photo_path'] as String? ?? '',
        registrationText: row['registration_text'] as String? ?? '',
      );

  CapacityAssessment assess(double declaredKg) {
    if (imagePath.isEmpty ||
        payloadKg == null ||
        !payloadKg!.isFinite ||
        payloadKg! <= 0 ||
        payloadKg! > 10000 ||
        reserveKg == null ||
        !declaredKg.isFinite ||
        !reserveKg!.isFinite ||
        reserveKg! < 0 ||
        declaredKg <= 0) {
      return CapacityAssessment.reviewRequired;
    }
    if (declaredKg + reserveKg! > payloadKg!) {
      return CapacityAssessment.exceedsLimit;
    }
    final vehicleYear = int.tryParse(year);
    if (!ownerConfirmed ||
        brand.trim().isEmpty ||
        model.trim().isEmpty ||
        vehicleYear == null ||
        vehicleYear < 1900 ||
        vehicleYear > DateTime.now().year + 1) {
      return CapacityAssessment.reviewRequired;
    }
    return CapacityAssessment.consistent;
  }

  /// Only explicitly labelled payload values in kg are candidates.
  /// Gross mass, axle ratings, bare numbers and conflicting values need review.
  static double? extractPayload(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('à', 'a')
        .replaceAll('\u00a0', ' ');
    final pattern = RegExp(
        r'^\s*(?:maximum\s+payload|max\.?\s+payload|payload|charge\s+utile|cargo\s+capacity)\s*[:=\-]?\s*(\d{1,3}(?:[ ,]\d{3})+(?:[.,]\d+)?|\d+(?:[.,]\d+)?)\s*kg\b',
        multiLine: true);
    final values = <double>{};
    for (final match in pattern.allMatches(normalized)) {
      var number = match[1]!.replaceAll(' ', '');
      if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(number)) {
        number = number.replaceAll(',', '');
      } else {
        number = number.replaceAll(',', '.');
      }
      final value = double.tryParse(number);
      if (value != null && value > 0 && value <= 10000) values.add(value);
    }
    return values.length == 1 ? values.single : null;
  }
}
