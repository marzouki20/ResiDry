import 'dart:ui' as ui;

import 'package:ttttttteee/features/laundry/domain/models/laundry_complaint.dart';

Future<ComplaintPhoto> complaintTestPhoto() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF06B6D4), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 4);
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return ComplaintPhoto(
      bytes: bytes!.buffer.asUint8List(),
      mimeType: 'image/png',
    );
  } finally {
    image.dispose();
  }
}
