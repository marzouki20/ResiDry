import 'dart:io';
import 'dart:convert';
import 'ocr_fixture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ttttttteee/features/delivery_drivers/data/vehicle_evidence_service.dart';
import 'package:ttttttteee/features/delivery_drivers/domain/vehicle_capacity_evidence.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native OCR extracts a payload from a generated test image',
      (tester) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/residry-ocr-test.png');
    try {
      await file.writeAsBytes(base64Decode(capacityFixtureBase64));
      final readText = await VehicleEvidenceService().readText(file.path);
      final payload = VehicleCapacityEvidence.extractPayload(readText);
      expect(payload, 750, reason: 'Native OCR output: $readText');
    } finally {
      if (await file.exists()) await file.delete();
    }
  });
}
