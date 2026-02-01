import 'package:flutter/material.dart';

/// Application color palette (macOS Activity Monitor inspired)
class AppColors {
  AppColors._();

  // Base colors
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252526);
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color elevated = Color(0xFF333333);

  // Primary colors
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryLight = Color(0xFF409CFF);
  static const Color primaryDark = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF30D158);

  // Semantic colors
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF64D2FF);

  // Text colors
  static const Color textPrimary = Color(0xFFE5E5E5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textTertiary = Color(0xFF6E6E6E);
  static const Color textDisabled = Color(0xFF4A4A4A);

  // Border colors
  static const Color border = Color(0xFF3D3D3D);
  static const Color borderLight = Color(0xFF4A4A4A);
  static const Color divider = Color(0xFF323232);

  // Icon colors
  static const Color iconPrimary = Color(0xFFE5E5E5);
  static const Color iconSecondary = Color(0xFFA0A0A0);
  static const Color iconDisabled = Color(0xFF6E6E6E);

  // Status colors for processes
  static const Color statusRunning = Color(0xFF30D158);
  static const Color statusListening = Color(0xFF0A84FF);
  static const Color statusWaiting = Color(0xFFFFD60A);
  static const Color statusStopped = Color(0xFFFF453A);

  // Category colors
  static const Color categoryJavaScript = Color(0xFFF7DF1E);
  static const Color categoryPython = Color(0xFF3776AB);
  static const Color categoryRuby = Color(0xFFCC342D);
  static const Color categoryJava = Color(0xFFE76F00);
  static const Color categoryPhp = Color(0xFF777BB4);
  static const Color categoryGo = Color(0xFF00ADD8);
  static const Color categoryRust = Color(0xFFDEA584);
  static const Color categoryDotnet = Color(0xFF512BD4);
  static const Color categoryDocker = Color(0xFF2496ED);
  static const Color categoryDatabase = Color(0xFF336791);
  static const Color categoryAI = Color(0xFF10A37F);  // OpenAI green
  static const Color categoryMCP = Color(0xFFFF6B35);  // Orange for MCP
  static const Color categoryIDE = Color(0xFF007ACC);  // VS Code blue
  static const Color categoryComm = Color(0xFF5865F2);  // Discord blurple
  static const Color categoryOther = Color(0xFF6E6E6E);

  // Button colors
  static const Color buttonPrimary = Color(0xFF0A84FF);
  static const Color buttonDanger = Color(0xFFFF453A);
  static const Color buttonDangerHover = Color(0xFFFF6961);
  static const Color buttonDisabled = Color(0xFF3D3D3D);

  // Special colors
  static const Color chipBackground = Color(0xFF3A3A3A);
  static const Color tooltipBackground = Color(0xFF404040);
  static const Color progressTrack = Color(0xFF3D3D3D);
  static const Color scrollbarThumb = Color(0xFF4A4A4A);

  // Traffic light colors (for bytes/network)
  static const Color trafficRed = Color(0xFFFF6B6B);
  static const Color trafficBlue = Color(0xFF4DABF7);
  static const Color trafficGreen = Color(0xFF69DB7C);

  // Chart colors
  static const Color chartLine1 = Color(0xFF0A84FF);
  static const Color chartLine2 = Color(0xFFFF453A);
  static const Color chartFill1 = Color(0x330A84FF);
  static const Color chartFill2 = Color(0x33FF453A);

  // Header/Toolbar colors
  static const Color toolbarBackground = Color(0xFF323232);
  static const Color headerBackground = Color(0xFF2A2A2A);

  // Row colors (alternating)
  static const Color rowEven = Color(0xFF2D2D2D);
  static const Color rowOdd = Color(0xFF262626);
  static const Color rowHover = Color(0xFF383838);
  static const Color rowSelected = Color(0xFF0A84FF);
  static const Color rowSelectedBackground = Color(0x330A84FF);

  /// Get category color by name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'javascript/node':
      case 'javascript':
      case 'node':
        return categoryJavaScript;
      case 'python':
        return categoryPython;
      case 'ruby':
        return categoryRuby;
      case 'java/jvm':
      case 'java':
        return categoryJava;
      case 'php':
        return categoryPhp;
      case 'go':
        return categoryGo;
      case 'rust':
        return categoryRust;
      case '.net':
      case 'dotnet':
        return categoryDotnet;
      case 'devops':
      case 'docker':
        return categoryDocker;
      case 'database':
        return categoryDatabase;
      case 'ai/ml':
      case 'ai':
        return categoryAI;
      case 'mcp/tools':
      case 'mcp':
        return categoryMCP;
      case 'ide/editors':
      case 'ide':
        return categoryIDE;
      case 'communication':
        return categoryComm;
      default:
        return primary;
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return statusRunning;
      case 'listening':
        return statusListening;
      case 'waiting':
        return statusWaiting;
      case 'stopped':
        return statusStopped;
      default:
        return textSecondary;
    }
  }
}
