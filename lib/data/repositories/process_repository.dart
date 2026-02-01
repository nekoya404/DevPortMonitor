import '../models/port_process.dart';
import '../models/kill_result.dart';
import '../services/process_service.dart';

/// Repository for managing process data
class ProcessRepository {
  final ProcessService _processService;

  ProcessRepository({ProcessService? processService})
      : _processService = processService ?? ProcessService();

  /// Fetch all listening dev processes
  Future<List<PortProcess>> fetchProcesses({
    int minPort = 3000,
    int maxPort = 9000,
    bool devProcessesOnly = true,
  }) async {
    return _processService.getListeningProcesses(
      minPort: minPort,
      maxPort: maxPort,
      devProcessesOnly: devProcessesOnly,
    );
  }

  /// Kill a single process
  Future<KillResult> killProcess(PortProcess process, {bool force = false}) {
    return _processService.killProcess(process, force: force);
  }

  /// Kill multiple processes
  Future<BulkKillResult> killProcesses(
    List<PortProcess> processes, {
    bool force = false,
  }) {
    return _processService.killProcesses(processes, force: force);
  }

  /// Kill all processes on a port
  Future<BulkKillResult> killPort(
    int port,
    List<PortProcess> allProcesses, {
    bool force = false,
  }) {
    return _processService.killPort(port, allProcesses, force: force);
  }

  /// Check if a process is running
  Future<bool> isProcessRunning(int pid) {
    return _processService.isProcessRunning(pid);
  }
}
