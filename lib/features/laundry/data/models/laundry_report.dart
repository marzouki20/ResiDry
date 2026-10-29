import '../../../../models/laundry_status_change.dart';
import '../../domain/models/laundry_statistics.dart';
import '../../domain/models/laundry_workload.dart';
import 'laundry_details.dart';

class LaundryReport {
  LaundryReport({
    required List<LaundryWorkload> workloads,
    required this.statistics,
    required List<LaundryPriority> priorities,
    required Map<String, List<LaundryStatusChange>> history,
    required this.evaluatedAt,
    Map<String, LaundryDetails> details = const {},
  }) : workloads = List.unmodifiable(workloads),
       priorities = List.unmodifiable(priorities),
       details = Map.unmodifiable(details),
       history = Map.unmodifiable(
         history.map(
           (id, events) =>
               MapEntry(id, List<LaundryStatusChange>.unmodifiable(events)),
         ),
       );
  final List<LaundryWorkload> workloads;
  final Map<String, List<LaundryStatusChange>> history;
  final LaundryStatistics statistics;
  final List<LaundryPriority> priorities;
  final DateTime evaluatedAt;
  final Map<String, LaundryDetails> details;
}
