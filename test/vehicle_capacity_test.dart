import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/vehicle_capacity_evidence.dart';
import 'package:ttttttteee/features/delivery_drivers/data/vehicle_evidence_service.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';

VehicleCapacityEvidence evidence(
        {double? payload = 750,
        double? reserve = 100,
        bool confirmed = true,
        String image = 'evidence.jpg'}) =>
    VehicleCapacityEvidence(
        imagePath: image,
        source: 'gallery',
        brand: 'Example',
        model: 'Van',
        year: '2022',
        payloadKg: payload,
        reserveKg: reserve,
        ownerConfirmed: confirmed);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('required evidence allows manual review but rejects missing details',
      () {
    expect(evidence(payload: null).isComplete, isTrue);
    expect(evidence(image: '').isComplete, isFalse);
    expect(evidence(confirmed: false).isComplete, isFalse);
    expect(evidence(reserve: null).isComplete, isFalse);
    expect(evidence(reserve: -1).isComplete, isFalse);
    expect(evidence(reserve: double.nan).isComplete, isFalse);
  });

  testWidgets(
      'vehicle page continues to certificate page but certificate gate is locked',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: DriverOnboardingPage(userName: 'Driver')));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Registration certificate verification'), findsOneWidget);
    expect(find.text('Service area'), findsNothing);
    final button = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('Continue'), matching: find.byType(ElevatedButton)));
    expect(button.onPressed, isNull);
    await tester.ensureVisible(find.text('Verify with AI'));
    await tester.tap(find.text('Verify with AI'));
    await tester.pumpAndSettle();
    expect(
        find.text('Add both photos, enter a valid weight and confirm consent.'),
        findsOneWidget);
  });

  test(
      'parsing accepts only labelled kg payload and rejects ambiguous documents',
      () {
    expect(
        VehicleCapacityEvidence.extractPayload('Vehicle\nCharge utile: 750 kg'),
        750);
    expect(VehicleCapacityEvidence.extractPayload('PAYLOAD 1,250 kg'), 1250);
    expect(
        VehicleCapacityEvidence.extractPayload('Charge utile 750,5 kg'), 750.5);
    expect(VehicleCapacityEvidence.extractPayload('Payload: 1 250 kg'), 1250);
    for (final text in [
      'GVWR 3500 kg',
      '750 kg',
      'Axle limit 1000 kg',
      'Minimum payload 600 kg',
      'Payload 2000 lbs',
      'Payload 750 kg\nPayload 900 kg',
      'Maximum mass 3500 kg\nUnladen mass 2000 kg'
    ]) {
      expect(VehicleCapacityEvidence.extractPayload(text), isNull,
          reason: text);
    }
  });

  test(
      'comparison includes reserve and never approves missing or invalid evidence',
      () {
    expect(evidence().assess(500), CapacityAssessment.consistent);
    expect(evidence().assess(700), CapacityAssessment.exceedsLimit);
    expect(
        evidence(payload: null).assess(500), CapacityAssessment.reviewRequired);
    expect(
        evidence(reserve: null).assess(500), CapacityAssessment.reviewRequired);
    expect(evidence(payload: double.nan).assess(500),
        CapacityAssessment.reviewRequired);
    expect(evidence(confirmed: false).assess(500),
        CapacityAssessment.reviewRequired);
    expect(evidence(image: '').assess(500), CapacityAssessment.reviewRequired);
    expect(
        evidence().assess(double.infinity), CapacityAssessment.reviewRequired);
  });

  test(
      'OCR channel integration reads payload and closes recognizer even on failure',
      () async {
    const channel = MethodChannel('google_mlkit_text_recognizer');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    var fail = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'vision#startTextRecognizer') {
        if (fail) throw PlatformException(code: 'unreadable');
        return {'text': 'Charge utile 750 kg', 'blocks': []};
      }
      return null;
    });
    try {
      expect(await VehicleEvidenceService().readPayload('plate.jpg'), 750);
      expect(calls.last.method, 'vision#closeTextRecognizer');
      fail = true;
      await expectLater(VehicleEvidenceService().readPayload('bad.jpg'),
          throwsA(isA<PlatformException>()));
      expect(calls.last.method, 'vision#closeTextRecognizer');
    } finally {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets('old one-sided evidence cannot bypass certificate verification',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: DriverOnboardingPage(
            userName: 'Driver', initialEvidence: evidence())));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Registration certificate verification'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text('Continue'), matching: find.byType(ElevatedButton)));
    expect(button.onPressed, isNull);
  });
}
