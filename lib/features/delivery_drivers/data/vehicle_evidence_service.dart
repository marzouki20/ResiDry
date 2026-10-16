import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/vehicle_capacity_evidence.dart';

class VehicleEvidenceService {
  Future<double?> readPayload(String imagePath) async =>
      VehicleCapacityEvidence.extractPayload(await readText(imagePath));

  Future<String> readText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
