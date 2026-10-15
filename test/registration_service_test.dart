import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/features/delivery_drivers/data/registration_verification_service.dart';

void main() {
  test('only a complete plausible passed response unlocks verification', () {
    final data = <String, dynamic>{
      'status': 'passed',
      'reason': 'consistent',
      'brand': 'Example',
      'model': 'Van',
      'year': '2022',
      'payload_kg': 750
    };
    expect(RegistrationResult.fromJson(data).passed, isTrue);
    for (final change in [
      {'status': 'inconclusive'},
      {'status': 'rejected'},
      {'year': '1800'},
      {'brand': ' '},
      {'payload_kg': null},
      {'payload_kg': -1},
      {'payload_kg': 20000}
    ]) {
      expect(RegistrationResult.fromJson({...data, ...change}).passed, isFalse);
    }
  });
  test('unconfigured service fails closed before opening a connection',
      () async {
    await expectLater(
        RegistrationVerificationService().verify(
            frontPath: 'front.jpg',
            backPath: 'back.jpg',
            vehicleType: 'Voiture',
            declaredKg: 200,
            reserveKg: 100),
        throwsStateError);
  });
}
