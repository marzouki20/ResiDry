import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/residents_mock_data.dart';
import '../../../../models/residence.dart';
import '../../data/residence_locator.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.resident,
    required this.onSave,
  });

  final ResidentProfile resident;
  final ValueChanged<ResidentProfile> onSave;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _residenceController;
  late final TextEditingController _apartmentController;
  Residence? _detectedResidence;
  bool _isDetectingResidence = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.resident.firstName,
    );
    _lastNameController = TextEditingController(text: widget.resident.lastName);
    _emailController = TextEditingController(text: widget.resident.email);
    _phoneController = TextEditingController(text: widget.resident.phone);
    _residenceController = TextEditingController(
      text: widget.resident.residenceName,
    );
    _apartmentController = TextEditingController(
      text: widget.resident.apartmentNumber,
    );
    _detectResidence();
  }

  Future<void> _detectResidence() async {
    if (!mounted) return;
    setState(() => _isDetectingResidence = true);
    Residence? residence;
    try {
      residence = await ResidenceLocator.detectNearest();
    } catch (_) {
      residence = null;
    }
    if (!mounted) return;
    setState(() {
      _detectedResidence = residence;
      _isDetectingResidence = false;
      if (residence != null) {
        _residenceController.text = residence.name;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _residenceController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _buildField(
                controller: _firstNameController,
                label: 'First name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _lastNameController,
                label: 'Last name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email.';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _residenceController,
                readOnly: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Residence not detected.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Residence détectée par GPS',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _isDetectingResidence
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Détecter la résidence',
                          onPressed: _detectResidence,
                          icon: const Icon(Icons.my_location_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (_detectedResidence != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Résidence trouvée à proximité (${_detectedResidence!.radius.toInt()} m).',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildField(
                controller: _apartmentController,
                label: 'Apartment',
                icon: Icons.apartment_outlined,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your apartment.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon, color: AppColors.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE45858), width: 1.2),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedResident = widget.resident.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        residenceName: _residenceController.text.trim(),
        residenceAddress:
            _detectedResidence?.address ?? widget.resident.residenceAddress,
        city: _detectedResidence?.city ?? widget.resident.city,
        apartmentNumber: _apartmentController.text.trim(),
      );
      widget.onSave(updatedResident);
      Navigator.of(context).pop(updatedResident);
    }
  }
}
