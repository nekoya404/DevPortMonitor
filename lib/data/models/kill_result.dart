/// Result of a kill operation
class KillResult {
  final int pid;
  final int port;
  final String processName;
  final bool success;
  final String? errorMessage;

  const KillResult({
    required this.pid,
    required this.port,
    required this.processName,
    required this.success,
    this.errorMessage,
  });

  factory KillResult.success({
    required int pid,
    required int port,
    required String processName,
  }) {
    return KillResult(
      pid: pid,
      port: port,
      processName: processName,
      success: true,
    );
  }

  factory KillResult.failure({
    required int pid,
    required int port,
    required String processName,
    required String errorMessage,
  }) {
    return KillResult(
      pid: pid,
      port: port,
      processName: processName,
      success: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'Successfully killed $processName (PID: $pid, Port: $port)';
    }
    return 'Failed to kill $processName (PID: $pid, Port: $port): $errorMessage';
  }
}

/// Result of killing multiple processes
class BulkKillResult {
  final List<KillResult> results;

  const BulkKillResult({required this.results});

  int get successCount => results.where((r) => r.success).length;
  int get failureCount => results.where((r) => !r.success).length;
  int get totalCount => results.length;

  bool get allSucceeded => failureCount == 0;
  bool get allFailed => successCount == 0;

  List<KillResult> get successes => results.where((r) => r.success).toList();
  List<KillResult> get failures => results.where((r) => !r.success).toList();

  @override
  String toString() {
    return 'BulkKillResult(success: $successCount, failed: $failureCount, total: $totalCount)';
  }
}
