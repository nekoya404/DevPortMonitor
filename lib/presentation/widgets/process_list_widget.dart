import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/process_group.dart';
import '../viewmodels/process_monitor_viewmodel.dart';
import 'process_item_widget.dart';

/// Widget displaying the list of processes grouped by category
class ProcessListWidget extends ConsumerWidget {
  const ProcessListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(processMonitorProvider);
    // Use state.groups directly to properly track expansion state
    final groups = state.groups;

    if (groups.isEmpty) {
      return _EmptyState(
        searchQuery: state.filter.searchQuery,
        onClearFilter: () {
          ref.read(processMonitorProvider.notifier).clearFilters();
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _ProcessGroupWidget(group: group);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onClearFilter;

  const _EmptyState({
    required this.searchQuery,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.check_circle_outline,
            color: hasSearch ? AppColors.textTertiary : AppColors.success,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No processes match your search'
                : 'No dev processes running',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'All clear! No development servers detected.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          if (hasSearch) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onClearFilter,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProcessGroupWidget extends ConsumerWidget {
  final ProcessGroup group;

  const _ProcessGroupWidget({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(processMonitorProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        _GroupHeader(
          group: group,
          onToggle: () => viewModel.toggleGroupExpansion(group.category),
        ),

        // Process items
        if (group.isExpanded)
          ...group.processes.map(
            (process) => ProcessItemWidget(
              process: process,
              key: ValueKey(process.uniqueId),
            ),
          ),
      ],
    );
  }
}

class _GroupHeader extends StatefulWidget {
  final ProcessGroup group;
  final VoidCallback onToggle;

  const _GroupHeader({
    required this.group,
    required this.onToggle,
  });

  @override
  State<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<_GroupHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.getCategoryColor(widget.group.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.rowHover : AppColors.headerBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Expand/collapse icon
              AnimatedRotation(
                turns: widget.group.isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),

              // Category indicator
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Category icon
              _getCategoryIcon(widget.group.category, categoryColor),
              const SizedBox(width: 10),

              // Category name
              Text(
                widget.group.category,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Process count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.group.count} ${widget.group.count == 1 ? 'process' : 'processes'}',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Ports badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.group.portCount} ${widget.group.portCount == 1 ? 'port' : 'ports'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category, Color color) {
    IconData icon;
    switch (category) {
      case 'JavaScript/Node':
        icon = Icons.javascript;
        break;
      case 'Python':
        icon = Icons.code;
        break;
      case 'Ruby':
        icon = Icons.diamond_outlined;
        break;
      case 'Java/JVM':
        icon = Icons.coffee;
        break;
      case 'PHP':
        icon = Icons.php;
        break;
      case 'Go':
        icon = Icons.speed;
        break;
      case 'Rust':
        icon = Icons.settings;
        break;
      case '.NET':
        icon = Icons.window;
        break;
      case 'Build Tools':
        icon = Icons.build;
        break;
      case 'Frameworks':
        icon = Icons.layers;
        break;
      case 'Database':
        icon = Icons.storage;
        break;
      case 'DevOps':
        icon = Icons.cloud;
        break;
      case 'Desktop/Mobile':
        icon = Icons.devices;
        break;
      case 'Testing':
        icon = Icons.bug_report;
        break;
      case 'Cloud/BaaS':
        icon = Icons.cloud_queue;
        break;
      case 'AI/ML':
        icon = Icons.psychology;
        break;
      case 'MCP/Tools':
        icon = Icons.extension;
        break;
      default:
        icon = Icons.terminal;
    }

    return Icon(icon, size: 18, color: color);
  }
}
