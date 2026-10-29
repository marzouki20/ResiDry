import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_sorting.dart';
import 'package:ttttttteee/features/laundry/domain/services/sorting_service.dart';
import 'package:ttttttteee/models/laundry_item.dart';

void main() {
  final now = DateTime.utc(2026, 10, 28, 10);
  const service = SortingService();
  LaundrySortingProfile profile({
    LaundryColorFamily? color = LaundryColorFamily.white,
    LaundryFabric? fabric = LaundryFabric.cotton,
    LaundryWashCycle? cycle = LaundryWashCycle.normal,
    int? temperature = 40,
    LaundryDyeTransferRisk risk = LaundryDyeTransferRisk.low,
    bool? separate = false,
    bool verified = true,
    DateTime? verifiedAt,
  }) => LaundrySortingProfile(
    color: color,
    fabric: fabric,
    cycle: cycle,
    maxTemperatureC: temperature,
    dyeTransferRisk: risk,
    washSeparately: separate,
    verifiedByUserId: verified ? 7 : null,
    verifiedAt: verified ? verifiedAt ?? now : null,
  );
  LaundrySortingLot lot(
    String id, {
    String request = 'REQUEST-1',
    String garment = 'Chemise blanche',
    String treatment = 'washing',
    LaundryStatus status = LaundryStatus.deposited,
    String instructions = '',
    int quantity = 2,
    int? weight = 500,
    LaundrySortingProfile? care,
  }) => LaundrySortingLot(
    requestId: request,
    lineId: id,
    garment: garment,
    serviceId: treatment,
    status: status,
    quantity: quantity,
    weightGrams: weight,
    instructions: instructions,
    profile: care,
  );

  test('matching verified lots form one traceable candidate group', () {
    final plan = service.propose([
      lot('B', care: profile()),
      lot('A', care: profile()),
    ], now: now);
    expect(plan.reviews, isEmpty);
    final group = plan.groups.single;
    expect(group.lots.map((l) => l.lineId), ['A', 'B']);
    expect(group.canCombine, isTrue);
    expect(group.quantity, 4);
    expect(group.weightGrams, 1000);
    expect(group.maxTemperatureC, 40);
    expect(() => group.lots.clear(), throwsUnsupportedError);
  });

  test(
    'colour fabric cycle and temperature each prevent an incompatible merge',
    () {
      final plan = service.propose([
        lot('A', care: profile()),
        lot('B', care: profile(color: LaundryColorFamily.dark)),
        lot('C', care: profile(fabric: LaundryFabric.linen)),
        lot('D', care: profile(cycle: LaundryWashCycle.delicate)),
        lot('E', care: profile(temperature: 30)),
      ], now: now);
      expect(plan.groups.length, 5);
      expect(plan.groups.every((g) => !g.canCombine), isTrue);
      expect(plan.reviews, isEmpty);
    },
  );

  test(
    'different requests remain separate even when all care properties match',
    () {
      final plan = service.propose([
        lot('A', request: 'REQUEST-1', care: profile()),
        lot('A', request: 'REQUEST-2', care: profile()),
      ], now: now);
      expect(plan.groups.length, 2);
      expect(plan.groups.every((g) => !g.canCombine), isTrue);
    },
  );

  test('garment names never establish fabric colour or care conditions', () {
    final plan = service.propose([lot('A')], now: now);
    expect(plan.groups, isEmpty);
    expect(
      plan.reviews.single.reasons,
      containsAll([
        LaundrySortingReason.careNotVerified,
        LaundrySortingReason.unknownColor,
        LaundrySortingReason.unknownFabric,
        LaundrySortingReason.unknownCycle,
        LaundrySortingReason.unknownTemperature,
        LaundrySortingReason.unknownDyeTransferRisk,
        LaundrySortingReason.unknownSeparationRequirement,
      ]),
    );
  });

  test(
    'missing observations and ambiguous fibre compositions require review',
    () {
      for (final care in [
        profile(color: null),
        profile(fabric: null),
        profile(fabric: LaundryFabric.blend),
        profile(fabric: LaundryFabric.other),
        profile(cycle: null),
        profile(temperature: null),
        profile(temperature: 0),
        profile(temperature: 120),
        profile(risk: LaundryDyeTransferRisk.unknown),
        profile(separate: null),
        profile(verified: false),
        profile(verifiedAt: now.add(const Duration(minutes: 1))),
      ]) {
        final plan = service.propose([lot('A', care: care)], now: now);
        expect(plan.groups, isEmpty);
        expect(plan.reviews.single.reasons, isNotEmpty);
      }
    },
  );

  test('dry cleaning and ironing are never mixed into a washing proposal', () {
    for (final treatment in ['dry_cleaning', 'ironing', 'unknown']) {
      final plan = service.propose([
        lot('A', treatment: treatment, care: profile()),
      ], now: now);
      expect(plan.groups, isEmpty);
      expect(
        plan.reviews.single.reasons,
        contains(LaundrySortingReason.notAWashingService),
      );
    }
  });

  test('active or completed treatment is never replanned automatically', () {
    for (final status in [
      LaundryStatus.processing,
      LaundryStatus.ready,
      LaundryStatus.delivered,
    ]) {
      final plan = service.propose([
        lot('A', status: status, care: profile()),
      ], now: now);
      expect(plan.groups, isEmpty);
      expect(
        plan.reviews.single.reasons,
        contains(LaundrySortingReason.treatmentAlreadyStarted),
      );
    }
  });

  test('care prohibitions and colour transfer warnings override matching properties', () {
    final cases = {
      profile(risk: LaundryDyeTransferRisk.high):
          LaundrySortingReason.dyeTransferRisk,
      profile(separate: true): LaundrySortingReason.separateWashRequired,
      profile(cycle: LaundryWashCycle.handWash):
          LaundrySortingReason.handWashOnly,
      profile(cycle: LaundryWashCycle.doNotWash):
          LaundrySortingReason.washingProhibited,
    };
    for (final entry in cases.entries) {
      final plan = service.propose([lot('A', care: entry.key)], now: now);
      expect(plan.groups, isEmpty);
      expect(plan.reviews.single.reasons, contains(entry.value));
    }
  });

  test('free text instructions require human review rather than guessed interpretation', () {
    final plan = service.propose([
      lot(
        'A',
        instructions: 'Ne pas mélanger / do not mix / لا تخلط',
        care: profile(),
      ),
    ], now: now);
    expect(plan.groups, isEmpty);
    expect(
      plan.reviews.single.reasons,
      contains(LaundrySortingReason.specialInstructions),
    );
  });

  test(
    'missing weight is exposed rather than replaced by a fictitious weight',
    () {
      final plan = service.propose([
        lot('A', care: profile()),
        lot('B', weight: null, care: profile()),
      ], now: now);
      expect(plan.groups.single.weightGrams, isNull);
      expect(plan.groups.single.quantity, 4);
    },
  );

  test(
    'result is stable irrespective of input order and all lots appear once',
    () {
      final inputs = [
        lot('C'),
        lot('B', care: profile()),
        lot('A', care: profile()),
      ];
      final forward = service.propose(inputs, now: now);
      final reverse = service.propose(inputs.reversed, now: now);
      expect(
        forward.groups.single.lots.map((l) => l.lineId),
        reverse.groups.single.lots.map((l) => l.lineId),
      );
      final ids = [
        for (final g in forward.groups) ...g.lots.map((l) => l.lineId),
        ...forward.reviews.map((r) => r.lot.lineId),
      ];
      expect(ids.toSet(), {'A', 'B', 'C'});
      expect(ids.length, 3);
    },
  );

  test(
    'invalid and duplicate lots are rejected; an empty plan stays empty',
    () {
      for (final inputs in [
        [lot('A'), lot('A')],
        [lot('')],
        [lot('A', quantity: 0)],
        [lot('A', weight: -1)],
        [lot('A', garment: '   ')],
      ]) {
        expect(() => service.propose(inputs, now: now), throwsArgumentError);
      }
      expect(service.propose([], now: now).groups, isEmpty);
      expect(service.propose([], now: now).reviews, isEmpty);
    },
  );
}
