import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/laundry_details.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../domain/models/laundry_quote.dart';
import '../widgets/laundry_design.dart';
import '../widgets/laundry_request_editor.dart';
import '../widgets/laundry_language_button.dart';

class LaundryTariffsPage extends StatefulWidget {
  const LaundryTariffsPage({super.key, required this.repository});
  final LaundryRepository repository;
  @override
  State<LaundryTariffsPage> createState() => _LaundryTariffsPageState();
}

class _LaundryTariffsPageState extends State<LaundryTariffsPage> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController(), _minutes = TextEditingController();
  List<LaundryServiceType> _services = [];
  List<LaundryTariff> _tariffs = [];
  String? _service, _error;
  LaundryPricingBasis _basis = LaundryPricingBasis.perKilogram;
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _price.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tariffs = await widget.repository.getTariffs();
      final services = await widget.repository.getServices();
      if (mounted) {
        setState(() {
          _tariffs = tariffs;
          _services = services;
          _service ??= services.firstOrNull?.id;
          _loading = false;
          _error = null;
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

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveTariff(
        serviceId: _service!,
        basis: _basis,
        unitPriceMillimes: laundryMilliUnits(_price.text)!,
        estimatedMinutes: _minutes.text.trim().isEmpty
            ? null
            : int.parse(_minutes.text.trim()),
      );
      if (!mounted) return;
      _price.clear();
      _minutes.clear();
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = 'save');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final active = _tariffs.where((t) => t.rate.appliesAt(now)).toList();
    String basisLabel(LaundryPricingBasis basis) =>
        basis == LaundryPricingBasis.perKilogram
        ? context.tr(
            fr: 'Par kilogramme',
            en: 'Per kilogram',
            ar: 'لكل كيلوغرام',
          )
        : context.tr(fr: 'Par pièce', en: 'Per item', ar: 'لكل قطعة');
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        actions: const [LaundryLanguageButton(compact: true)],
        title: Text(
          context.tr(
            fr: 'Tarifs du linge',
            en: 'Laundry tariffs',
            ar: 'تعريفات الغسيل',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error == 'load'
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: Text(context.localize('Réessayer')),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LaundrySectionHeader(
                  title: context.tr(
                    fr: 'Configurer les calculs',
                    en: 'Configure calculations',
                    ar: 'إعداد الحسابات',
                  ),
                  subtitle: context.tr(
                    fr: 'Les nouvelles règles ne changent pas les devis déjà enregistrés.',
                    en: 'New rules do not change saved quotes.',
                    ar: 'لا تغيّر القواعد الجديدة الأسعار المحفوظة.',
                  ),
                  icon: Icons.calculate_outlined,
                ),
                const SizedBox(height: 20),
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _service,
                        isExpanded: true,
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Service',
                            en: 'Service',
                            ar: 'الخدمة',
                          ),
                        ),
                        items: _services
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.label(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (s) => setState(() => _service = s),
                        validator: (v) => v == null
                            ? context.localize('Champ obligatoire')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LaundryPricingBasis>(
                        initialValue: _basis,
                        isExpanded: true,
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Facturation',
                            en: 'Pricing basis',
                            ar: 'أساس التسعير',
                          ),
                        ),
                        items: LaundryPricingBasis.values
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(basisLabel(b)),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (b) => setState(() => _basis = b!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: !_saving,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Prix unitaire (DT)',
                            en: 'Unit price (DT)',
                            ar: 'سعر الوحدة (د.ت)',
                          ),
                        ),
                        validator: (v) =>
                            laundryMilliUnits(v ?? '') == null ||
                                laundryMilliUnits(v ?? '')! > 9007199254740
                            ? context.tr(
                                fr: 'Montant valide, 3 décimales maximum',
                                en: 'Valid amount, at most 3 decimals',
                                ar: 'مبلغ صالح، حتى 3 أرقام عشرية',
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        enabled: !_saving,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        decoration: laundryFieldDecoration(
                          label: context.tr(
                            fr: 'Durée indicative par lot (minutes, facultative)',
                            en: 'Estimated time per lot (minutes, optional)',
                            ar: 'مدة تقديرية للمجموعة (دقائق، اختياري)',
                          ),
                          helper: context.tr(
                            fr: 'Estimation métier, sans réservation de machine ni de capacité.',
                            en: 'Business estimate, without reserving a machine or capacity.',
                            ar: 'تقدير للمعالجة، دون حجز آلة أو سعة.',
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final value = v.trim();
                          final n = int.tryParse(value);
                          return !RegExp(r'^\d+$').hasMatch(value) ||
                                  n == null ||
                                  n <= 0 ||
                                  n > 525600
                              ? context.tr(
                                  fr: 'Durée positive attendue',
                                  en: 'Enter a positive duration',
                                  ar: 'أدخل مدة موجبة',
                                )
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(context.localize('Enregistrer')),
                      ),
                    ],
                  ),
                ),
                if (_error == 'save')
                  Text(
                    context.tr(
                      fr: 'Tarif non enregistré. Réessayez.',
                      en: 'Tariff not saved. Try again.',
                      ar: 'لم يتم حفظ التعريفة. أعد المحاولة.',
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.tr(
                    fr: 'Tarifs actifs',
                    en: 'Active tariffs',
                    ar: 'التعريفات النشطة',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      context.tr(
                        fr: 'Aucun tarif configuré. Les demandes restent à tarifer.',
                        en: 'No configured tariffs. Requests remain unpriced.',
                        ar: 'لا توجد تعريفات معدّة. تبقى الطلبات دون تسعير.',
                      ),
                    ),
                  ),
                for (final tariff in active)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${_services.where((s) => s.id == tariff.rate.serviceCode).firstOrNull?.label(Localizations.localeOf(context).languageCode) ?? tariff.rate.serviceCode} · ${basisLabel(tariff.rate.basis)}',
                      ),
                      subtitle: Text(
                        '${(tariff.rate.unitPriceMillimes / 1000).toStringAsFixed(3)} DT${tariff.estimatedMinutes == null ? '' : ' · ${tariff.estimatedMinutes} min'}',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
