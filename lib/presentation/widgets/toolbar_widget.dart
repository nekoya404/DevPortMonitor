import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../viewmodels/process_monitor_viewmodel.dart';

/// Toolbar widget with search and action buttons
class ToolbarWidget extends ConsumerStatefulWidget {
  const ToolbarWidget({super.key});

  @override
  ConsumerState<ToolbarWidget> createState() => _ToolbarWidgetState();
}

class _ToolbarWidgetState extends ConsumerState<ToolbarWidget> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(processMonitorProvider);
    final viewModel = ref.read(processMonitorProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.toolbarBackground,
      child: Row(
        children: [
          // Search field
          if (_showSearch)
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.search,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search processes, ports, PID...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          viewModel.setSearchQuery(value);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        color: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setSearchQuery('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        setState(() => _showSearch = false);
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                      },
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Search button
            _ToolbarButton(
              icon: Icons.search,
              tooltip: 'Search',
              onPressed: () {
                setState(() => _showSearch = true);
              },
            ),
            const SizedBox(width: 4),

            // Refresh button
            _ToolbarButton(
              icon: Icons.refresh,
              tooltip: 'Refresh',
              isLoading: state.isRefreshing,
              onPressed: () => viewModel.refreshProcesses(),
            ),
            const SizedBox(width: 4),

            // Auto-refresh toggle
            _ToolbarButton(
              icon: state.autoRefreshEnabled
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              tooltip: state.autoRefreshEnabled
                  ? 'Pause auto-refresh'
                  : 'Enable auto-refresh',
              isActive: state.autoRefreshEnabled,
              onPressed: () => viewModel.toggleAutoRefresh(),
            ),
            
            const SizedBox(width: 8),
            
            // Divider
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            const SizedBox(width: 8),
            
            // Dev Processes Only toggle
            _DevOnlyToggle(
              isActive: state.filter.showOnlyDevProcesses,
              onPressed: () => viewModel.toggleDevProcessesOnly(),
            ),

            const Spacer(),

            // Expand/Collapse buttons
            _ToolbarButton(
              icon: Icons.unfold_more,
              tooltip: 'Expand all',
              onPressed: () => viewModel.expandAllGroups(),
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.unfold_less,
              tooltip: 'Collapse all',
              onPressed: () => viewModel.collapseAllGroups(),
            ),
            const SizedBox(width: 8),

            // Divider
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            const SizedBox(width: 8),

            // Kill all button
            _KillAllButton(
              processCount: state.filteredProcessCount,
              onPressed: state.filteredProcessCount > 0
                  ? () => _showKillAllDialog(context, viewModel, state.filteredProcessCount)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showKillAllDialog(
    BuildContext context,
    ProcessMonitorViewModel viewModel,
    int count,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kill All Processes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to terminate all $count running dev processes?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kill All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await viewModel.killAllProcesses(force: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Killed ${result.successCount} of ${result.totalCount} processes',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
    this.isActive = false,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.elevated
                  : (widget.isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: widget.isActive
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
                  : null,
            ),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isActive
                        ? AppColors.primary
                        : (_isHovered ? AppColors.textPrimary : AppColors.textSecondary),
                  ),
          ),
        ),
      ),
    );
  }
}

class _KillAllButton extends StatefulWidget {
  final int processCount;
  final VoidCallback? onPressed;

  const _KillAllButton({
    required this.processCount,
    this.onPressed,
  });

  @override
  State<_KillAllButton> createState() => _KillAllButtonState();
}

class _KillAllButtonState extends State<_KillAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return Tooltip(
      message: 'Kill all ${widget.processCount} processes',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isEnabled
                  ? (_isHovered ? AppColors.buttonDangerHover : AppColors.buttonDanger)
                  : AppColors.buttonDisabled,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.power_settings_new,
                  size: 16,
                  color: isEnabled ? Colors.white : AppColors.textDisabled,
                ),
                const SizedBox(width: 6),
                Text(
                  'Kill All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : AppColors.textDisabled,
                  ),
                ),
                if (widget.processCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.processCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.white : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dev Only toggle button widget
class _DevOnlyToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _DevOnlyToggle({
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive ? 'Show all processes' : 'Show dev processes only',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.buttonPrimary.withValues(alpha: 0.2)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? AppColors.buttonPrimary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.code : Icons.apps,
                size: 14,
                color: isActive ? AppColors.buttonPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'Dev Only' : 'All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.buttonPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
