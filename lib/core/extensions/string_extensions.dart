/// String extension methods
extension StringExtensions on String {
  /// Capitalize the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert string to title case
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string contains any of the patterns
  bool containsAny(List<String> patterns) {
    final lowerCase = toLowerCase();
    return patterns.any((pattern) => lowerCase.contains(pattern.toLowerCase()));
  }

  /// Check if string matches any of the patterns exactly
  bool matchesAny(List<String> patterns) {
    final lowerCase = toLowerCase();
    return patterns.any((pattern) => lowerCase == pattern.toLowerCase());
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Extract process name from full command
  String extractProcessName() {
    // Get the last component of the path
    final parts = split('/');
    final name = parts.isNotEmpty ? parts.last : this;
    
    // Remove common extensions
    return name
        .replaceAll(RegExp(r'\.exe$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.app$', caseSensitive: false), '')
        .trim();
  }

  /// Check if this looks like a dev process
  bool isDevProcess(List<String> patterns) {
    final processName = extractProcessName().toLowerCase();
    return patterns.any((pattern) {
      final p = pattern.toLowerCase();
      return processName == p ||
          processName.startsWith('$p ') ||
          processName.startsWith('$p-') ||
          processName.startsWith('$p.') ||
          processName.contains('/$p') ||
          processName.endsWith(p);
    });
  }
}
