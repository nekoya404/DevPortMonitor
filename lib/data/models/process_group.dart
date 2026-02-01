import 'package:equatable/equatable.dart';
import 'port_process.dart';

/// Represents a group of processes in the same category
class ProcessGroup extends Equatable {
  final String category;
  final List<PortProcess> processes;
  final bool isExpanded;

  const ProcessGroup({
    required this.category,
    required this.processes,
    this.isExpanded = true,
  });

  /// Total number of processes in this group
  int get count => processes.length;

  /// Total number of unique ports used by processes in this group
  int get portCount => processes.map((p) => p.port).toSet().length;

  /// List of all ports used by this group
  List<int> get ports => processes.map((p) => p.port).toSet().toList()..sort();

  /// Create a copy with updated fields
  ProcessGroup copyWith({
    String? category,
    List<PortProcess>? processes,
    bool? isExpanded,
  }) {
    return ProcessGroup(
      category: category ?? this.category,
      processes: processes ?? this.processes,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [category, processes, isExpanded];

  @override
  String toString() {
    return 'ProcessGroup(category: $category, count: $count)';
  }
}
