import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../domain/models/laundry_complaint.dart';
import '../../domain/services/complaint_service.dart';

typedef ComplaintPhotoPicker = Future<ComplaintPhoto?> Function(
  ImageSource source,
);

String? complaintPhotoMime(List<int> bytes) {
  if (bytes.length >= 8 &&
      List.generate(8, (i) => bytes[i]).join(',') ==
          '137,80,78,71,13,10,26,10') {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return 'image/jpeg';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

Future<void> validateComplaintPhotos(List<ComplaintPhoto> photos) async {
  if (photos.length > ComplaintService.maxPhotos) {
    throw const FormatException('photos');
  }
  for (final photo in photos) {
    if (photo.bytes.isEmpty ||
        photo.bytes.length > ComplaintService.maxPhotoBytes ||
        complaintPhotoMime(photo.bytes) != photo.mimeType) {
      throw const FormatException('photos');
    }
    try {
      final codec = await ui.instantiateImageCodec(
        photo.bytes,
        targetWidth: 1600,
        allowUpscaling: false,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    } catch (_) {
      throw const FormatException('photos');
    }
  }
}

class ComplaintPhotoService {
  ComplaintPhotoService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<ComplaintPhoto?> pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (image == null) return null;
    if (await image.length() > ComplaintService.maxPhotoBytes) {
      throw const FormatException('photos');
    }
    final bytes = await image.readAsBytes();
    final mime = complaintPhotoMime(bytes);
    if (mime == null) throw const FormatException('photos');
    final photo = ComplaintPhoto(bytes: bytes, mimeType: mime);
    await validateComplaintPhotos([photo]);
    return photo;
  }
}
