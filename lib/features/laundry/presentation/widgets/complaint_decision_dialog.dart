import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../domain/models/laundry_complaint.dart';
import 'complaint_labels.dart';
import 'laundry_design.dart';

class ComplaintDecisionDialog extends StatefulWidget {
  const ComplaintDecisionDialog({super.key});
  @override
  State<ComplaintDecisionDialog> createState() =>
      _ComplaintDecisionDialogState();
}

class _ComplaintDecisionDialogState extends State<ComplaintDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  ComplaintStatus _status = ComplaintStatus.resolved;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    title: Text(
      context.tr(
        fr: 'Décision motivée',
        en: 'Reasoned decision',
        ar: 'قرار مبرر',
      ),
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ComplaintStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Décision',
                    en: 'Decision',
                    ar: 'القرار',
                  ),
                ),
                items: [
                  for (final status in [
                    ComplaintStatus.resolved,
                    ComplaintStatus.rejected,
                  ])
                    DropdownMenuItem(
                      value: status,
                      child: Text(complaintLabel(context, status)),
                    ),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reason,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => complaintTextError(context, v),
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Motif et solution apportée',
                    en: 'Reason and action taken',
                    ar: 'السبب والإجراء المتخذ',
                  ),
                  helper: context.tr(
                    fr: 'Expliquez la décision au résident (10 caractères minimum).',
                    en: 'Explain the decision to the resident (at least 10 characters).',
                    ar: 'اشرح القرار للمقيم (10 أحرف على الأقل).',
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
        onPressed: () => Navigator.pop(context),
        child: Text(context.localize('Annuler')),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, (_status, _reason.text.trim()));
          }
        },
        child: Text(
          context.tr(
            fr: 'Confirmer la décision',
            en: 'Confirm decision',
            ar: 'تأكيد القرار',
          ),
        ),
      ),
    ],
  );
}
