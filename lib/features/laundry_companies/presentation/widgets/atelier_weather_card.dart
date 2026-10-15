import 'package:flutter/material.dart';
import '../../../../core/services/open_meteo_service.dart';
import '../../../../core/theme/app_theme.dart';

class AtelierWeatherCard extends StatefulWidget {
  const AtelierWeatherCard({super.key});

  @override
  State<AtelierWeatherCard> createState() => _AtelierWeatherCardState();
}

class _AtelierWeatherCardState extends State<AtelierWeatherCard> {
  late Future<AtelierMeteoData> _meteoFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _meteoFuture = OpenMeteoService.instance.fetchAtelierMeteo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AtelierMeteoData>(
      future: _meteoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Connexion satellite météo (Open-Meteo)...',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          );
        }

        final meteo = snapshot.data ?? OpenMeteoService.instance.fetchAtelierMeteo() as AtelierMeteoData;
        final isHighDemand = meteo.augmentationSechagePercent >= 30;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                meteo.couleur.withValues(alpha: 0.12),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: meteo.couleur.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: meteo.couleur.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Location, Status, Refresh
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: meteo.couleur.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: meteo.couleur),
                          const SizedBox(width: 4),
                          Text(
                            'Grand Tunis • Live IoT Satellite',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: meteo.couleur,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _refresh,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.refresh_rounded, size: 16, color: meteo.couleur),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Weather Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: meteo.couleur.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(meteo.icone, color: meteo.couleur, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${meteo.temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                meteo.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: meteo.couleur,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, size: 12, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                'Humidité: ${meteo.humidite}%',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.air_rounded, size: 12, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                'Vent: ${meteo.ventVitesse.toStringAsFixed(0)} km/h',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Prediction badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isHighDemand ? Colors.orange.shade700 : Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+${meteo.augmentationSechagePercent}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Séchage',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 10),

                // AI Decision Support Banner
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isHighDemand ? Icons.bolt_rounded : Icons.eco_rounded,
                      size: 16,
                      color: isHighDemand ? Colors.orange.shade800 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meteo.recommandationProduction,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isHighDemand ? Colors.orange.shade900 : Colors.green.shade900,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
