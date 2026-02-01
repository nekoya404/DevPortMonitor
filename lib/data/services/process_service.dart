import 'dart:async';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/process_utils.dart';
import '../models/port_process.dart';
import '../models/kill_result.dart';

/// Service for interacting with system processes
class ProcessService {
  ProcessService();

  /// Get all processes listening on ports in the specified range
  Future<List<PortProcess>> getListeningProcesses({
    int minPort = AppConstants.minPort,
    int maxPort = AppConstants.maxPort,
    bool devProcessesOnly = true,
  }) async {
    try {
      if (PlatformUtils.isMacOS || PlatformUtils.isLinux) {
        return _getUnixProcesses(minPort, maxPort, devProcessesOnly);
      } else if (PlatformUtils.isWindows) {
        return _getWindowsProcesses(minPort, maxPort, devProcessesOnly);
      }
      throw UnsupportedError('Unsupported platform');
    } catch (e) {
      rethrow;
    }
  }

  /// Get processes on Unix-like systems (macOS, Linux)
  Future<List<PortProcess>> _getUnixProcesses(
    int minPort,
    int maxPort,
    bool devProcessesOnly,
  ) async {
    final processes = <PortProcess>[];
    final seenPidPorts = <String>{};

    try {
      // Use lsof to get listening processes
      final result = await Process.run(
        PlatformUtils.shell,
        PlatformUtils.getShellArgs(PlatformUtils.listPortsCommand),
      );

      if (result.exitCode != 0) {
        // lsof returns exit code 1 if no files found, which is OK
        if (result.exitCode != 1) {
          throw Exception('lsof failed: ${result.stderr}');
        }
      }

      final lines = (result.stdout as String).split('\n');
      
      // Debug: print raw output
      print('[ProcessService] lsof returned ${lines.length} lines');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith('COMMAND')) continue; // Header line
        
        // Debug: print each line being processed
        print('[ProcessService] Processing line: ${line.substring(0, line.length > 60 ? 60 : line.length)}...');

        try {
          final process = _parseUnixLsofLine(line, minPort, maxPort);
          if (process != null) {
            final key = '${process.pid}_${process.port}';
            if (!seenPidPorts.contains(key)) {
              seenPidPorts.add(key);
              
              // Debug: print each detected process
              print('[ProcessService] Found: ${process.processName} on port ${process.port}');

              // Filter dev processes
              if (devProcessesOnly) {
                final isDev = ProcessUtils.isDevProcess(process.processName, process.command);
                final isSys = ProcessUtils.isSystemProcess(process.processName, process.user);
                print('[ProcessService]   isDev=$isDev, isSys=$isSys');
                if (isDev && !isSys) {
                  processes.add(process);
                  print('[ProcessService]   ADDED');
                }
              } else {
                if (!ProcessUtils.isSystemProcess(process.processName, process.user)) {
                  processes.add(process);
                  print('[ProcessService]   ADDED (non-dev mode)');
                }
              }
            }
          } else {
            print('[ProcessService] _parseUnixLsofLine returned null');
          }
        } catch (e) {
          // Skip malformed lines but print error
          print('[ProcessService] Error parsing line: $e');
          continue;
        }
      }
      
      print('[ProcessService] Total processes after filtering: ${processes.length}');

      // Get additional process details
      final enriched = await _enrichProcessDetails(processes);
      print('[ProcessService] After enrichment: ${enriched.length} processes');
      return enriched;
    } catch (e) {
      rethrow;
    }
  }

  /// Clean up process name from lsof output
  /// Handles escaped characters like \x20 (space) that appear in some process names
  String _cleanProcessName(String name) {
    // Replace common escape sequences
    String cleaned = name
        .replaceAll(r'\x20', ' ')
        .replaceAll(r'\x2f', '/')
        .replaceAll(r'\x5c', r'\');
    
    // Remove any remaining escape sequences
    cleaned = cleaned.replaceAll(RegExp(r'\\x[0-9a-fA-F]{2}'), '');
    
    return cleaned.trim();
  }

  /// Parse a single line from lsof output
  PortProcess? _parseUnixLsofLine(String line, int minPort, int maxPort) {
    // lsof output format: COMMAND  PID  USER  FD  TYPE  DEVICE  SIZE/OFF  NODE  NAME
    final parts = line.split(RegExp(r'\s+'));
    
    print('[ParseLine] Line: $line');
    print('[ParseLine] Parts count: ${parts.length}');
    
    if (parts.length < 9) {
      print('[ParseLine] SKIP: not enough parts');
      return null;
    }

    // Clean up the process name (handle escaped chars like \x20)
    final rawName = parts[0];
    final processName = _cleanProcessName(rawName);
    final pid = int.tryParse(parts[1]);
    final user = parts[2];

    if (pid == null) {
      print('[ParseLine] SKIP: invalid PID');
      return null;
    }

    // Parse the port from the NAME field (last field)
    // Format: *:PORT or localhost:PORT or 127.0.0.1:PORT or (LISTEN)
    final nameField = parts.last;
    print('[ParseLine] nameField: $nameField');
    
    // Handle case where last field is "(LISTEN)" - port is in second-to-last
    String portField = nameField;
    if (nameField == '(LISTEN)' && parts.length >= 10) {
      portField = parts[parts.length - 2];
      print('[ParseLine] Using second-to-last: $portField');
    }
    
    final portMatch = RegExp(r':(\d+)').firstMatch(portField);
    if (portMatch == null) {
      print('[ParseLine] SKIP: no port match in $portField');
      return null;
    }

    final port = int.tryParse(portMatch.group(1)!);
    if (port == null) {
      print('[ParseLine] SKIP: invalid port');
      return null;
    }

    // Check port range
    if (port < minPort || port > maxPort) {
      print('[ParseLine] SKIP: port $port out of range [$minPort-$maxPort]');
      return null;
    }
    
    print('[ParseLine] SUCCESS: $processName (PID: $pid) on port $port');

    final category = ProcessUtils.getProcessCategory(processName, '');
    final friendlyName = ProcessUtils.getFriendlyName(processName, '');

    return PortProcess(
      pid: pid,
      processName: processName,
      command: '',
      port: port,
      protocol: 'TCP',
      user: user,
      status: 'LISTEN',
      category: category,
      friendlyName: friendlyName,
    );
  }

  /// Get processes on Windows
  Future<List<PortProcess>> _getWindowsProcesses(
    int minPort,
    int maxPort,
    bool devProcessesOnly,
  ) async {
    final processes = <PortProcess>[];
    final seenPidPorts = <String>{};

    try {
      // Get netstat output
      final netstatResult = await Process.run(
        'cmd.exe',
        ['/c', 'netstat -ano -p tcp'],
      );

      if (netstatResult.exitCode != 0) {
        throw Exception('netstat failed: ${netstatResult.stderr}');
      }

      final netstatLines = (netstatResult.stdout as String).split('\n');
      final pidToPort = <int, List<int>>{};

      for (final line in netstatLines) {
        if (!line.contains('LISTENING')) continue;

        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length < 5) continue;

        // Parse local address (format: 0.0.0.0:PORT or [::]:PORT)
        final localAddr = parts[1];
        final portMatch = RegExp(r':(\d+)$').firstMatch(localAddr);
        if (portMatch == null) continue;

        final port = int.tryParse(portMatch.group(1)!);
        final pid = int.tryParse(parts.last);

        if (port == null || pid == null) continue;
        if (port < minPort || port > maxPort) continue;

        pidToPort.putIfAbsent(pid, () => []).add(port);
      }

      // Get process details using tasklist
      final tasklistResult = await Process.run(
        'cmd.exe',
        ['/c', 'tasklist /FO CSV /V'],
      );

      final processInfo = <int, Map<String, String>>{};
      final tasklistLines = (tasklistResult.stdout as String).split('\n');

      for (final line in tasklistLines) {
        if (line.trim().isEmpty || line.startsWith('"Image Name"')) continue;

        final parts = line.split('","');
        if (parts.length < 2) continue;

        final name = parts[0].replaceAll('"', '');
        final pid = int.tryParse(parts[1].replaceAll('"', ''));
        final user = parts.length > 6 ? parts[6].replaceAll('"', '') : 'unknown';

        if (pid != null) {
          processInfo[pid] = {
            'name': name.replaceAll('.exe', ''),
            'user': user,
          };
        }
      }

      // Combine netstat and tasklist data
      for (final entry in pidToPort.entries) {
        final pid = entry.key;
        final ports = entry.value;
        final info = processInfo[pid];

        if (info == null) continue;

        final processName = info['name'] ?? 'Unknown';
        final user = info['user'] ?? 'unknown';

        for (final port in ports) {
          final key = '${pid}_$port';
          if (seenPidPorts.contains(key)) continue;
          seenPidPorts.add(key);

          final category = ProcessUtils.getProcessCategory(processName, '');
          final friendlyName = ProcessUtils.getFriendlyName(processName, '');

          final process = PortProcess(
            pid: pid,
            processName: processName,
            command: '',
            port: port,
            protocol: 'TCP',
            user: user,
            status: 'LISTEN',
            category: category,
            friendlyName: friendlyName,
          );

          if (devProcessesOnly) {
            if (ProcessUtils.isDevProcess(processName, '') &&
                !ProcessUtils.isSystemProcess(processName, user)) {
              processes.add(process);
            }
          } else {
            if (!ProcessUtils.isSystemProcess(processName, user)) {
              processes.add(process);
            }
          }
        }
      }

      return processes;
    } catch (e) {
      rethrow;
    }
  }

  /// Enrich process details with additional information
  Future<List<PortProcess>> _enrichProcessDetails(
    List<PortProcess> processes,
  ) async {
    final enrichedProcesses = <PortProcess>[];
    final pidToCommand = <int, String>{};

    // Batch get commands for all PIDs
    try {
      if (PlatformUtils.isMacOS || PlatformUtils.isLinux) {
        final pids = processes.map((p) => p.pid).toSet().join(',');
        if (pids.isNotEmpty) {
          final result = await Process.run(
            PlatformUtils.shell,
            PlatformUtils.getShellArgs(
              'ps -p $pids -o pid=,command= 2>/dev/null || true',
            ),
          );

          final lines = (result.stdout as String).split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;

            final match = RegExp(r'^\s*(\d+)\s+(.*)$').firstMatch(line);
            if (match != null) {
              final pid = int.tryParse(match.group(1)!);
              final command = match.group(2)?.trim() ?? '';
              if (pid != null) {
                pidToCommand[pid] = command;
              }
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors getting additional details
    }

    // Update processes with command info
    for (final process in processes) {
      final command = pidToCommand[process.pid] ?? process.command;
      final category = ProcessUtils.getProcessCategory(
        process.processName,
        command,
      );
      final friendlyName = ProcessUtils.getFriendlyName(
        process.processName,
        command,
      );

      enrichedProcesses.add(process.copyWith(
        command: command,
        category: category,
        friendlyName: friendlyName,
      ));
    }

    return enrichedProcesses;
  }

  /// Kill a process by PID
  Future<KillResult> killProcess(PortProcess process, {bool force = false}) async {
    try {
      final command = PlatformUtils.getKillCommand(process.pid, force: force);
      final result = await Process.run(
        PlatformUtils.shell,
        PlatformUtils.getShellArgs(command),
      );

      if (result.exitCode == 0) {
        return KillResult.success(
          pid: process.pid,
          port: process.port,
          processName: process.processName,
        );
      } else {
        // Try force kill if regular kill failed
        if (!force) {
          return killProcess(process, force: true);
        }

        return KillResult.failure(
          pid: process.pid,
          port: process.port,
          processName: process.processName,
          errorMessage: (result.stderr as String).trim(),
        );
      }
    } catch (e) {
      return KillResult.failure(
        pid: process.pid,
        port: process.port,
        processName: process.processName,
        errorMessage: e.toString(),
      );
    }
  }

  /// Kill multiple processes
  Future<BulkKillResult> killProcesses(
    List<PortProcess> processes, {
    bool force = false,
  }) async {
    final results = <KillResult>[];

    // Kill processes sequentially to avoid issues
    for (final process in processes) {
      final result = await killProcess(process, force: force);
      results.add(result);

      // Small delay between kills
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return BulkKillResult(results: results);
  }

  /// Kill all processes on a specific port
  Future<BulkKillResult> killPort(
    int port,
    List<PortProcess> allProcesses, {
    bool force = false,
  }) async {
    final processesOnPort = allProcesses.where((p) => p.port == port).toList();
    return killProcesses(processesOnPort, force: force);
  }

  /// Check if a process is still running
  Future<bool> isProcessRunning(int pid) async {
    try {
      if (PlatformUtils.isMacOS || PlatformUtils.isLinux) {
        final result = await Process.run(
          PlatformUtils.shell,
          PlatformUtils.getShellArgs('kill -0 $pid 2>/dev/null'),
        );
        return result.exitCode == 0;
      } else if (PlatformUtils.isWindows) {
        final result = await Process.run(
          'cmd.exe',
          ['/c', 'tasklist /FI "PID eq $pid" /NH'],
        );
        return (result.stdout as String).contains(pid.toString());
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
