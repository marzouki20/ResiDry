import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_locale.dart';
import '../../domain/vehicle_capacity_evidence.dart';

class VehiclePhotoPanel extends StatefulWidget {
  const VehiclePhotoPanel(
      {super.key,
      required this.vehicle,
      required this.onChanged,
      required this.onBusyChanged,
      this.initialEvidence});
  final String vehicle;
  final VehicleCapacityEvidence? initialEvidence;
  final ValueChanged<VehicleCapacityEvidence?> onChanged;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<VehiclePhotoPanel> createState() => _VehiclePhotoPanelState();
}

class _VehiclePhotoPanelState extends State<VehiclePhotoPanel> {
  final _picker = ImagePicker();
  String? _path;
  String _source = 'camera';
  bool _consent = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _path = widget.initialEvidence?.supportingPaths['VEHICLE_PHOTO'];
    _source = widget.initialEvidence?.source == 'vehicle_photo_gallery'
        ? 'gallery'
        : 'camera';
    _consent = widget.initialEvidence?.ownerConfirmed ?? false;
  }

  void _emit() {
    widget.onChanged(VehicleCapacityEvidence(
        imagePath: '',
        source: 'vehicle_photo_$_source',
        brand: '',
        model: '',
        year: '',
        payloadKg: null,
        reserveKg: 0,
        ownerConfirmed: _consent,
        supportingPaths: {if (_path != null) 'VEHICLE_PHOTO': _path!}));
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged(true);
    try {
      final image = await _picker.pickImage(
          source: source, maxWidth: 2200, imageQuality: 90);
      if (image != null && mounted) {
        setState(() {
          _path = image.path;
          _source = source == ImageSource.camera ? 'camera' : 'gallery';
        });
        _emit();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr(
            en: 'Could not open the camera or photo. Check permission and retry.',
            fr: 'Impossible d’ouvrir l’appareil photo ou l’image. Vérifiez l’autorisation et réessayez.',
            ar: 'تعذر فتح الكاميرا أو الصورة. تحقق من الإذن وأعد المحاولة.'));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            context.tr(
                en: 'Vehicle photo — required',
                fr: 'Photo du véhicule — obligatoire',
                ar: 'صورة المركبة — إلزامية'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(widget.vehicle == 'Moto'
            ? context.tr(
                en:
                    'Take a new, clear photo of your motorcycle showing the whole vehicle. A manager will review it before approval. Maximum laundry capacity: 60 kg.',
                fr:
                    'Prenez une nouvelle photo nette de votre moto, avec le véhicule entier visible. Un responsable l’examinera avant approbation. Capacité maximale de linge : 60 kg.',
                ar:
                    'التقط صورة جديدة وواضحة للدراجة النارية كاملة. يراجعها المسؤول قبل الموافقة. الحد الأقصى للغسيل: 60 كغ.')
            : context.tr(
                en: 'Take or upload a clear photo showing your bicycle and its load carrier. A manager will review it. Maximum laundry capacity: 20 kg.',
                fr: 'Prenez ou ajoutez une photo nette montrant votre vélo et son support de chargement. Un responsable l’examinera. Capacité maximale de linge : 20 kg.',
                ar: 'التقط أو أضف صورة واضحة للدراجة الهوائية وحامل الحمولة. يراجعها المسؤول. الحد الأقصى للغسيل: 20 كغ.')),
        if (_path != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.file(File(_path!),
                  height: 220,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image))),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(context.tr(
                  en: 'Take a photo',
                  fr: 'Prendre une photo',
                  ar: 'التقاط صورة'))),
          if (widget.vehicle != 'Moto')
            OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                    context.tr(en: 'Gallery', fr: 'Galerie', ar: 'المعرض'))),
        ]),
        CheckboxListTile(
            value: _consent,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() => _consent = value ?? false);
                    _emit();
                  },
            title: Text(context.tr(
                en: 'This is my delivery vehicle. I agree to send this photo to ResiDry for manager review.',
                fr: 'Il s’agit de mon véhicule de livraison. J’accepte l’envoi de cette photo à ResiDry pour examen par un responsable.',
                ar: 'هذه مركبتي للتوصيل. أوافق على إرسال الصورة إلى ريزيدراي لمراجعتها من المسؤول.'))),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        if (_busy) const LinearProgressIndicator(),
      ]);
}
