import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../models/laundry_item.dart';
import '../../data/repositories/laundry_repository.dart';
import 'laundry_design.dart';

/// Small shared state helper: keep database futures out of build().
mixin LaundryAsyncState<T extends StatefulWidget> on State<T> {
  List<LaundryItem> items = [];
  bool loading = true;
  bool busy = false;
  String? loadError;
  int _loadGeneration = 0;

  Future<List<LaundryItem>> fetchItems();

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final result = await fetchItems();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        items = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        loading = false;
        loadError = 'Impossible de charger les demandes.';
      });
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) message('Modification enregistrée.');
    } on LaundryException catch (error) {
      if (mounted) message(error.message);
    } catch (_) {
      if (mounted) message('Impossible d’enregistrer. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await reload();
      }
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.localize(text)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget requestBody(Widget child) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              context.tr(
                fr: 'Chargement des demandes…',
                en: 'Loading requests…',
                ar: 'جارٍ تحميل الطلبات…',
              ),
            ),
          ],
        ),
      );
    }
    if (loadError != null) {
      return Center(
        child: SingleChildScrollView(
          child: LaundryEmptyState(
            title: context.localize(loadError!),
            description: context.tr(
              fr: 'Le chargement a échoué. Vous pouvez réessayer.',
              en: 'Loading failed. You can try again.',
              ar: 'تعذّر التحميل. يمكنك إعادة المحاولة.',
            ),
            icon: Icons.error_outline_rounded,
            action: FilledButton.icon(
              onPressed: reload,
              icon: const Icon(Icons.refresh),
              label: Text(context.localize('Réessayer')),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        if (busy) const LinearProgressIndicator(),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: IconButton(
            tooltip: context.localize('Actualiser'),
            onPressed: busy ? null : reload,
            icon: const Icon(Icons.refresh),
          ),
        ),
        Expanded(
          child: AbsorbPointer(absorbing: busy, child: child),
        ),
      ],
    );
  }
}
