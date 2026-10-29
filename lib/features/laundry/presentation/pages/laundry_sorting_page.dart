import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/laundry_sorting_data.dart';
import '../../data/repositories/laundry_repository.dart';
import '../../domain/models/laundry_sorting.dart';
import '../widgets/laundry_design.dart';
import '../widgets/laundry_language_button.dart';
import '../widgets/laundry_sorting_labels.dart';
import '../widgets/laundry_sorting_profile_dialog.dart';

class LaundrySortingButton extends StatelessWidget {
  const LaundrySortingButton({
    super.key,
    required this.repository,
    this.onReturn,
  });
  final LaundryRepository repository;
  final VoidCallback? onReturn;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.layers_outlined),
    label: Text(
      context.tr(fr: 'Tri intelligent', en: 'Smart sorting', ar: 'الفرز الذكي'),
    ),
    onPressed: () async {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LaundrySortingPage(repository: repository),
        ),
      );
      if (context.mounted) onReturn?.call();
    },
  );
}

class LaundrySortingPage extends StatefulWidget {
  const LaundrySortingPage({super.key, required this.repository});
  final LaundryRepository repository;
  @override
  State<LaundrySortingPage> createState() => _LaundrySortingPageState();
}

class _LaundrySortingPageState extends State<LaundrySortingPage> {
  late Future<LaundrySortingData> _data;
  @override
  void initState() {
    super.initState();
    _data = widget.repository.getSortingData();
  }

  void _refresh() {
    final next = widget.repository.getSortingData();
    setState(() {
      _data = next;
    });
  }

  Future<void> _edit(LaundrySortingLot lot, LaundrySortingData data) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => LaundrySortingProfileDialog(
        repository: widget.repository,
        lot: lot,
        revision: data.revisions[lot.requestId]!,
      ),
    );
    if (saved == true && mounted) _refresh();
  }

  Widget _lot(LaundrySortingLot lot, LaundrySortingData data) => Column(
    key: ValueKey('sorting-lot-${lot.requestId}-${lot.lineId}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${lot.garment} · ${lot.quantity}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
      Text(
        '#${lot.requestId} · ${lot.lineId}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (lot.instructions.trim().isNotEmpty) Text(lot.instructions),
      if (lot.profile?.verifiedAt != null)
        Text(
          context.tr(
            fr: 'Dernière vérification : ${MaterialLocalizations.of(context).formatMediumDate(lot.profile!.verifiedAt!.toLocal())} · compte #${lot.profile!.verifiedByUserId}',
            en: 'Last check: ${MaterialLocalizations.of(context).formatMediumDate(lot.profile!.verifiedAt!.toLocal())} · account #${lot.profile!.verifiedByUserId}',
            ar: 'آخر تحقق: ${MaterialLocalizations.of(context).formatMediumDate(lot.profile!.verifiedAt!.toLocal())} · الحساب #${lot.profile!.verifiedByUserId}',
          ),
        ),
      if (lot.serviceId == 'washing')
        TextButton.icon(
          onPressed: () => _edit(lot, data),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(
            context.tr(
              fr: 'Vérifier l’étiquette',
              en: 'Check care label',
              ar: 'التحقق من ملصق العناية',
            ),
          ),
        ),
    ],
  );

  Widget _panel(Color tint, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(
        context.tr(
          fr: 'Tri intelligent',
          en: 'Smart sorting',
          ar: 'الفرز الذكي',
        ),
      ),
      actions: [
        const LaundryLanguageButton(compact: true),
        IconButton(
          onPressed: _refresh,
          tooltip: context.localize('Actualiser'),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<LaundrySortingData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(
                      fr: 'Tri indisponible. Un compte pressing ou administrateur est requis. Vérifiez aussi la connexion locale.',
                      en: 'Sorting unavailable. A pressing or administrator account is required. Also check local storage.',
                      ar: 'الفرز غير متاح. يلزم حساب المغسلة أو المدير. تحقق أيضًا من التخزين المحلي.',
                    ),
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: Text(context.localize('Réessayer')),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LaundrySectionHeader(
              title: context.tr(
                fr: 'Des lots compatibles, un tri expliqué',
                en: 'Compatible lots, explained sorting',
                ar: 'مجموعات متوافقة مع تفسير الفرز',
              ),
              subtitle: context.tr(
                fr: 'Demandes déposées uniquement. Les propositions restent à confirmer par le pressing. Les demandes restent séparées ; aucune machine ni capacité n’est réservée.',
                en: 'Deposited requests only. Pressing staff must confirm suggestions. Requests stay separate; no machine or capacity is reserved.',
                ar: 'الطلبات المودعة فقط. يجب على المغسلة تأكيد الاقتراحات. تبقى الطلبات منفصلة ولا تحجز آلة أو سعة.',
              ),
              icon: Icons.layers_outlined,
              accent: LaundryPalette.teal,
            ),
            const SizedBox(height: 18),
            Text(
              context.tr(
                fr: '${data.plan.groups.where((g) => g.canCombine).length} groupe(s) proposé(s) · ${data.plan.reviews.length} lot(s) à examiner',
                en: '${data.plan.groups.where((g) => g.canCombine).length} suggested group(s) · ${data.plan.reviews.length} lot(s) to review',
                ar: '${data.plan.groups.where((g) => g.canCombine).length} مجموعات مقترحة · ${data.plan.reviews.length} مجموعات للمراجعة',
              ),
            ),
            const SizedBox(height: 16),
            if (data.lots.isEmpty && data.requestsWithoutLots.isEmpty)
              LaundryEmptyState(
                title: context.tr(
                  fr: 'Aucun lot déposé à trier',
                  en: 'No deposited lots to sort',
                  ar: 'لا توجد مجموعات مودعة للفرز',
                ),
              ),
            for (final group in data.plan.groups)
              _panel(LaundryPalette.mint, [
                Text(
                  context.tr(
                    fr: group.canCombine
                        ? 'Regroupement proposé'
                        : 'Lot compatible, à conserver seul',
                    en: group.canCombine
                        ? 'Suggested grouping'
                        : 'Eligible lot, keep separate for now',
                    ar: group.canCombine
                        ? 'تجميع مقترح'
                        : 'مجموعة متوافقة تبقى منفصلة حاليًا',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: LaundryPalette.teal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${sortingLabel(context, group.color)} · ${sortingLabel(context, group.fabric)} · ${sortingLabel(context, group.cycle)} · ${group.maxTemperatureC} °C',
                ),
                Text(
                  context.tr(
                    fr: 'Même demande et mêmes caractéristiques vérifiées ; risque de décoloration déclaré faible, aucune consigne de séparation.',
                    en: 'Same request and verified care properties; declared low dye-transfer risk and no separate-wash instruction.',
                    ar: 'الطلب نفسه وخصائص عناية متطابقة ومتحقق منها؛ خطر انتقال لون منخفض ولا تعليمات فصل.',
                  ),
                ),
                Text(
                  group.weightGrams == null
                      ? context.tr(
                          fr: 'Poids total inconnu',
                          en: 'Total weight unknown',
                          ar: 'الوزن الإجمالي غير معروف',
                        )
                      : '${(group.weightGrams! / 1000).toStringAsFixed(3)} kg',
                ),
                for (final lot in group.lots) ...[
                  const Divider(),
                  _lot(lot, data),
                ],
              ]),
            for (final review in data.plan.reviews)
              _panel(LaundryPalette.peach, [
                _lot(review.lot, data),
                for (final reason in review.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text('• ${sortingLabel(context, reason)}'),
                  ),
              ]),
            for (final id in data.requestsWithoutLots)
              _panel(LaundryPalette.lilac, [
                Text(
                  context.tr(
                    fr: 'Demande #$id : aucun détail des articles. Renseigner les lots avant de proposer un tri.',
                    en: 'Request #$id: no article details. Add lots before proposing a sort.',
                    ar: 'الطلب #$id: لا توجد تفاصيل الملابس. أضف المجموعات قبل اقتراح الفرز.',
                  ),
                ),
              ]),
          ],
        );
      },
    ),
  );
}
