import '../../../../models/laundry_status_change.dart';
import '../../domain/models/laundry_statistics.dart';
import '../../domain/models/laundry_workload.dart';

class LaundryReport {
  LaundryReport({
    required List<LaundryWorkload> workloads,
    required this.statistics,
    required List<LaundryPriority> priorities,
    required Map<String, List<LaundryStatusChange>> history,
    required this.evaluatedAt,
  }) : workloads = List.unmodifiable(workloads),
       priorities = List.unmodifiable(priorities),
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
}
