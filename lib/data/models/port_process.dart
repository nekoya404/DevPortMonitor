import 'package:equatable/equatable.dart';

/// Represents a process listening on a port
class PortProcess extends Equatable {
  final int pid;
  final String processName;
  final String command;
  final int port;
  final String protocol;
  final String user;
  final String status;
  final String category;
  final String friendlyName;
  final int? parentPid;
  final double? cpuUsage;
  final double? memoryUsage;
  final int? bytesSent;
  final int? bytesReceived;
  final DateTime? startTime;

  const PortProcess({
    required this.pid,
    required this.processName,
    required this.command,
    required this.port,
    this.protocol = 'TCP',
    required this.user,
    this.status = 'LISTEN',
    required this.category,
    required this.friendlyName,
    this.parentPid,
    this.cpuUsage,
    this.memoryUsage,
    this.bytesSent,
    this.bytesReceived,
    this.startTime,
  });

  /// Create a copy with updated fields
  PortProcess copyWith({
    int? pid,
    String? processName,
    String? command,
    int? port,
    String? protocol,
    String? user,
    String? status,
    String? category,
    String? friendlyName,
    int? parentPid,
    double? cpuUsage,
    double? memoryUsage,
    int? bytesSent,
    int? bytesReceived,
    DateTime? startTime,
  }) {
    return PortProcess(
      pid: pid ?? this.pid,
      processName: processName ?? this.processName,
      command: command ?? this.command,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      user: user ?? this.user,
      status: status ?? this.status,
      category: category ?? this.category,
      friendlyName: friendlyName ?? this.friendlyName,
      parentPid: parentPid ?? this.parentPid,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      startTime: startTime ?? this.startTime,
    );
  }

  /// Create from map
  factory PortProcess.fromMap(Map<String, dynamic> map) {
    return PortProcess(
      pid: map['pid'] as int,
      processName: map['processName'] as String,
      command: map['command'] as String? ?? '',
      port: map['port'] as int,
      protocol: map['protocol'] as String? ?? 'TCP',
      user: map['user'] as String? ?? 'unknown',
      status: map['status'] as String? ?? 'LISTEN',
      category: map['category'] as String? ?? 'Other',
      friendlyName: map['friendlyName'] as String? ?? map['processName'] as String,
      parentPid: map['parentPid'] as int?,
      cpuUsage: map['cpuUsage'] as double?,
      memoryUsage: map['memoryUsage'] as double?,
      bytesSent: map['bytesSent'] as int?,
      bytesReceived: map['bytesReceived'] as int?,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'pid': pid,
      'processName': processName,
      'command': command,
      'port': port,
      'protocol': protocol,
      'user': user,
      'status': status,
      'category': category,
      'friendlyName': friendlyName,
      'parentPid': parentPid,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'bytesSent': bytesSent,
      'bytesReceived': bytesReceived,
      'startTime': startTime?.toIso8601String(),
    };
  }

  /// Get display port string
  String get displayPort => ':$port';

  /// Get unique identifier combining PID and port
  String get uniqueId => '${pid}_$port';

  /// Check if this is a known dev process
  bool get isKnownDevProcess => category != 'Other';

  @override
  List<Object?> get props => [
        pid,
        processName,
        command,
        port,
        protocol,
        user,
        status,
        category,
        friendlyName,
        parentPid,
        cpuUsage,
        memoryUsage,
        bytesSent,
        bytesReceived,
        startTime,
      ];

  @override
  String toString() {
    return 'PortProcess(pid: $pid, name: $processName, port: $port, category: $category)';
  }
}
