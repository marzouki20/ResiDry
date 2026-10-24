import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/laundry_report.dart';
import '../../data/repositories/laundry_repository.dart';
import '../widgets/laundry_design.dart';

/// Reads the repository again on entry/refresh: no sample figures or stale
/// totals passed by another role's screen.
class LaundryDashboardPage extends StatefulWidget {
  const LaundryDashboardPage({super.key, required this.repository});
  final LaundryRepository repository;
  @override
  State<LaundryDashboardPage> createState() => _LaundryDashboardPageState();
}

class _LaundryDashboardPageState extends State<LaundryDashboardPage> {
  late Future<LaundryReport> _report;
  @override
  void initState() {
    super.initState();
    _report = widget.repository.getReport();
  }

  void _refresh() {
    final nextReport = widget.repository.getReport();
    setState(() {
      _report = nextReport;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.tr(
          fr: 'Tableau de bord du linge',
          en: 'Laundry dashboard',
          ar: 'لوحة متابعة الغسيل',
        ),
      ),
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: context.localize('Actualiser'),
        ),
      ],
    ),
    backgroundColor: AppColors.cream,
    body: FutureBuilder<LaundryReport>(
      future: _report,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: LaundryEmptyState(
              title: context.tr(
                fr: 'Statistiques indisponibles',
                en: 'Statistics unavailable',
                ar: 'الإحصائيات غير متاحة',
              ),
              action: FilledButton(
                onPressed: _refresh,
                child: Text(context.localize('Réessayer')),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = snapshot.data!;
        final stats = report.statistics;
        final locale = MaterialLocalizations.of(context);
        final entries = <(String, String)>[
          (
            context.tr(fr: 'Demandes', en: 'Requests', ar: 'الطلبات'),
            '${stats.totalRequests}',
          ),
          (
            context.tr(
              fr: 'À traiter / en traitement',
              en: 'Awaiting / in treatment',
              ar: 'بانتظار المعالجة / قيد المعالجة',
            ),
            '${stats.activeTreatmentRequests}',
          ),
          (
            context.tr(
              fr: 'Prêtes à livrer',
              en: 'Ready for delivery',
              ar: 'جاهزة للتسليم',
            ),
            '${stats.awaitingDeliveryRequests}',
          ),
          (context.localize('Livrées'), '${stats.deliveredRequests}'),
          (
            context.tr(
              fr: 'Traitement moyen',
              en: 'Average treatment time',
              ar: 'متوسط وقت المعالجة',
            ),
            stats.averageProcessingTime == null
                ? '—'
                : '${(stats.averageProcessingTime!.inSeconds / 60).toStringAsFixed(1)} min',
          ),
          (
            context.tr(
              fr: 'Retards de traitement',
              en: 'Treatment delays',
              ar: 'تأخر المعالجة',
            ),
            stats.activeTreatmentRequests > 0 &&
                    stats.missingDeadlineRequests ==
                        stats.activeTreatmentRequests
                ? '—'
                : '${stats.overdueTreatmentRequests}',
          ),
          if (stats.confirmedDeliveredValueMillimes != null)
            (
              context.tr(
                fr: 'Valeur livrée confirmée',
                en: 'Confirmed delivered value',
                ar: 'قيمة الطلبات المسلّمة المؤكدة',
              ),
              '${(stats.confirmedDeliveredValueMillimes! / 1000).toStringAsFixed(3)} DT',
            ),
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LaundrySectionHeader(
              title: context.tr(
                fr: 'Votre activité en chiffres',
                en: 'Your activity in figures',
                ar: 'نشاطك بالأرقام',
              ),
              subtitle:
                  '${locale.formatMediumDate(report.evaluatedAt.toLocal())} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(report.evaluatedAt.toLocal()))}',
              icon: Icons.insights_outlined,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, value) in entries)
                    Container(
                      width: constraints.maxWidth >= 500
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 26,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr(
                fr: 'Durée moyenne : ${stats.measurableProcessingRequests} historique(s) complet(s) mesuré(s), ${stats.unmeasuredCompletedRequests} exclu(s). Du début du traitement au statut prêt.',
                en: 'Average: ${stats.measurableProcessingRequests} complete histories measured, ${stats.unmeasuredCompletedRequests} excluded. From treatment start to ready.',
                ar: 'المتوسط: ${stats.measurableProcessingRequests} سجلات مكتملة، واستبعاد ${stats.unmeasuredCompletedRequests}. من بدء المعالجة إلى الجاهزية.',
              ),
            ),
            if (stats.missingDeadlineRequests > 0) ...[
              const SizedBox(height: 12),
              Text(
                context.tr(
                  fr: '${stats.missingDeadlineRequests} demande(s) active(s) sans échéance : retard non évaluable.',
                  en: '${stats.missingDeadlineRequests} active request(s) have no deadline: delays cannot be assessed.',
                  ar: '${stats.missingDeadlineRequests} طلبات نشطة دون موعد نهائي: لا يمكن تقييم التأخير.',
                ),
              ),
            ],
            if (stats.confirmedDeliveredValueMillimes != null) ...[
              const SizedBox(height: 12),
              Text(
                context.tr(
                  fr: 'Valeur des prestations livrées, pas un encaissement. ${stats.unconfirmedDeliveredRequests} demande(s) livrée(s) sans tarif confirmé exclue(s).',
                  en: 'Value of delivered services, not collected payments. ${stats.unconfirmedDeliveredRequests} delivered request(s) without a confirmed price excluded.',
                  ar: 'قيمة الخدمات المسلّمة، وليست المدفوعات المقبوضة. استبعاد ${stats.unconfirmedDeliveredRequests} طلبات دون سعر مؤكد.',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              context.tr(
                fr: 'Services les plus demandés',
                en: 'Most requested services',
                ar: 'الخدمات الأكثر طلبًا',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (stats.popularServices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.tr(
                    fr: 'Aucune demande enregistrée.',
                    en: 'No saved requests.',
                    ar: 'لا توجد طلبات مسجلة.',
                  ),
                ),
              ),
            for (final service in stats.popularServices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.localize(service.serviceCode)),
                trailing: Text('${service.requests}'),
              ),
          ],
        );
      },
    ),
  );
}

class LaundryDashboardButton extends StatelessWidget {
  const LaundryDashboardButton({super.key, required this.repository});
  final LaundryRepository repository;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LaundryDashboardPage(repository: repository),
      ),
    ),
    icon: const Icon(Icons.insights_outlined),
    label: Text(
      context.tr(fr: 'Tableau de bord', en: 'Dashboard', ar: 'لوحة المتابعة'),
    ),
  );
}
