class LaundryServicePopularity {
  const LaundryServicePopularity({
    required this.serviceCode,
    required this.requests,
  });
  final String serviceCode;
  final int requests;
}

class LaundryStatistics {
  LaundryStatistics({
    required this.totalRequests,
    required this.activeTreatmentRequests,
    required this.awaitingDeliveryRequests,
    required this.deliveredRequests,
    required this.overdueTreatmentRequests,
    required this.atRiskTreatmentRequests,
    required this.missingDeadlineRequests,
    required this.missingEstimateRequests,
    required this.measurableProcessingRequests,
    required this.unmeasuredCompletedRequests,
    required this.averageProcessingTime,
    required List<LaundryServicePopularity> popularServices,
    this.confirmedDeliveredValueMillimes,
    this.unconfirmedDeliveredRequests,
  }) : popularServices = List.unmodifiable(popularServices);

  final int totalRequests;
  final int activeTreatmentRequests;
  final int awaitingDeliveryRequests;
  final int deliveredRequests;
  final int overdueTreatmentRequests;

  /// Active future deadlines estimated to be missed; excludes current delays.
  final int atRiskTreatmentRequests;
  final int missingDeadlineRequests;
  final int missingEstimateRequests;
  final int measurableProcessingRequests;
  final int unmeasuredCompletedRequests;
  final Duration? averageProcessingTime;
  final List<LaundryServicePopularity> popularServices;

  /// Confirmed value of delivered requests, NOT receipts or payments.
  /// Null when financial calculation was not requested by an authorized caller.
  final int? confirmedDeliveredValueMillimes;
  final int? unconfirmedDeliveredRequests;
}
