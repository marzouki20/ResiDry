import 'package:flutter/material.dart';

class ProgrammeLavage {
  final String id;
  final String nom;
  final String description;
  final int dureeMinutes;
  final double consommationKwh;
  final double temperatureC;
  final IconData icon;
  final Color couleur;
  final String typeRecommande;

  const ProgrammeLavage({
    required this.id,
    required this.nom,
    required this.description,
    required this.dureeMinutes,
    required this.consommationKwh,
    required this.temperatureC,
    required this.icon,
    required this.couleur,
    required this.typeRecommande,
  });

  static const List<ProgrammeLavage> catalogues = [
    ProgrammeLavage(
      id: 'eco_30',
      nom: 'Éco 30°C',
      description: 'Lavage économe basse température pour textiles quotidiens.',
      dureeMinutes: 30,
      consommationKwh: 0.8,
      temperatureC: 30.0,
      icon: Icons.eco_rounded,
      couleur: Color(0xFF10B981),
      typeRecommande: 'Quotidien & Écologique',
    ),
    ProgrammeLavage(
      id: 'coton_60',
      nom: 'Coton Intensif 60°C',
      description: 'Cycle haute température antibactérien pour draps et serviettes.',
      dureeMinutes: 50,
      consommationKwh: 1.8,
      temperatureC: 60.0,
      icon: Icons.local_laundry_service_rounded,
      couleur: Color(0xFF2563EB),
      typeRecommande: 'Linge sale & Hôtellerie',
    ),
    ProgrammeLavage(
      id: 'laine_20',
      nom: 'Laine & Délicat 20°C',
      description: 'Mouvement de tambour doux pour fibres fragiles et soies.',
      dureeMinutes: 25,
      consommationKwh: 0.5,
      temperatureC: 20.0,
      icon: Icons.spa_rounded,
      couleur: Color(0xFF8B5CF6),
      typeRecommande: 'Soie, Laine & Voiles',
    ),
    ProgrammeLavage(
      id: 'sechage_express',
      nom: 'Séchage Rapide Express',
      description: 'Turbine haute performance avec flux thermique pulsé.',
      dureeMinutes: 35,
      consommationKwh: 2.0,
      temperatureC: 75.0,
      icon: Icons.air_rounded,
      couleur: Color(0xFFF59E0B),
      typeRecommande: 'Séchage Rapide Express',
    ),
  ];
}
