import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/residents_mock_data.dart';
import '../widgets/resident_info_card.dart';

class ResidentProfilePage extends StatelessWidget {
  const ResidentProfilePage({
    super.key,
    required this.resident,
    required this.onEditProfile,
  });

  final ResidentProfile resident;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    resident.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                resident.fullName,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            ResidentInfoCard(
              icon: Icons.person_outline_rounded,
              label: 'First name',
              value: resident.firstName,
            ),
            ResidentInfoCard(
              icon: Icons.person_outline_rounded,
              label: 'Last name',
              value: resident.lastName,
            ),
            ResidentInfoCard(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: resident.email,
            ),
            ResidentInfoCard(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: resident.phone,
            ),
            ResidentInfoCard(
              icon: Icons.home_outlined,
              label: 'Residence',
              value: resident.residenceName,
            ),
            ResidentInfoCard(
              icon: Icons.apartment_outlined,
              label: 'Apartment',
              value: resident.apartmentNumber,
            ),
            ResidentInfoCard(
              icon: Icons.stairs_outlined,
              label: 'Floor',
              value: resident.floor,
            ),
            ResidentInfoCard(
              icon: Icons.badge_outlined,
              label: 'Status',
              value: resident.status,
              color: AppColors.cyan,
            ),
          ],
        ),
      ],
    );
  }
}
