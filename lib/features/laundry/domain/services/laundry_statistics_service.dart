import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_status_change.dart';
import '../models/laundry_statistics.dart';
import '../models/laundry_workload.dart';
import 'tracking_service.dart';

/// Aggregates only the caller's already-authorized data scope.
/// This pure calculator never reads accounts or grants financial permissions.
class LaundryStatisticsService {
  const LaundryStatisticsService();

  LaundryStatistics summarize(
    Iterable<LaundryWorkload> workloads, {
    required DateTime now,
    Map<String, List<LaundryStatusChange>> historyByLaundryId = const {},
    bool includeFinancials = false,
  }) {
    final inputs = workloads.toList();
    if (inputs.map((w) => w.item.id).toSet().length != inputs.length) {
      throw ArgumentError('Each request must occur only once in statistics.');
    }
    const tracking = TrackingService();
    var active = 0;
    var ready = 0;
    var delivered = 0;
    var overdue = 0;
    var atRisk = 0;
    var missingDeadline = 0;
    var missingEstimate = 0;
    var measured = 0;
    var unmeasured = 0;
    var processingMicroseconds = 0;
    var confirmedDeliveredValue = 0;
    var unconfirmedDelivered = 0;
    final serviceCounts = <String, int>{};
    for (final workload in inputs) {
      final item = workload.item;
      final timing = tracking.assess(workload, now: now);
      serviceCounts.update(
        item.serviceType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (workload.needsTreatment) {
        active++;
        if (timing.isOverdue) overdue++;
        if (!timing.isOverdue && timing.isAtRisk == true) atRisk++;
        if (workload.treatmentDueAt == null) missingDeadline++;
        if (workload.estimatedRemainingTreatment == null) missingEstimate++;
      } else {
        if (item.status == LaundryStatus.ready) ready++;
        if (item.status == LaundryStatus.delivered) delivered++;
        final duration = tracking.processingDuration(
          item,
          historyByLaundryId[item.id] ?? const [],
          now: now,
        );
        if (duration == null) {
          unmeasured++;
        } else {
          measured++;
          processingMicroseconds += duration.inMicroseconds;
        }
      }
      if (includeFinancials && item.status == LaundryStatus.delivered) {
        if (!item.priceConfirmed) {
          unconfirmedDelivered++;
        } else {
          // Compatibility boundary: historical shared models still use DT REAL.
          // New quotations calculate in integer millimes before persistence.
          final scaled = item.price * 1000;
          if (!scaled.isFinite || scaled < 0 || scaled > 9007199254740991) {
            throw ArgumentError('The confirmed request price is invalid.');
          }
          final amount = scaled.round();
          if (confirmedDeliveredValue > 9007199254740991 - amount) {
            throw RangeError(
              'The financial total exceeds the exact integer range.',
            );
          }
          confirmedDeliveredValue += amount;
        }
      }
    }
    final popular =
        [
          for (final entry in serviceCounts.entries)
            LaundryServicePopularity(
              serviceCode: entry.key,
              requests: entry.value,
            ),
        ]..sort((a, b) {
          final count = b.requests.compareTo(a.requests);
          return count != 0 ? count : a.serviceCode.compareTo(b.serviceCode);
        });
    return LaundryStatistics(
      totalRequests: inputs.length,
      activeTreatmentRequests: active,
      awaitingDeliveryRequests: ready,
      deliveredRequests: delivered,
      overdueTreatmentRequests: overdue,
      atRiskTreatmentRequests: atRisk,
      missingDeadlineRequests: missingDeadline,
      missingEstimateRequests: missingEstimate,
      measurableProcessingRequests: measured,
      unmeasuredCompletedRequests: unmeasured,
      averageProcessingTime: measured == 0
          ? null
          : Duration(microseconds: (processingMicroseconds / measured).round()),
      popularServices: popular,
      confirmedDeliveredValueMillimes: includeFinancials
          ? confirmedDeliveredValue
          : null,
      unconfirmedDeliveredRequests: includeFinancials
          ? unconfirmedDelivered
          : null,
    );
  }
}
