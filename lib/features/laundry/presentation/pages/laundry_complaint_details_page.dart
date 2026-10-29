import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_role.dart';
import '../../data/models/laundry_complaint_data.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../domain/models/laundry_complaint.dart';
import '../widgets/complaint_decision_dialog.dart';
import '../widgets/complaint_labels.dart';
import '../widgets/laundry_design.dart';
import '../widgets/laundry_language_button.dart';
import '../widgets/laundry_messages.dart';

class LaundryComplaintDetailsPage extends StatefulWidget {
  const LaundryComplaintDetailsPage({
    super.key,
    required this.repository,
    required this.complaintId,
  });
  final LaundryRepository repository;
  final String complaintId;
  @override
  State<LaundryComplaintDetailsPage> createState() =>
      _LaundryComplaintDetailsPageState();
}

class _LaundryComplaintDetailsPageState
    extends State<LaundryComplaintDetailsPage> {
  late Future<ComplaintDetails> _details;
  Timer? _timer;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _details = _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && !_busy && ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }
    });
  }

  Future<ComplaintDetails> _load() async {
    final details = await widget.repository.getComplaintDetails(
      widget.complaintId,
    );
    if (details.role == LaundryRole.resident &&
        details.complaint.hasUnreadResponse) {
      await widget.repository.markComplaintSeen(
        widget.complaintId,
        expectedRevision: details.complaint.revision,
      );
    }
    return details;
  }

  void _refresh() {
    final next = _load();
    setState(() {
      _details = next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _advance(
    ComplaintDetails data,
    ComplaintStatus status, {
    String reason = '',
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.advanceComplaint(
        widget.complaintId,
        expectedRevision: data.complaint.revision,
        newStatus: status,
        decisionReason: reason,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is LaundryException
                  ? laundryMessage(context, error.message)
                  : context.tr(
                      fr: 'Décision non enregistrée. Réessayez.',
                      en: 'Decision not saved. Try again.',
                      ar: 'لم يتم حفظ القرار. أعد المحاولة.',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _decide(ComplaintDetails data) async {
    final decision = await showDialog<(ComplaintStatus, String)>(
      context: context,
      builder: (_) => const ComplaintDecisionDialog(),
    );
    if (decision != null && mounted) {
      await _advance(data, decision.$1, reason: decision.$2);
    }
  }

  String _date(DateTime date) =>
      '${MaterialLocalizations.of(context).formatMediumDate(date.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date.toLocal()))}';
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(
        context.tr(
          fr: 'Suivi de réclamation',
          en: 'Complaint tracking',
          ar: 'متابعة الشكوى',
        ),
      ),
      actions: [
        const LaundryLanguageButton(compact: true),
        IconButton(
          onPressed: _busy ? null : _refresh,
          tooltip: context.localize('Actualiser'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<ComplaintDetails>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: LaundryEmptyState(
              title: context.tr(
                fr: 'Dossier inaccessible',
                en: 'Case unavailable',
                ar: 'الملف غير متاح',
              ),
              action: TextButton(
                onPressed: _refresh,
                child: Text(context.localize('Réessayer')),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final complaint = data.complaint;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: complaintColor(complaint.status),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaintLabel(context, complaint.status),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaintLabel(context, complaint.reason),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('#${complaint.laundryId}'),
                  Text(
                    complaint.id,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    data.names[complaint.residentId] ??
                        '#${complaint.residentId}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (complaint.garmentSnapshot != null)
              Text(
                complaint.garmentSnapshot!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in data.photos)
                  InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 600,
                            height: 500,
                            child: InteractiveViewer(
                              child: Image.memory(
                                photo.bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        photo.bytes,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        cacheWidth: 220,
                      ),
                    ),
                  ),
              ],
            ),
            if (complaint.decisionReason != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: complaintColor(complaint.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        fr: 'Décision et solution',
                        en: 'Decision and action',
                        ar: 'القرار والإجراء',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(complaint.decisionReason!),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (data.role == LaundryRole.admin &&
                complaint.status == ComplaintStatus.submitted)
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _advance(data, ComplaintStatus.reviewing),
                icon: const Icon(Icons.manage_search_outlined),
                label: Text(
                  context.tr(
                    fr: 'Prendre en charge',
                    en: 'Start review',
                    ar: 'بدء المراجعة',
                  ),
                ),
              ),
            if (data.role == LaundryRole.admin &&
                complaint.status == ComplaintStatus.reviewing)
              FilledButton.icon(
                onPressed: _busy ? null : () => _decide(data),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  context.tr(
                    fr: 'Rendre une décision',
                    en: 'Make a decision',
                    ar: 'اتخاذ قرار',
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              context.tr(
                fr: 'Historique du dossier',
                en: 'Case history',
                ar: 'سجل الملف',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            for (final event in data.events)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: complaintColor(event.newStatus),
                      child: const Icon(Icons.history, color: AppColors.navy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaintLabel(context, event.newStatus),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              data.names[event.actorId] ?? '#${event.actorId}',
                            ),
                            Text(
                              _date(event.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (event.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(event.note),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              context.tr(
                fr: 'Un signalement ou une photo ne suffit pas à établir une responsabilité.',
                en: 'A report or photo alone does not establish responsibility.',
                ar: 'البلاغ أو الصورة وحدهما لا يثبتان المسؤولية.',
              ),
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        );
      },
    ),
  );
}
