import 'dart:convert';
import 'dart:io';

class RegistrationResult {
  const RegistrationResult(
      {required this.status,
      required this.reason,
      this.brand,
      this.model,
      this.year,
      this.payloadKg});
  final String status, reason;
  final String? brand, model, year;
  final double? payloadKg;
  bool get passed =>
      status == 'passed' &&
      brand?.trim().isNotEmpty == true &&
      model?.trim().isNotEmpty == true &&
      (int.tryParse(year ?? '') ?? 0) >= 1900 &&
      (int.tryParse(year ?? '') ?? 0) <= DateTime.now().year + 1 &&
      payloadKg != null &&
      payloadKg!.isFinite &&
      payloadKg! > 0 &&
      payloadKg! <= 10000;
  factory RegistrationResult.fromJson(Map<String, dynamic> value) =>
      RegistrationResult(
          status: value['status'] as String,
          reason: value['reason'] as String,
          brand: value['brand'] as String?,
          model: value['model'] as String?,
          year: value['year'] as String?,
          payloadKg: (value['payload_kg'] as num?)?.toDouble());
}

class RegistrationVerificationService {
  Future<RegistrationResult> verify(
      {required String frontPath,
      required String backPath,
      required String vehicleType,
      required double declaredKg,
      required double reserveKg}) async {
    const endpoint = String.fromEnvironment('REGISTRATION_API_URL');
    const token = String.fromEnvironment('REGISTRATION_DEV_TOKEN');
    if (endpoint.isEmpty) throw StateError('service_not_configured');
    final uri = Uri.parse(endpoint);
    if (uri.scheme != 'https') throw StateError('https_required');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final front = await File(frontPath).readAsBytes();
      final back = await File(backPath).readAsBytes();
      if (front.length > 5 * 1024 * 1024 || back.length > 5 * 1024 * 1024) {
        throw StateError('image_too_large');
      }
      final request =
          await client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      if (token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }
      request.write(jsonEncode({
        'front': base64Encode(front),
        'back': base64Encode(back),
        'vehicle_type': vehicleType,
        'declared_kg': declaredKg,
        'reserve_kg': reserveKg
      }));
      final response =
          await request.close().timeout(const Duration(seconds: 100));
      if (response.statusCode != 200) {
        throw StateError('verification_unavailable');
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      final result =
          RegistrationResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
      // A malformed or inconsistent response must never unlock navigation.
      if (result.status == 'passed' &&
          (!result.passed || declaredKg + reserveKg > result.payloadKg!)) {
        throw StateError('invalid_verification_response');
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }
}
