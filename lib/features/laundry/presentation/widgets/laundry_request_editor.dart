import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_role.dart';
import '../../../../models/user.dart';
import '../../data/models/laundry_details.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../domain/models/laundry_quote.dart';
import '../../domain/models/laundry_workload.dart';
import 'laundry_design.dart';
import 'laundry_messages.dart';

/// Exact decimal input for kg/DT: at most three decimal places, no float rounding.
int? laundryMilliUnits(String input) {
  final value = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null || whole > 9007199254740) return null;
  return whole * 1000 +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(3, '0'));
}

class _LineFields {
  _LineFields({LaundryLine? line})
    : id = line?.id ?? 'LINE${DateTime.now().microsecondsSinceEpoch}',
      garment = TextEditingController(text: line?.garment ?? ''),
      quantity = TextEditingController(text: '${line?.quantity ?? 1}'),
      weight = TextEditingController(
        text: line?.weightGrams == null
            ? ''
            : (line!.weightGrams! / 1000).toStringAsFixed(3),
      ),
      instructions = TextEditingController(text: line?.instructions ?? ''),
      service = line?.serviceId ?? 'washing',
      basis = line?.basis ?? LaundryPricingBasis.perKilogram;
  final String id;
  final TextEditingController garment, quantity, weight, instructions;
  final garmentKey = GlobalKey<FormFieldState<String>>();
  final quantityKey = GlobalKey<FormFieldState<String>>();
  final weightKey = GlobalKey<FormFieldState<String>>();
  String service;
  LaundryPricingBasis basis;
  LaundryLine value() => LaundryLine(
    id: id,
    garment: garment.text.trim(),
    serviceId: service,
    quantity: int.tryParse(quantity.text) ?? 0,
    weightGrams: weight.text.trim().isEmpty
        ? null
        : laundryMilliUnits(weight.text),
    instructions: instructions.text,
    basis: basis,
  );
  void dispose() {
    garment.dispose();
    quantity.dispose();
    weight.dispose();
    instructions.dispose();
  }
}

/// Owns every controller; authentication, pricing and ownership are rechecked
/// by the repository on submission, regardless of what this form displays.
class LaundryRequestEditor extends StatefulWidget {
  const LaundryRequestEditor({super.key, required this.repository, this.item});
  final LaundryRepository repository;
  final LaundryItem? item;
  @override
  State<LaundryRequestEditor> createState() => _LaundryRequestEditorState();
}

class _LaundryRequestEditorState extends State<LaundryRequestEditor> {
  final _form = GlobalKey<FormState>();
  final _residentField = GlobalKey<FormFieldState<int>>();
  final _lines = <_LineFields>[];
  final _retired = <_LineFields>[];
  List<LaundryServiceType> _services = [];
  List<User> _residents = [];
  User? _actor;
  int? _residentId;
  LaundryDetails? _existing, _preview;
  LaundryStatus _status = LaundryStatus.deposited;
  LaundryUrgency _urgency = LaundryUrgency.normal;
  DateTime? _due;
  bool _loading = true, _saving = false;
  String? _error;
  late final String _id =
      widget.item?.id ?? 'LD${DateTime.now().microsecondsSinceEpoch}';
  bool get _admin =>
      laundryRoleFromUserRole(_actor?.role ?? '') == LaundryRole.admin;
  bool get _frozen =>
      _existing != null && _existing!.item.status != LaundryStatus.deposited;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final actor = await widget.repository.getCurrentUser();
      final services = await widget.repository.getServices();
      final admin = laundryRoleFromUserRole(actor.role) == LaundryRole.admin;
      final residents = admin
          ? await widget.repository.getResidents()
          : <User>[];
      final existing = widget.item == null
          ? null
          : await widget.repository.getDetails(widget.item!.id);
      if (!mounted) return;
      setState(() {
        _actor = actor;
        _services = services;
        _residents = residents;
        _existing = existing;
        _residentId = admin ? existing?.item.residentId : actor.id;
        _status = existing?.item.status ?? LaundryStatus.deposited;
        _urgency = existing?.urgency ?? LaundryUrgency.normal;
        _due = existing?.dueAt;
        if (existing != null && existing.lines.isNotEmpty) {
          _lines.addAll(existing.lines.map((line) => _LineFields(line: line)));
        } else if (!_frozen) {
          _lines.add(_LineFields());
        }
        _loading = false;
      });
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
    for (final line in [..._lines, ..._retired]) {
      line.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (_preview != null) setState(() => _preview = null);
  }

  LaundryDetails _draft() => LaundryDetails(
    item: LaundryItem(
      id: _id,
      residentId: _residentId,
      residentName: '',
      serviceType: widget.item?.serviceType ?? 'Laundry',
      status: _status,
      price: 0,
    ),
    lines: _lines.map((line) => line.value()).toList(),
    dueAt: _due,
    urgency: _urgency,
    revision: _existing?.revision ?? 0,
  );
  Future<void> _submit({bool preview = false}) async {
    if (_saving) return;
    if (!_form.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final keys = <GlobalKey>[
          _residentField,
          for (final line in _lines) ...[
            line.garmentKey,
            line.quantityKey,
            line.weightKey,
          ],
        ];
        for (final key in keys) {
          final state = key.currentState;
          if (state is FormFieldState &&
              state.hasError &&
              key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              alignment: .15,
              duration: const Duration(milliseconds: 220),
            );
            break;
          }
        }
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (preview) {
        final result = await widget.repository.previewRequest(_draft());
        if (mounted) setState(() => _preview = result);
      } else {
        await widget.repository.saveRequest(_draft());
        if (mounted) Navigator.pop(context, true);
      }
    } on LaundryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final first = (_existing?.item.createdAt ?? now).toLocal();
    final day = await showDatePicker(
      context: context,
      initialDate: (_due ?? now).toLocal(),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(now.year + 5),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime((_due ?? now).toLocal()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _due = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ).toUtc();
      _preview = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LaundryPalette.peach, LaundryPalette.lilac],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        context.localize(
          widget.item == null ? 'Nouvelle demande' : 'Modifier la demande',
        ),
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    content: SizedBox(
      width: 600,
      child: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : _actor == null
          ? Text(
              context.tr(
                fr: 'Impossible de charger le formulaire.',
                en: 'Unable to load the form.',
                ar: 'تعذّر تحميل النموذج.',
              ),
            )
          : Form(
              key: _form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        context.tr(
                          fr: 'Renseignez vos articles. Les champs obligatoires sont indiqués ; aucun prix à saisir.',
                          en: 'Add your articles. Required fields are marked; no price to enter.',
                          ar: 'أضف ملابسك. الحقول المطلوبة موضّحة؛ لا حاجة لإدخال سعر.',
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_admin)
                      DropdownButtonFormField<int>(
                        key: _residentField,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: _residentId,
                        isExpanded: true,
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Compte résident',
                            en: 'Resident account',
                            ar: 'حساب المقيم',
                          ),
                        ),
                        items: _residents
                            .map(
                              (u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(
                                  '${u.name} · #${u.id}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _residentId = value),
                        validator: (value) =>
                            value == null &&
                                (_existing == null ||
                                    _existing!.item.residentId != null)
                            ? context.localize(
                                'Sélectionnez un compte résident.',
                              )
                            : null,
                      ),
                    if (_admin && _residentId != null)
                      Text(
                        context.tr(
                          fr: 'Résident : ${_residents.where((u) => u.id == _residentId).firstOrNull?.name ?? ''}',
                          en: 'Resident: ${_residents.where((u) => u.id == _residentId).firstOrNull?.name ?? ''}',
                          ar: 'المقيم: ${_residents.where((u) => u.id == _residentId).firstOrNull?.name ?? ''}',
                        ),
                      ),
                    if (_frozen)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          context.tr(
                            fr: 'Articles et devis conservés : le traitement a déjà commencé.',
                            en: 'Articles and quote are preserved: treatment has started.',
                            ar: 'تم حفظ الملابس والسعر: بدأت المعالجة.',
                          ),
                        ),
                      ),
                    if (_frozen && _lines.isEmpty)
                      Text(
                        context.tr(
                          fr: 'Ancienne demande sans détail des articles.',
                          en: 'Legacy request without article details.',
                          ar: 'طلب قديم دون تفاصيل الملابس.',
                        ),
                      ),
                    for (var index = 0; index < _lines.length; index++)
                      _lineEditor(_lines[index], index),
                    if (!_frozen && _lines.length < 100)
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _lines.add(_LineFields());
                                _preview = null;
                              }),
                        icon: const Icon(Icons.add),
                        label: Text(
                          context.tr(
                            fr: 'Ajouter un lot',
                            en: 'Add a lot',
                            ar: 'إضافة مجموعة',
                          ),
                        ),
                      ),
                    const Divider(),
                    DropdownButtonFormField<LaundryUrgency>(
                      initialValue: _urgency,
                      isExpanded: true,
                      decoration: laundryFieldDecoration(
                        label: context.tr(
                          fr: 'Urgence',
                          en: 'Urgency',
                          ar: 'الاستعجال',
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: LaundryUrgency.normal,
                          child: Text(
                            context.tr(
                              fr: 'Normale',
                              en: 'Normal',
                              ar: 'عادية',
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: LaundryUrgency.urgent,
                          child: Text(
                            context.tr(
                              fr: 'Urgente',
                              en: 'Urgent',
                              ar: 'عاجلة',
                            ),
                          ),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                              _urgency = value!;
                              _preview = null;
                            }),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _saving ? null : _pickDue,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            _due == null
                                ? context.tr(
                                    fr: 'Échéance de traitement (facultative)',
                                    en: 'Treatment deadline (optional)',
                                    ar: 'موعد المعالجة (اختياري)',
                                  )
                                : '${MaterialLocalizations.of(context).formatMediumDate(_due!.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_due!.toLocal()))}',
                          ),
                        ),
                        if (_due != null)
                          IconButton(
                            onPressed: () => setState(() {
                              _due = null;
                              _preview = null;
                            }),
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                    if (_admin)
                      DropdownButtonFormField<LaundryStatus>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Statut',
                            en: 'Status',
                            ar: 'الحالة',
                          ),
                        ),
                        items: LaundryStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(laundryStatusText(context, s)),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (s) => setState(() {
                                _status = s!;
                                _preview = null;
                              }),
                      ),
                    if (_admin && !_frozen) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _submit(preview: true),
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(
                          context.tr(
                            fr: 'Calculer le devis',
                            en: 'Calculate quote',
                            ar: 'حساب السعر',
                          ),
                        ),
                      ),
                      if (_preview != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _preview!.item.priceConfirmed
                                ? '${(_preview!.item.price).toStringAsFixed(3)} DT'
                                : context.tr(
                                    fr: 'Devis incomplet : vérifiez les tarifs et les poids.',
                                    en: 'Incomplete quote: check rates and weights.',
                                    ar: 'سعر غير مكتمل: تحقق من التعريفات والأوزان.',
                                  ),
                          ),
                        ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error == 'save'
                              ? context.tr(
                                  fr: 'Enregistrement impossible. Réessayez.',
                                  en: 'Unable to save. Try again.',
                                  ar: 'تعذّر الحفظ. أعد المحاولة.',
                                )
                              : laundryMessage(context, _error!),
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
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(context.localize('Annuler')),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _loading || _saving || _actor == null
            ? null
            : () => _submit(),
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.localize('Enregistrer')),
      ),
    ],
  );
  Widget _lineEditor(_LineFields line, int index) => Container(
    key: ValueKey(line.id),
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: LaundryPalette.sky.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(
                  fr: 'Lot ${index + 1}',
                  en: 'Lot ${index + 1}',
                  ar: 'المجموعة ${index + 1}',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!_frozen && _lines.length > 1)
              IconButton(
                onPressed: () => setState(() {
                  _retired.add(_lines.removeAt(index));
                  _preview = null;
                }),
                icon: const Icon(Icons.delete_outline),
                tooltip: context.localize('Supprimer'),
              ),
          ],
        ),
        TextFormField(
          controller: line.garment,
          key: line.garmentKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: !_frozen && !_saving,
          maxLength: 120,
          onChanged: (_) => _changed(),
          decoration: laundryFieldDecoration(
            label: context.tr(fr: 'Vêtement', en: 'Garment', ar: 'نوع الملابس'),
            helper: context.tr(
              fr: 'Obligatoire · exemple : chemise blanche',
              en: 'Required · example: white shirt',
              ar: 'مطلوب · مثال: قميص أبيض',
            ),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? context.localize('Champ obligatoire')
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: line.service,
          isExpanded: true,
          decoration: laundryFieldDecoration(
            label: context.tr(fr: 'Service', en: 'Service', ar: 'الخدمة'),
          ),
          items: _services
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    s.label(Localizations.localeOf(context).languageCode),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _frozen || _saving
              ? null
              : (s) => setState(() {
                  line.service = s!;
                  _preview = null;
                }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: line.quantity,
          key: line.quantityKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: !_frozen && !_saving,
          keyboardType: TextInputType.number,
          onChanged: (_) => _changed(),
          decoration: laundryFieldDecoration(
            label: context.tr(fr: 'Quantité', en: 'Quantity', ar: 'الكمية'),
            helper: context.tr(
              fr: 'Obligatoire · nombre entier de 1 à 100 000',
              en: 'Required · whole number from 1 to 100,000',
              ar: 'مطلوب · عدد صحيح من 1 إلى 100000',
            ),
          ),
          validator: (v) {
            final value = (v ?? '').trim();
            final n = int.tryParse(value);
            return !RegExp(r'^\d+$').hasMatch(value) ||
                    n == null ||
                    n <= 0 ||
                    n > 100000
                ? context.tr(
                    fr: 'Quantité positive attendue',
                    en: 'Enter a positive quantity',
                    ar: 'أدخل كمية موجبة',
                  )
                : null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LaundryPricingBasis>(
          initialValue: line.basis,
          isExpanded: true,
          decoration: laundryFieldDecoration(
            label: context.tr(
              fr: 'Facturation',
              en: 'Pricing basis',
              ar: 'أساس التسعير',
            ),
          ),
          items: [
            DropdownMenuItem(
              value: LaundryPricingBasis.perKilogram,
              child: Text(
                context.tr(
                  fr: 'Par kilogramme',
                  en: 'Per kilogram',
                  ar: 'لكل كيلوغرام',
                ),
              ),
            ),
            DropdownMenuItem(
              value: LaundryPricingBasis.perItem,
              child: Text(
                context.tr(fr: 'Par pièce', en: 'Per item', ar: 'لكل قطعة'),
              ),
            ),
          ],
          onChanged: _frozen || _saving
              ? null
              : (b) => setState(() {
                  line.basis = b!;
                  _preview = null;
                }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: line.weight,
          key: line.weightKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: !_frozen && !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _changed(),
          decoration: laundryFieldDecoration(
            label: context.tr(
              fr: 'Poids du lot (kg, facultatif)',
              en: 'Lot weight (kg, optional)',
              ar: 'وزن المجموعة (كغ، اختياري)',
            ),
            helper: context.tr(
              fr: 'Exemple : 2,500 kg. Sans poids, le devis au kg restera à établir.',
              en: 'Example: 2.500 kg. A per-kg quote needs a measured weight.',
              ar: 'مثال: 2.500 كغ. التسعير بالكيلوغرام يتطلب وزنًا مقاسًا.',
            ),
          ),
          validator: (v) =>
              v == null ||
                  v.trim().isEmpty ||
                  (laundryMilliUnits(v) != null &&
                      laundryMilliUnits(v)! > 0 &&
                      laundryMilliUnits(v)! <= 100000000)
              ? null
              : context.tr(
                  fr: 'Poids positif, 3 décimales maximum',
                  en: 'Positive weight, at most 3 decimals',
                  ar: 'وزن موجب، حتى 3 أرقام عشرية',
                ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: line.instructions,
          enabled: !_frozen && !_saving,
          maxLength: 2000,
          maxLines: 2,
          onChanged: (_) => _changed(),
          decoration: laundryFieldDecoration(
            label: context.tr(
              fr: 'Instructions particulières',
              en: 'Special instructions',
              ar: 'تعليمات خاصة',
            ),
          ),
        ),
      ],
    ),
  );
}
