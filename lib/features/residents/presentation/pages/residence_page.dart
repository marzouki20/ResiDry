import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/residents_mock_data.dart';

class ResidencePage extends StatelessWidget {
  const ResidencePage({super.key, required this.resident});

  final ResidentProfile resident;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _SectionCard(
          title: 'Residence',
          icon: Icons.home_outlined,
          items: [
            _InfoRow(label: 'Residence name', value: resident.residenceName),
            _InfoRow(label: 'Address', value: resident.residenceAddress),
            _InfoRow(label: 'City', value: resident.city),
            _InfoRow(label: 'Postal code', value: resident.postalCode),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Apartment',
          icon: Icons.apartment_outlined,
          items: [
            _InfoRow(
              label: 'Apartment number',
              value: resident.apartmentNumber,
            ),
            _InfoRow(label: 'Floor', value: resident.floor),
            _InfoRow(label: 'Apartment status', value: resident.status),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
