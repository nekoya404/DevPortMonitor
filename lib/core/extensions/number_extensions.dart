/// Number extension methods
extension IntExtensions on int {
  /// Format bytes to human readable string
  String formatBytes({int decimals = 1}) {
    if (this <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var i = 0;
    double size = toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    if (i == 0) {
      return '${size.toInt()} ${suffixes[i]}';
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format number with thousand separators
  String formatWithCommas() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Format as port number display
  String formatPort() {
    return ':$this';
  }
}

extension DoubleExtensions on double {
  /// Format bytes to human readable string
  String formatBytes({int decimals = 1}) {
    return toInt().formatBytes(decimals: decimals);
  }

  /// Format as percentage
  String formatPercent({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Format as rate (per second)
  String formatRate({String suffix = '/s', int decimals = 1}) {
    return '${toInt().formatBytes(decimals: decimals)}$suffix';
  }
}
