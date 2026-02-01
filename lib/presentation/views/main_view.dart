import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodels/process_monitor_viewmodel.dart';
import '../widgets/process_list_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/status_bar_widget.dart';
import '../widgets/header_widget.dart';

/// Main view of the application
class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(processMonitorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom title bar / header
          const HeaderWidget(),

          // Toolbar with search and actions
          const ToolbarWidget(),

          // Divider
          Container(
            height: 1,
            color: AppColors.divider,
          ),

          // Main content - Process list
          Expanded(
            child: state.isLoading && state.processes.isEmpty
                ? const _LoadingWidget()
                : state.hasError && state.processes.isEmpty
                    ? _ErrorWidget(error: state.error!)
                    : const ProcessListWidget(),
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.divider,
          ),

          // Status bar
          const StatusBarWidget(),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning ports...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading processes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton.icon(
                onPressed: () {
                  ref.read(processMonitorProvider.notifier).loadProcesses();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              );
            },
          ),
        ],
      ),
    );
  }
}
