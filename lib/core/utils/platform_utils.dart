import 'dart:io';

/// Platform-specific utility functions
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on macOS
  static bool get isMacOS => Platform.isMacOS;

  /// Check if running on Windows
  static bool get isWindows => Platform.isWindows;

  /// Check if running on Linux
  static bool get isLinux => Platform.isLinux;

  /// Check if running on desktop
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Get the platform name
  static String get platformName {
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Get the command to list ports based on platform
  static String get listPortsCommand {
    if (isMacOS || isLinux) {
      return 'lsof -iTCP -sTCP:LISTEN -n -P';
    } else if (isWindows) {
      return 'netstat -ano -p tcp';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the command to kill a process by PID
  static String getKillCommand(int pid, {bool force = false}) {
    if (isMacOS || isLinux) {
      return force ? 'kill -9 $pid' : 'kill $pid';
    } else if (isWindows) {
      return force ? 'taskkill /F /PID $pid' : 'taskkill /PID $pid';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the command to get process details by PID
  static String getProcessDetailsCommand(int pid) {
    if (isMacOS) {
      return 'ps -p $pid -o pid,ppid,user,%cpu,%mem,command';
    } else if (isLinux) {
      return 'ps -p $pid -o pid,ppid,user,%cpu,%mem,cmd';
    } else if (isWindows) {
      return 'wmic process where ProcessId=$pid get ProcessId,ParentProcessId,Name,CommandLine /format:csv';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get the shell for running commands
  static String get shell {
    if (isMacOS || isLinux) {
      return '/bin/bash';
    } else if (isWindows) {
      return 'cmd.exe';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get shell arguments for running a command
  static List<String> getShellArgs(String command) {
    if (isMacOS || isLinux) {
      return ['-c', command];
    } else if (isWindows) {
      return ['/c', command];
    }
    throw UnsupportedError('Unsupported platform');
  }
}
