import 'package:flutter/material.dart';
import '../../../core/navigation/app_back_button.dart';

import '../../../core/localization/localized_text.dart';
import '../../../core/localization/app_locale.dart';

import '../../auth/presentation/widgets/sign_out_button.dart';

import '../../../core/localization/language_picker_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.userName, this.userRole});

  final String? userName;
  final String? userRole;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => confirmSignOut(context)),
        title: const LocalizedText('ResiDry'),
        centerTitle: false,
        actions: const [LanguagePickerButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SignOutButton(),
            LocalizedText(
              userName == null ? 'Welcome home' : 'Welcome, $userName',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              userRole == null
                  ? 'Manage your laundry lockers in one place.'
                  : '${context.localize(userRole!)} account · Manage your laundry lockers here.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_laundry_service_outlined,
                      size: 32,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    LocalizedText(
                      'Your lockers',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LocalizedText(
                      'Your locker information will appear here.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
