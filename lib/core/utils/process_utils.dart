import '../constants/app_constants.dart';

/// Utility functions for process handling
class ProcessUtils {
  ProcessUtils._();

  /// Check if a process name is a development tool
  static bool isDevProcess(String processName, String command) {
    final name = processName.toLowerCase();
    final cmd = command.toLowerCase();

    // Check against dev process patterns
    for (final pattern in AppConstants.devProcessPatterns) {
      final p = pattern.toLowerCase();
      if (name == p ||
          name.startsWith('$p ') ||
          name.startsWith('$p.') ||
          name.contains(p) ||
          cmd.contains(p)) {
        return true;
      }
    }

    return false;
  }

  /// Check if a process should be excluded (system process)
  static bool isSystemProcess(String processName, String user) {
    final name = processName.toLowerCase();

    // Check against system process exclusions
    for (final exclusion in AppConstants.systemProcessExclusions) {
      if (name == exclusion.toLowerCase() ||
          name.startsWith(exclusion.toLowerCase())) {
        return true;
      }
    }

    // Exclude root/system user processes on macOS/Linux
    if (user == 'root' || user == '_windowserver' || user.startsWith('_')) {
      // But allow some root processes that are dev-related
      if (isDevProcess(name, '')) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Get the category for a process
  static String getProcessCategory(String processName, String command) {
    final name = processName.toLowerCase();
    final cmd = command.toLowerCase();

    for (final entry in AppConstants.processCategories.entries) {
      for (final pattern in entry.value) {
        final p = pattern.toLowerCase();
        if (name == p ||
            name.contains(p) ||
            cmd.contains(p)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  /// Get a friendly display name for a process
  static String getFriendlyName(String processName, String command) {
    final name = processName.toLowerCase();
    final cmd = command.toLowerCase();

    // Node.js related
    if (name == 'node' || name.contains('node')) {
      if (cmd.contains('next')) return 'Next.js';
      if (cmd.contains('nuxt')) return 'Nuxt.js';
      if (cmd.contains('remix')) return 'Remix';
      if (cmd.contains('astro')) return 'Astro';
      if (cmd.contains('gatsby')) return 'Gatsby';
      if (cmd.contains('vite')) return 'Vite';
      if (cmd.contains('webpack')) return 'Webpack';
      if (cmd.contains('react-scripts')) return 'Create React App';
      if (cmd.contains('vue-cli')) return 'Vue CLI';
      if (cmd.contains('angular')) return 'Angular';
      if (cmd.contains('express')) return 'Express.js';
      if (cmd.contains('nest')) return 'NestJS';
      if (cmd.contains('fastify')) return 'Fastify';
      if (cmd.contains('strapi')) return 'Strapi';
      if (cmd.contains('storybook')) return 'Storybook';
      return 'Node.js';
    }

    // Python related
    if (name == 'python' || name == 'python3' || name.contains('python')) {
      if (cmd.contains('uvicorn')) return 'Uvicorn';
      if (cmd.contains('gunicorn')) return 'Gunicorn';
      if (cmd.contains('flask')) return 'Flask';
      if (cmd.contains('django')) return 'Django';
      if (cmd.contains('fastapi')) return 'FastAPI';
      if (cmd.contains('streamlit')) return 'Streamlit';
      if (cmd.contains('jupyter')) return 'Jupyter';
      if (cmd.contains('gradio')) return 'Gradio';
      return 'Python';
    }

    // Other common tools
    if (name == 'ruby' || name.contains('ruby')) {
      if (cmd.contains('rails')) return 'Rails';
      if (cmd.contains('puma')) return 'Puma';
      return 'Ruby';
    }

    if (name == 'java' || name.contains('java')) {
      if (cmd.contains('spring')) return 'Spring Boot';
      if (cmd.contains('tomcat')) return 'Tomcat';
      return 'Java';
    }

    if (name == 'php' || name.contains('php')) {
      if (cmd.contains('artisan')) return 'Laravel';
      return 'PHP';
    }

    if (name == 'go' || name.contains('go')) return 'Go';
    if (name.contains('cargo') || name.contains('rust')) return 'Rust';
    if (name.contains('dotnet')) return '.NET';
    if (name == 'deno') return 'Deno';
    if (name == 'bun') return 'Bun';
    if (name.contains('docker')) return 'Docker';
    if (name.contains('nginx')) return 'Nginx';
    if (name.contains('apache') || name == 'httpd') return 'Apache';
    if (name.contains('postgres')) return 'PostgreSQL';
    if (name.contains('mysql')) return 'MySQL';
    if (name.contains('redis')) return 'Redis';
    if (name.contains('mongo')) return 'MongoDB';

    // AI/ML tools
    if (name.contains('ollama')) return 'Ollama';
    if (name.contains('llama')) return 'LLaMA';
    if (name.contains('langchain')) return 'LangChain';
    if (name.contains('chromadb')) return 'ChromaDB';
    if (name.contains('mlflow')) return 'MLflow';
    if (name.contains('tensorboard')) return 'TensorBoard';

    // MCP tools
    if (name.contains('unity-mcp') || name.contains('unity_mcp')) return 'Unity MCP';
    if (name.contains('mcp')) return 'MCP Server';
    if (name.contains('openclaw')) return 'OpenClaw';

    // Return the original name capitalized
    return processName.isNotEmpty
        ? processName[0].toUpperCase() + processName.substring(1)
        : processName;
  }

  /// Get an icon name for a process category
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'JavaScript/Node':
        return 'javascript';
      case 'Python':
        return 'python';
      case 'Ruby':
        return 'ruby';
      case 'Java/JVM':
        return 'java';
      case 'PHP':
        return 'php';
      case 'Go':
        return 'go';
      case 'Rust':
        return 'rust';
      case '.NET':
        return 'dotnet';
      case 'Build Tools':
        return 'build';
      case 'Frameworks':
        return 'framework';
      case 'Database':
        return 'database';
      case 'DevOps':
        return 'devops';
      case 'Desktop/Mobile':
        return 'mobile';
      case 'Testing':
        return 'testing';
      case 'Cloud/BaaS':
        return 'cloud';
      case 'AI/ML':
        return 'ai';
      case 'MCP/Tools':
        return 'mcp';
      default:
        return 'code';
    }
  }
}
