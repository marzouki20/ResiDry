import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_role.dart';
import '../../data/models/laundry_complaint_data.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../data/services/complaint_photo_service.dart';
import '../../domain/models/laundry_complaint.dart';
import '../widgets/complaint_form.dart';
import '../widgets/complaint_labels.dart';
import '../widgets/laundry_design.dart';
import '../widgets/laundry_insights.dart';
import '../widgets/laundry_language_button.dart';
import 'laundry_complaint_details_page.dart';

class LaundryComplaintsButton extends StatefulWidget {
  const LaundryComplaintsButton({super.key, required this.repository});
  final LaundryRepository repository;
  @override
  State<LaundryComplaintsButton> createState() =>
      _LaundryComplaintsButtonState();
}

class _LaundryComplaintsButtonState extends State<LaundryComplaintsButton> {
  late Future<ComplaintInbox> _inbox;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _inbox = widget.repository.getComplaintInbox();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) _refresh();
    });
  }

  void _refresh() {
    final next = widget.repository.getComplaintInbox();
    setState(() {
      _inbox = next;
    });
  }

  @override
  void didUpdateWidget(covariant LaundryComplaintsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _inbox = widget.repository.getComplaintInbox();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ComplaintInbox>(
    future: _inbox,
    builder: (context, snapshot) => TextButton.icon(
      icon: Badge(
        isLabelVisible: (snapshot.data?.unreadCount ?? 0) > 0,
        label: Text('${snapshot.data?.unreadCount ?? 0}'),
        child: const Icon(Icons.support_agent_outlined),
      ),
      label: Text(
        context.tr(fr: 'Réclamations', en: 'Complaints', ar: 'الشكاوى'),
      ),
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LaundryComplaintsPage(repository: widget.repository),
          ),
        );
        if (mounted) _refresh();
      },
    ),
  );
}

class LaundryComplaintsPage extends StatefulWidget {
  const LaundryComplaintsPage({
    super.key,
    required this.repository,
    this.laundryId,
    this.pickPhoto,
  });
  final LaundryRepository repository;
  final String? laundryId;
  final ComplaintPhotoPicker? pickPhoto;
  @override
  State<LaundryComplaintsPage> createState() => _LaundryComplaintsPageState();
}

class _LaundryComplaintsPageState extends State<LaundryComplaintsPage> {
  late Future<ComplaintInbox> _inbox;
  ComplaintStatus? _filter;
  String _search = '';
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _inbox = widget.repository.getComplaintInbox(laundryId: widget.laundryId);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) _refresh();
    });
  }

  void _refresh() {
    final next = widget.repository.getComplaintInbox(
      laundryId: widget.laundryId,
    );
    setState(() {
      _inbox = next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LaundryComplaintDetailsPage(
          repository: widget.repository,
          complaintId: id,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _create() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => ComplaintForm(
        repository: widget.repository,
        laundryId: widget.laundryId!,
        pickPhoto: widget.pickPhoto,
      ),
    );
    if (id != null && mounted) {
      await _open(id);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(
        context.tr(fr: 'Réclamations', en: 'Complaints', ar: 'الشكاوى'),
      ),
      actions: [
        const LaundryLanguageButton(compact: true),
        IconButton(
          tooltip: context.localize('Actualiser'),
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<ComplaintInbox>(
      future: _inbox,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: LaundryEmptyState(
              title: context.tr(
                fr: 'Réclamations indisponibles',
                en: 'Complaints unavailable',
                ar: 'الشكاوى غير متاحة',
              ),
              description: context.tr(
                fr: 'Vérifiez votre connexion au compte et réessayez.',
                en: 'Check your account and try again.',
                ar: 'تحقق من حسابك وأعد المحاولة.',
              ),
              action: TextButton(
                onPressed: _refresh,
                child: Text(context.localize('Réessayer')),
              ),
            ),
          );
        }
        final inbox = snapshot.data!;
        final admin = inbox.role == LaundryRole.admin;
        final cases = inbox.complaints
            .where(
              (c) =>
                  (_filter == null || c.status == _filter) &&
                  '${c.id} ${c.laundryId} ${c.description} ${inbox.names[c.residentId] ?? ''} ${complaintLabel(context, c.reason)}'
                      .toLowerCase()
                      .contains(_search.toLowerCase()),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
          children: [
            LaundrySectionHeader(
              title: context.tr(
                fr: admin
                    ? 'Écouter, examiner, répondre'
                    : 'Votre linge, votre suivi',
                en: admin
                    ? 'Listen, review, respond'
                    : 'Your laundry, your follow-up',
                ar: admin ? 'استمع وراجع وأجب' : 'متابعة شكاوى غسيلك',
              ),
              subtitle: context.tr(
                fr: 'Un dossier traçable et une décision motivée. Les réponses non lues apparaissent ici, sur cet appareil.',
                en: 'A traceable case and a reasoned decision. Unread responses appear here, on this device.',
                ar: 'ملف قابل للتتبع وقرار مبرر. تظهر الردود غير المقروءة هنا على هذا الجهاز.',
              ),
              icon: Icons.support_agent_outlined,
              accent: LaundryPalette.terracotta,
            ),
            const SizedBox(height: 16),
            if (!admin && widget.laundryId != null)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_comment_outlined),
                label: Text(
                  context.tr(
                    fr: 'Nouvelle réclamation',
                    en: 'New complaint',
                    ar: 'شكوى جديدة',
                  ),
                ),
              ),
            if (!admin && widget.laundryId == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  context.tr(
                    fr: 'Pour ouvrir un dossier, utilisez « Réclamer » sur votre demande de linge.',
                    en: 'To open a case, choose “Report an issue” on your laundry request.',
                    ar: 'لفتح ملف، اختر «تقديم شكوى» على طلب الغسيل.',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                fr: '${inbox.complaints.length} dossier(s) · ${inbox.unreadCount} ${admin ? 'à examiner' : 'réponse(s) non lue(s)'}',
                en: '${inbox.complaints.length} case(s) · ${inbox.unreadCount} ${admin ? 'awaiting review' : 'unread response(s)'}',
                ar: '${inbox.complaints.length} ملفات · ${inbox.unreadCount} ${admin ? 'بانتظار المراجعة' : 'ردود غير مقروءة'}',
              ),
            ),
            const SizedBox(height: 12),
            LaundrySearchField(
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(context.localize('Toutes')),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final status in ComplaintStatus.values)
                  ChoiceChip(
                    label: Text(complaintLabel(context, status)),
                    selected: _filter == status,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (cases.isEmpty)
              LaundryEmptyState(
                title: context.tr(
                  fr: 'Aucune réclamation à afficher',
                  en: 'No complaints to show',
                  ar: 'لا توجد شكاوى للعرض',
                ),
              ),
            for (final complaint in cases)
              Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _open(complaint.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              backgroundColor: complaintColor(complaint.status),
                              label: Text(
                                complaintLabel(context, complaint.status),
                              ),
                            ),
                            if (!admin && complaint.hasUnreadResponse)
                              Chip(
                                label: Text(
                                  context.tr(
                                    fr: 'Nouvelle réponse',
                                    en: 'New response',
                                    ar: 'رد جديد',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          complaintLabel(context, complaint.reason),
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text('#${complaint.laundryId}'),
                        if (admin)
                          Text(
                            inbox.names[complaint.residentId] ??
                                '#${complaint.residentId}',
                          ),
                        Text(
                          complaint.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(complaint.updatedAt.toLocal()),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
