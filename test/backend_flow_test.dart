import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/core/backend/backend_client.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/vehicle_capacity_evidence.dart';
import 'package:ttttttteee/features/delivery_drivers/presentation/driver_onboarding_page.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  testWidgets(
      'light vehicles enforce capacity and show the required photo flow',
      (tester) async {
    for (final entry in {'Moto': 60.0, 'V\u00e9lo': 20.0}.entries) {
      await tester.pumpWidget(MaterialApp(
          home: DriverOnboardingPage(
              key: ValueKey('${entry.key}-over'),
              userName: 'Driver',
              initialVehicle: entry.key,
              initialCapacity: entry.value + 1)));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Maximum laundry capacity: ${entry.value.toInt()} kg.'),
          findsOneWidget);
      await tester.pumpWidget(MaterialApp(
          home: DriverOnboardingPage(
              key: ValueKey(entry.key),
              userName: 'Driver',
              initialVehicle: entry.key,
              initialCapacity: entry.value)));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Vehicle photo'), findsOneWidget);
      if (entry.key == 'Moto') {
        expect(find.text('Required driver documents'), findsOneWidget);
        expect(find.textContaining('Technical-inspection certificate'),
            findsNothing);
      } else {
        expect(find.text('Gallery'), findsOneWidget);
      }
      expect(
          tester
              .widget<ElevatedButton>(
                  find.widgetWithText(ElevatedButton, 'Continue'))
              .onPressed,
          isNull);
    }
  }, skip: !BackendClient.enabled);
  test(
      'backend client authenticates and revokes its in-memory session',
      () => HttpOverrides.runWithHttpOverrides(() async {
            final server =
                await HttpServer.bind(InternetAddress.loopbackIPv4, 18766);
            String? authorization;
            server.listen((req) async {
              req.response.headers.contentType = ContentType.json;
              if (req.uri.path == '/api/auth/login') {
                req.response.write(jsonEncode({
                  'token': 'test-session-token',
                  'account': {
                    'id': 'driver',
                    'name': 'Driver',
                    'email': 'driver@test.tn',
                    'role': 'DRIVER'
                  }
                }));
              } else if (req.uri.path == '/api/auth/logout') {
                authorization = req.headers.value('Authorization');
              } else if (req.uri.path == '/broken') {
                req.response.write('not JSON');
              } else {
                req.response.statusCode = 401;
                req.response
                    .write(jsonEncode({'error': 'invalid_credentials'}));
              }
              await req.response.close();
            });
            try {
              final account = await BackendClient.authenticate(
                  '/api/auth/login',
                  {'email': 'driver@test.tn', 'password': 'local-test-only'});
              expect(account['role'], 'DRIVER');
              await expectLater(
                  BackendClient.request('/failure'),
                  throwsA(isA<BackendException>()
                      .having((e) => e.code, 'code', 'invalid_credentials')));
              await expectLater(
                  BackendClient.request('/broken'),
                  throwsA(isA<BackendException>()
                      .having((e) => e.code, 'code', 'invalid_response')));
              await BackendClient.logout();
              expect(authorization, 'Bearer test-session-token');
              expect(BackendClient.account, isNull);
            } finally {
              await server.close(force: true);
            }
          }, _RealHttpOverrides()),
      skip: !BackendClient.enabled);

  testWidgets('backend application blocks Continue without a verified dossier',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: DriverOnboardingPage(
            userName: 'Driver',
            initialVehicle: 'Voiture',
            initialEvidence: VehicleCapacityEvidence(
                imagePath: '',
                backImagePath: '',
                source: 'registration',
                brand: '',
                model: '',
                year: '',
                payloadKg: null,
                reserveKg: 100,
                ownerConfirmed: true))));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Required driver documents'), findsOneWidget);
    final continueButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'));
    expect(continueButton.onPressed, isNull);
    expect(find.text('Service area'), findsNothing);
  }, skip: !BackendClient.enabled);
}
