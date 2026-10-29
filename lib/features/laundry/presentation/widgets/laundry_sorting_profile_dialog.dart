import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../domain/models/laundry_sorting.dart';
import 'laundry_design.dart';
import 'laundry_messages.dart';
import 'laundry_sorting_labels.dart';

class LaundrySortingProfileDialog extends StatefulWidget {
  const LaundrySortingProfileDialog({
    super.key,
    required this.repository,
    required this.lot,
    required this.revision,
  });
  final LaundryRepository repository;
  final LaundrySortingLot lot;
  final int revision;
  @override
  State<LaundrySortingProfileDialog> createState() =>
      _LaundrySortingProfileDialogState();
}

class _LaundrySortingProfileDialogState
    extends State<LaundrySortingProfileDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _temperature;
  LaundryColorFamily? _color;
  LaundryFabric? _fabric;
  LaundryWashCycle? _cycle;
  LaundryDyeTransferRisk _risk = LaundryDyeTransferRisk.unknown;
  bool? _separate;
  bool _confirmed = false, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final profile = widget.lot.profile;
    _color = profile?.color;
    _fabric = profile?.fabric;
    _cycle = profile?.cycle;
    _risk = profile?.dyeTransferRisk ?? LaundryDyeTransferRisk.unknown;
    _separate = profile?.washSeparately;
    _temperature = TextEditingController(
      text: profile?.maxTemperatureC?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _temperature.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_confirmed || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveSortingProfile(
        requestId: widget.lot.requestId,
        lineId: widget.lot.lineId,
        expectedRevision: widget.revision,
        profile: LaundrySortingProfile(
          color: _color,
          fabric: _fabric,
          cycle: _cycle,
          maxTemperatureC: int.tryParse(_temperature.text.trim()),
          dyeTransferRisk: _risk,
          washSeparately: _separate,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on LaundryException catch (error) {
      if (mounted) {
        setState(() => _error = laundryMessage(context, error.message));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.tr(
            fr: 'Vérification non enregistrée. Réessayez.',
            en: 'Check not saved. Try again.',
            ar: 'لم يتم حفظ التحقق. أعد المحاولة.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _choice<T extends Enum>(
    String label,
    List<T> values,
    T? selected,
    ValueChanged<T?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<T>(
      initialValue: selected,
      isExpanded: true,
      decoration: laundryFieldDecoration(label: label),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            context.tr(
              fr: 'Inconnu / à vérifier',
              en: 'Unknown / to check',
              ar: 'غير معروف / يحتاج إلى تحقق',
            ),
          ),
        ),
        for (final value in values)
          DropdownMenuItem(
            value: value,
            child: Text(
              sortingLabel(context, value),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: _saving ? null : changed,
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    title: Text(
      context.tr(
        fr: 'Vérifier le lot',
        en: 'Check the lot',
        ar: 'التحقق من المجموعة',
      ),
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.lot.garment} · ${widget.lot.quantity}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  fr: 'Vérifiez le vêtement et son étiquette. Tous les vêtements du lot doivent partager ces caractéristiques. Sinon, séparez les lots avant traitement.',
                  en: 'Check the garment and care label. Every garment in this lot must share these properties. Otherwise split the lots before treatment.',
                  ar: 'تحقق من الملابس وملصق العناية. يجب أن تشترك جميع قطع المجموعة في هذه الخصائص. وإلا افصل المجموعات قبل المعالجة.',
                ),
              ),
              const SizedBox(height: 18),
              _choice(
                context.tr(fr: 'Couleur', en: 'Colour', ar: 'اللون'),
                LaundryColorFamily.values,
                _color,
                (v) => setState(() => _color = v),
              ),
              _choice(
                context.tr(fr: 'Tissu', en: 'Fabric', ar: 'النسيج'),
                LaundryFabric.values,
                _fabric,
                (v) => setState(() => _fabric = v),
              ),
              _choice(
                context.tr(
                  fr: 'Cycle indiqué',
                  en: 'Labelled cycle',
                  ar: 'الدورة المحددة',
                ),
                LaundryWashCycle.values,
                _cycle,
                (v) => setState(() => _cycle = v),
              ),
              TextFormField(
                controller: _temperature,
                enabled: !_saving,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Température maximale sur l’étiquette (°C)',
                    en: 'Maximum care-label temperature (°C)',
                    ar: 'الحرارة القصوى على الملصق (°م)',
                  ),
                  helper: context.tr(
                    fr: 'Facultative si inconnue. Entier de 1 à 95 °C.',
                    en: 'Leave blank if unknown. Integer from 1 to 95 °C.',
                    ar: 'اتركها فارغة إن كانت مجهولة. عدد صحيح بين 1 و95.',
                  ),
                ),
                validator: (text) {
                  final value = (text ?? '').trim();
                  if (value.isEmpty) return null;
                  final n = int.tryParse(value);
                  return !RegExp(r'^\d+$').hasMatch(value) ||
                          n == null ||
                          n < 1 ||
                          n > 95
                      ? context.tr(
                          fr: 'Entrez un entier entre 1 et 95 °C.',
                          en: 'Enter an integer from 1 to 95 °C.',
                          ar: 'أدخل عددًا صحيحًا بين 1 و95.',
                        )
                      : null;
                },
              ),
              const SizedBox(height: 14),
              _choice(
                context.tr(
                  fr: 'Risque de décoloration',
                  en: 'Dye transfer risk',
                  ar: 'خطر انتقال اللون',
                ),
                LaundryDyeTransferRisk.values,
                _risk,
                (v) =>
                    setState(() => _risk = v ?? LaundryDyeTransferRisk.unknown),
              ),
              DropdownButtonFormField<bool>(
                initialValue: _separate,
                isExpanded: true,
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Laver séparément',
                    en: 'Wash separately',
                    ar: 'يغسل منفصلاً',
                  ),
                ),
                items: [
                  DropdownMenuItem<bool>(
                    value: null,
                    child: Text(
                      context.tr(fr: 'Inconnu', en: 'Unknown', ar: 'غير معروف'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(context.tr(fr: 'Oui', en: 'Yes', ar: 'نعم')),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(context.tr(fr: 'Non', en: 'No', ar: 'لا')),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _separate = v),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _confirmed = v ?? false),
                title: Text(
                  context.tr(
                    fr: 'J’ai vérifié le lot et les indications disponibles. Les valeurs inconnues restent à vérifier.',
                    en: 'I checked the lot and available care instructions. Unknown values still need review.',
                    ar: 'تحققت من المجموعة وتعليمات العناية المتاحة. تبقى القيم المجهولة بحاجة إلى مراجعة.',
                  ),
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(context.localize('Annuler')),
      ),
      FilledButton(
        onPressed: _saving || !_confirmed ? null : _save,
        child: Text(context.localize('Enregistrer')),
      ),
    ],
  );
}
