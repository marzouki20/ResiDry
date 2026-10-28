import 'package:flutter/material.dart';

import '../../../../models/laundry_item.dart';
import '../../data/repositories/laundry_repository.dart';
import 'laundry_history_sheet.dart';

Future<void> showLaundryHistory(
  BuildContext context,
  LaundryRepository repository,
  LaundryItem item, {
  int? residentId,
}) {
  // Create the future once, before the dialog builder runs.
  final history = repository.getDetails(item.id);
  return showDialog<void>(
    context: context,
    builder: (_) => LaundryHistorySheet(details: history),
  );
}
