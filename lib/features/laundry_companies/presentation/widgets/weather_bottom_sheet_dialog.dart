import 'package:flutter/material.dart';
import '../../../../core/services/open_meteo_service.dart';
import '../../../../core/theme/app_theme.dart';

class WeatherBottomSheetDialog extends StatefulWidget {
  const WeatherBottomSheetDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WeatherBottomSheetDialog(),
    );
  }

  @override
  State<WeatherBottomSheetDialog> createState() => _WeatherBottomSheetDialogState();
}

class _WeatherBottomSheetDialogState extends State<WeatherBottomSheetDialog>
    with SingleTickerProviderStateMixin {
  late Future<AtelierMeteoData> _meteoFuture;
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _meteoFuture = OpenMeteoService.instance.fetchAtelierMeteo();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: const Offset(0.0, -0.05),
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _meteoFuture = OpenMeteoService.instance.fetchAtelierMeteo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      child: SafeArea(
        child: FutureBuilder<AtelierMeteoData>(
          future: _meteoFuture,
          builder: (context, snapshot) {
            // Drag handle top
            final dragHandle = Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dragHandle,
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.cyan),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Connexion satellite météo en cours...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Analyse de l\'humidité sur le campus',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            }

            final meteo = snapshot.data ??
                AtelierMeteoData(
                  temperature: 19.5,
                  humidite: 78,
                  ventVitesse: 14.0,
                  codeMeteo: 61,
                  description: 'Pluie Légère',
                  icone: Icons.grain_rounded,
                  couleur: const Color(0xFF3B82F6),
                  augmentationSechagePercent: 45,
                  recommandationProduction: 'Forte humidité détectée.',
                );

            final isHighDemand = meteo.augmentationSechagePercent >= 30;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragHandle,
                const SizedBox(height: 18),

                // Top Header Row with Refresh and Close
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: meteo.couleur.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: meteo.couleur.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.satellite_alt_rounded, size: 13, color: meteo.couleur),
                          const SizedBox(width: 5),
                          Text(
                            'API Open-Meteo Satellite • Tunis',
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
                    IconButton(
                      tooltip: 'Actualiser météo',
                      onPressed: _refresh,
                      icon: Icon(Icons.refresh_rounded, size: 20, color: meteo.couleur),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Animated Weather Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        meteo.couleur.withValues(alpha: 0.18),
                        meteo.couleur.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: meteo.couleur.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      // Floating Animated Cloud / Sun
                      SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: meteo.couleur.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(meteo.icone, color: meteo.couleur, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${meteo.temperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: meteo.couleur.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    meteo.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: meteo.couleur,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.water_drop_rounded, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  'Humidité : ${meteo.humidite}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.air_rounded, size: 14, color: AppColors.muted),
                                const SizedBox(width: 3),
                                Text(
                                  '${meteo.ventVitesse.toStringAsFixed(0)} km/h',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Decision Support Notification Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHighDemand ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isHighDemand ? Colors.orange.shade300 : Colors.green.shade300,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isHighDemand ? Colors.orange.shade600 : Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHighDemand
                                      ? 'Alerte Demande Casiers : +${meteo.augmentationSechagePercent}%'
                                      : 'Demande Casiers Optimale',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isHighDemand ? Colors.orange.shade900 : Colors.green.shade900,
                                  ),
                                ),
                                Text(
                                  'Impact en temps réel sur l\'atelier de lavage',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isHighDemand ? Colors.orange.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        meteo.recommandationProduction,
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighDemand ? Colors.brown.shade900 : Colors.green.shade900,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      'Compris, optimiser l\'atelier',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
