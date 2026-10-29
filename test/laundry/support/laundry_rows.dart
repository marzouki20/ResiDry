import 'package:sqflite/sqflite.dart';
import 'package:ttttttteee/features/laundry/data/laundry_storage.dart';

/// Collects the old logical record types from the four-table schema so migration
/// snapshots can be compared. These names are not SQL tables or compatibility views.
Future<List<Map<String, Object?>>> readLaundryRows(
  DatabaseExecutor db,
  String records,
) async {
  switch (records) {
    case 'laundry_service_types':
      return LaundryStorage.services(db);
    case 'laundry_pricing_rules':
      return LaundryStorage.tariffs(db);
    case 'laundry_request_lines':
      return [
        for (final parent in await db.query('laundry_items', columns: ['id']))
          ...await LaundryStorage.lines(db, parent['id'] as String),
      ];
    case 'laundry_status_history':
      return [
        for (final parent in await db.query('laundry_items', columns: ['id']))
          ...await LaundryStorage.history(db, parent['id'] as String),
      ];
    case 'laundry_complaint_events':
      return [
        for (final parent in await db.query(
          'laundry_complaints',
          columns: ['id'],
        ))
          ...await LaundryStorage.complaintEvents(db, parent['id'] as String),
      ];
    case 'laundry_complaint_attachments':
      return [
        for (final parent in await db.query(
          'laundry_complaints',
          columns: ['id'],
        ))
          ...await LaundryStorage.photos(db, parent['id'] as String),
      ];
    default:
      return db.query(records);
  }
}
