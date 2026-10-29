import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_role.dart';
import '../../data/models/laundry_details.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../data/services/complaint_photo_service.dart';
import '../../domain/models/laundry_complaint.dart';
import '../../domain/services/complaint_service.dart';
import 'complaint_labels.dart';
import 'laundry_design.dart';
import 'laundry_messages.dart';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({
    super.key,
    required this.repository,
    required this.laundryId,
    this.pickPhoto,
  });
  final LaundryRepository repository;
  final String laundryId;
  final Future<ComplaintPhoto?> Function(ImageSource)? pickPhoto;
  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _photos = <ComplaintPhoto>[];
  LaundryDetails? _request;
  ComplaintReason _reason = ComplaintReason.damaged;
  String? _line, _error;
  bool _loading = true, _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await widget.repository.getCurrentUser();
      if (laundryRoleFromUserRole(user.role) != LaundryRole.resident) {
        throw StateError('resident required');
      }
      final data = await widget.repository.getDetails(widget.laundryId);
      if (mounted) {
        setState(() {
          _request = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'load';
        });
      }
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_busy || _photos.length >= ComplaintService.maxPhotos) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await (widget.pickPhoto ?? ComplaintPhotoService().pick)(
        source,
      );
      if (photo != null && mounted) {
        await validateComplaintPhotos([photo]);
        if (mounted) setState(() => _photos.add(photo));
      }
    } on FormatException {
      if (mounted) {
        setState(
          () => _error = 'Photos invalides : 3 maximum, 2 Mo par photo (JPEG, PNG ou WebP).',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Photo inaccessible. Vérifiez les autorisations et réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await widget.repository.createComplaint(
        laundryId: widget.laundryId,
        reason: _reason,
        description: _description.text,
        lineId: _line,
        photos: _photos,
      );
      if (mounted) Navigator.pop(context, id);
    } on LaundryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Réclamation non enregistrée. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Text(
      context.tr(
        fr: 'Nouvelle réclamation',
        en: 'New complaint',
        ar: 'شكوى جديدة',
      ),
    ),
    content: SizedBox(
      width: 600,
      child: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _request == null
          ? Text(
              context.tr(
                fr: 'Demande inaccessible. Vérifiez votre compte résident.',
                en: 'Request unavailable. Check your resident account.',
                ar: 'الطلب غير متاح. تحقق من حساب المقيم.',
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LaundryPalette.peach,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('#${widget.laundryId}'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ComplaintReason>(
                      initialValue: _reason,
                      isExpanded: true,
                      decoration: laundryFieldDecoration(
                        label: context.tr(
                          fr: 'Motif',
                          en: 'Reason',
                          ar: 'السبب',
                        ),
                      ),
                      items: [
                        for (final reason in ComplaintReason.values)
                          DropdownMenuItem(
                            value: reason,
                            child: Text(
                              complaintLabel(context, reason),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _reason = v!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _line,
                      isExpanded: true,
                      decoration: laundryFieldDecoration(
                        label: context.tr(
                          fr: 'Lot concerné',
                          en: 'Affected lot',
                          ar: 'المجموعة المعنية',
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            context.tr(
                              fr: 'Toute la demande',
                              en: 'Entire request',
                              ar: 'الطلب كاملًا',
                            ),
                          ),
                        ),
                        for (final line in _request!.lines)
                          DropdownMenuItem(
                            value: line.id,
                            child: Text(
                              '${line.garment} · ${line.quantity}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _line = v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _description,
                      enabled: !_busy,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 2000,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => complaintTextError(context, v),
                      decoration: laundryFieldDecoration(
                        label: context.tr(
                          fr: 'Décrivez le problème',
                          en: 'Describe the issue',
                          ar: 'صف المشكلة',
                        ),
                        helper: context.tr(
                          fr: '10 caractères minimum. Décrivez les faits constatés.',
                          en: 'At least 10 characters. Describe what you observed.',
                          ar: '10 أحرف على الأقل. صف ما لاحظته.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        fr: 'Photos facultatives · 3 maximum · 2 Mo chacune',
                        en: 'Optional photos · up to 3 · 2 MB each',
                        ar: 'صور اختيارية · 3 كحد أقصى · 2 ميغابايت لكل صورة',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _busy || _photos.length >= 3
                              ? null
                              : () => _addPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            context.tr(
                              fr: 'Galerie',
                              en: 'Gallery',
                              ar: 'المعرض',
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy || _photos.length >= 3
                              ? null
                              : () => _addPhoto(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            context.tr(
                              fr: 'Appareil photo',
                              en: 'Camera',
                              ar: 'الكاميرا',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _photos.length; i++)
                          SizedBox(
                            width: 100,
                            height: 112,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _photos[i].bytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    cacheWidth: 200,
                                  ),
                                ),
                                PositionedDirectional(
                                  end: 0,
                                  top: 0,
                                  child: IconButton.filledTonal(
                                    tooltip: context.tr(
                                      fr: 'Retirer la photo',
                                      en: 'Remove photo',
                                      ar: 'حذف الصورة',
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                            () => _photos.removeAt(i),
                                          ),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        fr: 'Le signalement sera examiné. Une photo ne détermine pas automatiquement une responsabilité.',
                        en: 'The report will be reviewed. A photo does not automatically establish responsibility.',
                        ar: 'ستتم مراجعة البلاغ. الصورة لا تثبت المسؤولية تلقائيًا.',
                      ),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          laundryMessage(context, _error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: Text(context.localize('Annuler')),
      ),
      FilledButton(
        onPressed: _loading || _busy || _request == null ? null : _save,
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.tr(fr: 'Envoyer', en: 'Submit', ar: 'إرسال')),
      ),
    ],
  );
}
