import 'package:flutter_test/flutter_test.dart';

import 'package:ttttttteee/features/laundry/domain/models/laundry_quote.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_workload.dart';
import 'package:ttttttteee/features/laundry/domain/services/pricing_service.dart';
import 'package:ttttttteee/features/laundry/domain/services/planning_service.dart';
import 'package:ttttttteee/features/laundry/domain/services/tracking_service.dart';
import 'package:ttttttteee/features/laundry/domain/services/laundry_statistics_service.dart';
import 'package:ttttttteee/models/laundry_item.dart';
import 'package:ttttttteee/models/laundry_status_change.dart';

final now = DateTime.utc(2026, 10, 24, 12);

LaundryItem item(
  String id, {
  LaundryStatus status = LaundryStatus.deposited,
  DateTime? createdAt,
  String service = 'washing',
  double price = 15,
  bool confirmed = false,
}) => LaundryItem(
  id: id,
  residentName: 'Test fixture',
  serviceType: service,
  status: status,
  price: price,
  priceConfirmed: confirmed,
  createdAt: createdAt ?? now.subtract(const Duration(days: 2)),
);

LaundryRate rate({
  String id = 'R',
  String service = 'washing',
  int amount = 5000,
  LaundryPricingBasis basis = LaundryPricingBasis.perKilogram,
  DateTime? from,
  DateTime? until,
}) => LaundryRate(
  id: id,
  serviceCode: service,
  basis: basis,
  unitPriceMillimes: amount,
  validFrom: from ?? now.subtract(const Duration(days: 1)),
  validUntil: until,
);

List<LaundryStatusChange> history(
  String id, {
  bool delivered = false,
  int processingMinutes = 90,
}) {
  final start = now.subtract(Duration(minutes: processingMinutes + 30));
  return [
    LaundryStatusChange(
      id: 1,
      laundryId: id,
      oldStatus: null,
      newStatus: LaundryStatus.deposited,
      changedByUserId: null,
      changedAt: start.subtract(const Duration(minutes: 20)),
    ),
    LaundryStatusChange(
      id: 2,
      laundryId: id,
      oldStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
      changedByUserId: null,
      changedAt: start,
    ),
    LaundryStatusChange(
      id: 3,
      laundryId: id,
      oldStatus: LaundryStatus.processing,
      newStatus: LaundryStatus.ready,
      changedByUserId: null,
      changedAt: start.add(Duration(minutes: processingMinutes)),
    ),
    if (delivered)
      LaundryStatusChange(
        id: 4,
        laundryId: id,
        oldStatus: LaundryStatus.ready,
        newStatus: LaundryStatus.delivered,
        changedByUserId: null,
        changedAt: now,
      ),
  ];
}

void main() {
  group('Exact and explained pricing', () {
    const pricing = PricingService();
    LaundryQuote quote(
      List<LaundryRate> rates, {
      int? grams = 3000,
      int? quantity,
      LaundryPricingBasis basis = LaundryPricingBasis.perKilogram,
    }) => pricing.calculate(
      serviceCode: 'washing',
      basis: basis,
      rates: rates,
      now: now,
      weightGrams: grams,
      quantity: quantity,
    );

    test('3 kg at 5 DT/kg gives 15 DT with tariff provenance', () {
      final result = quote([rate()]);
      expect(result.canCalculate, isTrue);
      expect(result.totalMillimes, 15000);
      expect(result.rateId, 'R');
      expect(result.unitPriceMillimes, 5000);
      expect(result.weightGrams, 3000);
      expect(result.evaluatedAt, now);
    });

    test('piece pricing depends on quantity, not supplied weight', () {
      final result = quote(
        [rate(basis: LaundryPricingBasis.perItem, amount: 2500)],
        quantity: 3,
        grams: 9000,
        basis: LaundryPricingBasis.perItem,
      );
      expect(result.totalMillimes, 7500);
    });

    test('fractional kilograms round half up once, at the millime', () {
      expect(quote([rate(amount: 1)], grams: 499).totalMillimes, 0);
      expect(quote([rate(amount: 1)], grams: 500).totalMillimes, 1);
      expect(quote([rate(amount: 3333)], grams: 1250).totalMillimes, 4166);
    });

    test('validity includes its start and excludes its end', () {
      final old = rate(id: 'old', until: now);
      final current = rate(id: 'new', from: now, amount: 6000);
      expect(quote([old, current]).rateId, 'new');
      expect(quote([old]).issue, LaundryQuoteIssue.missingRate);
    });

    test('a different service, basis or future rule is never substituted', () {
      final result = quote([
        rate(service: 'ironing'),
        rate(basis: LaundryPricingBasis.perItem),
        rate(from: now.add(const Duration(days: 1))),
      ]);
      expect(result.issue, LaundryQuoteIssue.missingRate);
      expect(result.totalMillimes, isNull);
    });

    test(
      'overlapping rates are rejected rather than choosing the cheapest',
      () {
        expect(
          quote([rate(), rate(id: 'other', amount: 100)]).issue,
          LaundryQuoteIssue.ambiguousRate,
        );
      },
    );

    test('unknown measurements produce an unavailable estimate, not zero', () {
      expect(
        quote([rate()], grams: null).issue,
        LaundryQuoteIssue.missingWeight,
      );
      expect(
        quote([
          rate(basis: LaundryPricingBasis.perItem),
        ], basis: LaundryPricingBasis.perItem).issue,
        LaundryQuoteIssue.missingQuantity,
      );
    });

    test('a configured free service remains a valid estimate', () {
      expect(quote([rate(amount: 0)]).totalMillimes, 0);
      expect(quote([rate(amount: 0)]).canCalculate, isTrue);
    });

    test('invalid rates and measurements fail before calculation', () {
      expect(() => rate(amount: -1), throwsArgumentError);
      expect(() => rate(from: now, until: now), throwsArgumentError);
      expect(() => quote([rate()], grams: 0), throwsArgumentError);
      expect(() => quote([rate()], quantity: -2), throwsArgumentError);
      expect(
        () => pricing.calculate(
          serviceCode: '',
          basis: LaundryPricingBasis.perItem,
          rates: [],
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('oversized products cannot silently overflow', () {
      expect(
        () => quote([rate(amount: 9007199254740991)], grams: 2000),
        throwsRangeError,
      );
    });
  });

  group('Treatment deadlines and measurable history', () {
    const tracking = TrackingService();

    test('an unfinished request is late strictly after its deadline', () {
      final work = LaundryWorkload(item: item('A'), treatmentDueAt: now);
      expect(tracking.assess(work, now: now).isOverdue, isFalse);
      expect(
        tracking
            .assess(work, now: now.add(const Duration(seconds: 1)))
            .isOverdue,
        isTrue,
      );
    });

    test(
      'future deadline risk uses remaining treatment time and reports slack',
      () {
        final work = LaundryWorkload(
          item: item('A'),
          treatmentDueAt: now.add(const Duration(minutes: 30)),
          estimatedRemainingTreatment: const Duration(minutes: 45),
        );
        final result = tracking.assess(work, now: now);
        expect(result.isOverdue, isFalse);
        expect(result.isAtRisk, isTrue);
        expect(result.slack, const Duration(minutes: -15));
        expect(result.expectedReadyAt, now.add(const Duration(minutes: 45)));
      },
    );

    test('completion exactly at the deadline is not a predicted miss', () {
      final work = LaundryWorkload(
        item: item('A'),
        treatmentDueAt: now.add(const Duration(minutes: 30)),
        estimatedRemainingTreatment: const Duration(minutes: 30),
      );
      expect(tracking.assess(work, now: now).isAtRisk, isFalse);
    });

    test('ready and delivered requests are not current treatment delays', () {
      for (final status in [LaundryStatus.ready, LaundryStatus.delivered]) {
        final work = LaundryWorkload(
          item: item('A', status: status),
          treatmentDueAt: now.subtract(const Duration(hours: 1)),
        );
        expect(tracking.assess(work, now: now).isOverdue, isFalse);
        expect(tracking.assess(work, now: now).expectedReadyAt, isNull);
      }
    });

    test('missing deadlines or estimates keep risk unknown', () {
      expect(
        tracking.assess(LaundryWorkload(item: item('A')), now: now).isAtRisk,
        isNull,
      );
      final work = LaundryWorkload(item: item('A'), treatmentDueAt: now);
      expect(tracking.assess(work, now: now).isAtRisk, isNull);
      expect(
        tracking.assess(work, now: now.add(const Duration(hours: 1))).isOverdue,
        isTrue,
      );
    });

    test('invalid temporal inputs are rejected', () {
      expect(
        () => LaundryWorkload(
          item: item('A'),
          estimatedRemainingTreatment: const Duration(minutes: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => LaundryWorkload(
          item: item('A'),
          treatmentDueAt: now.subtract(const Duration(days: 3)),
        ),
        throwsArgumentError,
      );
      expect(
        () => tracking.assess(
          LaundryWorkload(
            item: item('A', createdAt: now.add(const Duration(days: 1))),
          ),
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('processing duration excludes queue and delivery waiting', () {
      final request = item('A', status: LaundryStatus.delivered);
      expect(
        tracking.processingDuration(
          request,
          history('A', delivered: true),
          now: now,
        ),
        const Duration(minutes: 90),
      );
    });

    test('legacy authors may be unknown without inventing their identity', () {
      expect(
        tracking.processingDuration(
          item('A', status: LaundryStatus.ready),
          history('A').reversed,
          now: now,
        ),
        const Duration(minutes: 90),
      );
    });

    test(
      'missing, unrelated, incomplete or stale histories are not measured',
      () {
        final request = item('A', status: LaundryStatus.ready);
        expect(tracking.processingDuration(request, [], now: now), isNull);
        expect(
          tracking.processingDuration(request, history('B'), now: now),
          isNull,
        );
        expect(
          tracking.processingDuration(request, history('A').skip(1), now: now),
          isNull,
        );
        expect(
          tracking.processingDuration(request, history('A').take(2), now: now),
          isNull,
        );
        expect(
          tracking.processingDuration(request, [
            ...history('A'),
            history('A').last,
          ], now: now),
          isNull,
        );
      },
    );
  });

  group('Deterministic treatment prioritization', () {
    const planning = PlanningService();
    test('late, predicted miss, deadline, urgency, age and ID give stable ordering', () {
      final workloads = [
        LaundryWorkload(
          item: item('next-week'),
          treatmentDueAt: now.add(const Duration(days: 7)),
        ),
        LaundryWorkload(item: item('urgent'), urgency: LaundryUrgency.urgent),
        LaundryWorkload(
          item: item('tomorrow'),
          treatmentDueAt: now.add(const Duration(days: 1)),
        ),
        LaundryWorkload(
          item: item('risk'),
          treatmentDueAt: now.add(const Duration(hours: 2)),
          estimatedRemainingTreatment: const Duration(hours: 3),
        ),
        LaundryWorkload(
          item: item('late'),
          treatmentDueAt: now.subtract(const Duration(hours: 1)),
        ),
        LaundryWorkload(item: item('B')),
        LaundryWorkload(item: item('A')),
      ];
      final result = planning.prioritize(workloads, now: now);
      expect(result.map((r) => r.workload.item.id), [
        'late',
        'risk',
        'tomorrow',
        'next-week',
        'urgent',
        'A',
        'B',
      ]);
      expect(result.first.reasons, contains(LaundryPriorityReason.overdue));
      expect(
        result[1].reasons,
        contains(LaundryPriorityReason.estimatedDeadlineMiss),
      );
      expect(result.last.reasons, contains(LaundryPriorityReason.noDeadline));
      expect(workloads.first.item.id, 'next-week');
      expect(() => result.clear(), throwsUnsupportedError);
    });

    test('submission time breaks otherwise equal priorities', () {
      final result = planning.prioritize([
        LaundryWorkload(
          item: item('new', createdAt: now.subtract(const Duration(hours: 1))),
        ),
        LaundryWorkload(item: item('old')),
      ], now: now);
      expect(result.first.workload.item.id, 'old');
    });

    test(
      'already ready and delivered requests are excluded from treatment queue',
      () {
        final result = planning.prioritize([
          LaundryWorkload(item: item('ready', status: LaundryStatus.ready)),
          LaundryWorkload(
            item: item('delivered', status: LaundryStatus.delivered),
          ),
        ], now: now);
        expect(result, isEmpty);
      },
    );

    test('duplicates cannot receive multiple queue positions', () {
      expect(
        () => planning.prioritize([
          LaundryWorkload(item: item('A')),
          LaundryWorkload(item: item('A')),
        ], now: now),
        throwsArgumentError,
      );
    });
  });

  group('Honest dashboard statistics', () {
    const statistics = LaundryStatisticsService();

    test('empty input has no invented duration or financial data', () {
      final result = statistics.summarize([], now: now);
      expect(result.totalRequests, 0);
      expect(result.averageProcessingTime, isNull);
      expect(result.confirmedDeliveredValueMillimes, isNull);
      expect(result.popularServices, isEmpty);
    });

    test(
      'counts scoped requests, current delays, risk and missing information',
      () {
        final result = statistics.summarize([
          LaundryWorkload(
            item: item('late'),
            treatmentDueAt: now.subtract(const Duration(hours: 1)),
          ),
          LaundryWorkload(
            item: item('risk', status: LaundryStatus.processing),
            treatmentDueAt: now.add(const Duration(hours: 1)),
            estimatedRemainingTreatment: const Duration(hours: 2),
          ),
          LaundryWorkload(item: item('unknown')),
          LaundryWorkload(
            item: item(
              'ready',
              status: LaundryStatus.ready,
              service: 'ironing',
            ),
          ),
          LaundryWorkload(
            item: item(
              'delivered',
              status: LaundryStatus.delivered,
              confirmed: true,
            ),
          ),
        ], now: now);
        expect(result.totalRequests, 5);
        expect(result.activeTreatmentRequests, 3);
        expect(result.awaitingDeliveryRequests, 1);
        expect(result.deliveredRequests, 1);
        expect(result.overdueTreatmentRequests, 1);
        expect(result.atRiskTreatmentRequests, 1);
        expect(result.missingDeadlineRequests, 1);
        expect(result.missingEstimateRequests, 2);
        expect(result.popularServices.first.serviceCode, 'washing');
        expect(result.popularServices.first.requests, 4);
        expect(result.confirmedDeliveredValueMillimes, isNull);
      },
    );

    test(
      'confirmed delivered value excludes unfinished and unconfirmed amounts',
      () {
        final result = statistics.summarize(
          [
            LaundryWorkload(
              item: item(
                'delivered',
                status: LaundryStatus.delivered,
                confirmed: true,
              ),
            ),
            LaundryWorkload(
              item: item(
                'unconfirmed',
                status: LaundryStatus.delivered,
                price: 99,
              ),
            ),
            LaundryWorkload(
              item: item(
                'ready',
                status: LaundryStatus.ready,
                price: 40,
                confirmed: true,
              ),
            ),
          ],
          now: now,
          includeFinancials: true,
        );
        expect(result.confirmedDeliveredValueMillimes, 15000);
        expect(result.unconfirmedDeliveredRequests, 1);
      },
    );

    test(
      'average uses complete histories and exposes sample size and unknowns',
      () {
        final result = statistics.summarize(
          [
            LaundryWorkload(item: item('A', status: LaundryStatus.ready)),
            LaundryWorkload(item: item('B', status: LaundryStatus.delivered)),
            LaundryWorkload(item: item('legacy', status: LaundryStatus.ready)),
          ],
          now: now,
          historyByLaundryId: {
            'A': history('A', processingMinutes: 60),
            'B': history('B', delivered: true, processingMinutes: 120),
          },
        );
        expect(result.averageProcessingTime, const Duration(minutes: 90));
        expect(result.measurableProcessingRequests, 2);
        expect(result.unmeasuredCompletedRequests, 1);
      },
    );

    test('duplicate requests are rejected to prevent inflated statistics', () {
      expect(
        () => statistics.summarize([
          LaundryWorkload(item: item('A')),
          LaundryWorkload(item: item('A')),
        ], now: now),
        throwsArgumentError,
      );
    });

    test('invalid confirmed money is never silently counted', () {
      expect(
        () => statistics.summarize(
          [
            LaundryWorkload(
              item: item(
                'A',
                status: LaundryStatus.delivered,
                confirmed: true,
                price: double.nan,
              ),
            ),
          ],
          now: now,
          includeFinancials: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
