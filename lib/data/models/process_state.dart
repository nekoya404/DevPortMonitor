import 'package:equatable/equatable.dart';
import 'port_process.dart';
import 'process_group.dart';

/// Sorting options for process list
enum ProcessSortOption {
  port,
  processName,
  pid,
  category,
  cpuUsage,
  memoryUsage,
}

/// Sort direction
enum SortDirection {
  ascending,
  descending,
}

/// Filter options for process list
class ProcessFilter extends Equatable {
  final String searchQuery;
  final Set<String> selectedCategories;
  final int? minPort;
  final int? maxPort;
  final bool showOnlyDevProcesses;

  const ProcessFilter({
    this.searchQuery = '',
    this.selectedCategories = const {},
    this.minPort,
    this.maxPort,
    this.showOnlyDevProcesses = true,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      minPort != null ||
      maxPort != null;

  /// Create a copy with updated fields
  ProcessFilter copyWith({
    String? searchQuery,
    Set<String>? selectedCategories,
    int? minPort,
    int? maxPort,
    bool? showOnlyDevProcesses,
  }) {
    return ProcessFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      minPort: minPort ?? this.minPort,
      maxPort: maxPort ?? this.maxPort,
      showOnlyDevProcesses: showOnlyDevProcesses ?? this.showOnlyDevProcesses,
    );
  }

  /// Apply filter to a list of processes
  List<PortProcess> apply(List<PortProcess> processes) {
    return processes.where((process) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesSearch = process.processName.toLowerCase().contains(query) ||
            process.friendlyName.toLowerCase().contains(query) ||
            process.command.toLowerCase().contains(query) ||
            process.port.toString().contains(query) ||
            process.pid.toString().contains(query);
        if (!matchesSearch) return false;
      }

      // Category filter
      if (selectedCategories.isNotEmpty) {
        if (!selectedCategories.contains(process.category)) return false;
      }

      // Port range filter
      if (minPort != null && process.port < minPort!) return false;
      if (maxPort != null && process.port > maxPort!) return false;

      // Dev process filter
      if (showOnlyDevProcesses && !process.isKnownDevProcess) return false;

      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [
        searchQuery,
        selectedCategories,
        minPort,
        maxPort,
        showOnlyDevProcesses,
      ];
}

/// State of the process monitor
class ProcessMonitorState extends Equatable {
  final List<PortProcess> processes;
  final List<ProcessGroup> groups;
  final ProcessFilter filter;
  final ProcessSortOption sortOption;
  final SortDirection sortDirection;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final Set<String> selectedProcessIds;
  final bool autoRefreshEnabled;

  const ProcessMonitorState({
    this.processes = const [],
    this.groups = const [],
    this.filter = const ProcessFilter(),
    this.sortOption = ProcessSortOption.port,
    this.sortDirection = SortDirection.ascending,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.selectedProcessIds = const {},
    this.autoRefreshEnabled = true,
  });

  /// Check if there's an error
  bool get hasError => error != null && error!.isNotEmpty;

  /// Total process count
  int get totalProcessCount => processes.length;

  /// Filtered process count
  int get filteredProcessCount => filteredProcesses.length;

  /// Get filtered and sorted processes
  List<PortProcess> get filteredProcesses {
    var result = filter.apply(processes);

    // Sort
    result.sort((a, b) {
      int comparison;
      switch (sortOption) {
        case ProcessSortOption.port:
          comparison = a.port.compareTo(b.port);
          break;
        case ProcessSortOption.processName:
          comparison = a.friendlyName.compareTo(b.friendlyName);
          break;
        case ProcessSortOption.pid:
          comparison = a.pid.compareTo(b.pid);
          break;
        case ProcessSortOption.category:
          comparison = a.category.compareTo(b.category);
          break;
        case ProcessSortOption.cpuUsage:
          comparison = (a.cpuUsage ?? 0).compareTo(b.cpuUsage ?? 0);
          break;
        case ProcessSortOption.memoryUsage:
          comparison = (a.memoryUsage ?? 0).compareTo(b.memoryUsage ?? 0);
          break;
      }
      return sortDirection == SortDirection.ascending ? comparison : -comparison;
    });

    return result;
  }

  /// Get processes grouped by category
  List<ProcessGroup> get groupedProcesses {
    final grouped = <String, List<PortProcess>>{};

    for (final process in filteredProcesses) {
      grouped.putIfAbsent(process.category, () => []).add(process);
    }

    // Maintain expansion state from existing groups
    final existingExpansion = {
      for (final g in groups) g.category: g.isExpanded,
    };

    return grouped.entries.map((entry) {
      return ProcessGroup(
        category: entry.key,
        processes: entry.value,
        isExpanded: existingExpansion[entry.key] ?? true,
      );
    }).toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  /// Create a copy with updated fields
  ProcessMonitorState copyWith({
    List<PortProcess>? processes,
    List<ProcessGroup>? groups,
    ProcessFilter? filter,
    ProcessSortOption? sortOption,
    SortDirection? sortDirection,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    Set<String>? selectedProcessIds,
    bool? autoRefreshEnabled,
  }) {
    return ProcessMonitorState(
      processes: processes ?? this.processes,
      groups: groups ?? this.groups,
      filter: filter ?? this.filter,
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      selectedProcessIds: selectedProcessIds ?? this.selectedProcessIds,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
    );
  }

  @override
  List<Object?> get props => [
        processes,
        groups,
        filter,
        sortOption,
        sortDirection,
        isLoading,
        isRefreshing,
        error,
        lastUpdated,
        selectedProcessIds,
        autoRefreshEnabled,
      ];
}
