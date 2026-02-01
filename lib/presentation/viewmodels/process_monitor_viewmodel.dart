import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/port_process.dart';
import '../../data/models/process_group.dart';
import '../../data/models/process_state.dart';
import '../../data/models/kill_result.dart';
import '../../data/repositories/process_repository.dart';
import '../providers/service_providers.dart';

/// ViewModel for managing process monitoring state
class ProcessMonitorViewModel extends StateNotifier<ProcessMonitorState> {
  final ProcessRepository _repository;
  Timer? _refreshTimer;

  ProcessMonitorViewModel(this._repository) : super(const ProcessMonitorState()) {
    // Initial load
    loadProcesses();
    // Start auto-refresh
    _startAutoRefresh();
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (state.autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: AppConstants.refreshIntervalSeconds),
        (_) => refreshProcesses(),
      );
    }
  }

  /// Stop auto-refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Toggle auto-refresh
  void toggleAutoRefresh() {
    state = state.copyWith(autoRefreshEnabled: !state.autoRefreshEnabled);
    if (state.autoRefreshEnabled) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  /// Load processes
  Future<void> loadProcesses() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('[ViewModel] Loading processes...');
      final processes = await _repository.fetchProcesses(
        minPort: AppConstants.minPort,
        maxPort: AppConstants.maxPort,
        devProcessesOnly: state.filter.showOnlyDevProcesses,
      );
      
      print('[ViewModel] Received ${processes.length} processes');
      final groups = _groupProcesses(processes);
      print('[ViewModel] Created ${groups.length} groups');

      state = state.copyWith(
        processes: processes,
        groups: groups,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      print('[ViewModel] State updated: ${state.processes.length} processes, ${state.groups.length} groups');
    } catch (e) {
      print('[ViewModel] Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load processes: ${e.toString()}',
      );
    }
  }

  /// Refresh processes (background refresh)
  Future<void> refreshProcesses() async {
    if (state.isRefreshing || state.isLoading) return;

    state = state.copyWith(isRefreshing: true);

    try {
      final processes = await _repository.fetchProcesses(
        minPort: AppConstants.minPort,
        maxPort: AppConstants.maxPort,
        devProcessesOnly: state.filter.showOnlyDevProcesses,
      );

      state = state.copyWith(
        processes: processes,
        groups: _groupProcesses(processes),
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Failed to refresh: ${e.toString()}',
      );
    }
  }

  /// Group processes by category
  List<ProcessGroup> _groupProcesses(List<PortProcess> processes) {
    final grouped = <String, List<PortProcess>>{};

    // Apply filter first
    final filtered = state.filter.apply(processes);

    for (final process in filtered) {
      grouped.putIfAbsent(process.category, () => []).add(process);
    }

    // Maintain expansion state
    final existingExpansion = <String, bool>{};
    for (final g in state.groups) {
      existingExpansion[g.category] = g.isExpanded;
    }

    return grouped.entries.map((entry) {
      return ProcessGroup(
        category: entry.key,
        processes: entry.value,
        isExpanded: existingExpansion[entry.key] ?? true,
      );
    }).toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: query),
    );
    state = state.copyWith(groups: _groupProcesses(state.processes));
  }

  /// Update sort option
  void setSortOption(ProcessSortOption option) {
    if (state.sortOption == option) {
      // Toggle direction
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending,
      );
    } else {
      state = state.copyWith(
        sortOption: option,
        sortDirection: SortDirection.ascending,
      );
    }
  }

  /// Toggle category filter
  void toggleCategoryFilter(String category) {
    final categories = Set<String>.from(state.filter.selectedCategories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = state.copyWith(
      filter: state.filter.copyWith(selectedCategories: categories),
    );
    state = state.copyWith(groups: _groupProcesses(state.processes));
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filter: const ProcessFilter(),
    );
    state = state.copyWith(groups: _groupProcesses(state.processes));
  }

  /// Toggle dev processes only filter
  void toggleDevProcessesOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        showOnlyDevProcesses: !state.filter.showOnlyDevProcesses,
      ),
    );
    loadProcesses();
  }

  /// Toggle group expansion
  void toggleGroupExpansion(String category) {
    final groups = state.groups.map((g) {
      if (g.category == category) {
        return g.copyWith(isExpanded: !g.isExpanded);
      }
      return g;
    }).toList();
    state = state.copyWith(groups: groups);
  }

  /// Expand all groups
  void expandAllGroups() {
    final groups = state.groups.map((g) => g.copyWith(isExpanded: true)).toList();
    state = state.copyWith(groups: groups);
  }

  /// Collapse all groups
  void collapseAllGroups() {
    final groups = state.groups.map((g) => g.copyWith(isExpanded: false)).toList();
    state = state.copyWith(groups: groups);
  }

  /// Select/deselect a process
  void toggleProcessSelection(String processId) {
    final selected = Set<String>.from(state.selectedProcessIds);
    if (selected.contains(processId)) {
      selected.remove(processId);
    } else {
      selected.add(processId);
    }
    state = state.copyWith(selectedProcessIds: selected);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedProcessIds: {});
  }

  /// Select all filtered processes
  void selectAll() {
    final ids = state.filteredProcesses.map((p) => p.uniqueId).toSet();
    state = state.copyWith(selectedProcessIds: ids);
  }

  /// Kill a single process
  Future<KillResult> killProcess(PortProcess process, {bool force = false}) async {
    final result = await _repository.killProcess(process, force: force);

    if (result.success) {
      // Remove from state immediately
      final processes = state.processes
          .where((p) => p.pid != process.pid || p.port != process.port)
          .toList();
      state = state.copyWith(
        processes: processes,
        groups: _groupProcesses(processes),
      );
    }

    // Refresh after a delay to confirm
    Future.delayed(const Duration(milliseconds: 500), () {
      refreshProcesses();
    });

    return result;
  }

  /// Kill multiple selected processes
  Future<BulkKillResult> killSelectedProcesses({bool force = false}) async {
    final selectedProcesses = state.filteredProcesses
        .where((p) => state.selectedProcessIds.contains(p.uniqueId))
        .toList();

    if (selectedProcesses.isEmpty) {
      return const BulkKillResult(results: []);
    }

    final result = await _repository.killProcesses(selectedProcesses, force: force);

    // Clear selection
    clearSelection();

    // Refresh
    await refreshProcesses();

    return result;
  }

  /// Kill all filtered processes
  Future<BulkKillResult> killAllProcesses({bool force = false}) async {
    final processes = state.filteredProcesses;

    if (processes.isEmpty) {
      return const BulkKillResult(results: []);
    }

    final result = await _repository.killProcesses(processes, force: force);

    // Refresh
    await refreshProcesses();

    return result;
  }

  /// Kill all processes on a specific port
  Future<BulkKillResult> killPort(int port, {bool force = false}) async {
    final result = await _repository.killPort(port, state.processes, force: force);

    // Refresh
    await refreshProcesses();

    return result;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}

/// Provider for ProcessMonitorViewModel
final processMonitorProvider =
    StateNotifierProvider<ProcessMonitorViewModel, ProcessMonitorState>((ref) {
  final repository = ref.watch(processRepositoryProvider);
  return ProcessMonitorViewModel(repository);
});

/// Provider for filtered processes count
final filteredProcessCountProvider = Provider<int>((ref) {
  final state = ref.watch(processMonitorProvider);
  return state.filteredProcessCount;
});

/// Provider for total processes count
final totalProcessCountProvider = Provider<int>((ref) {
  final state = ref.watch(processMonitorProvider);
  return state.totalProcessCount;
});

/// Provider for grouped processes
final groupedProcessesProvider = Provider<List<ProcessGroup>>((ref) {
  final state = ref.watch(processMonitorProvider);
  return state.groupedProcesses;
});

/// Provider for available categories
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(processMonitorProvider);
  return state.processes.map((p) => p.category).toSet().toList()..sort();
});

/// Provider for selected processes
final selectedProcessesProvider = Provider<List<PortProcess>>((ref) {
  final state = ref.watch(processMonitorProvider);
  return state.filteredProcesses
      .where((p) => state.selectedProcessIds.contains(p.uniqueId))
      .toList();
});
