import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../viewmodels/process_monitor_viewmodel.dart';

/// Status bar widget showing summary information
class StatusBarWidget extends ConsumerWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(processMonitorProvider);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.headerBackground,
      child: Row(
        children: [
          // Process count
          Flexible(
            child: _StatusItem(
              icon: Icons.memory,
              text: '${state.filteredProcessCount}',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Port range
          Flexible(
            child: _StatusItem(
              icon: Icons.electrical_services,
              text: '${AppConstants.minPort}-${AppConstants.maxPort}',
              color: AppColors.textTertiary,
            ),
          ),

          const Spacer(),

          // Auto-refresh indicator
          if (state.autoRefreshEnabled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Auto: 10s',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Refreshing indicator
          if (state.isRefreshing)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            )
          else if (state.lastUpdated != null)
            Text(
              _formatTime(state.lastUpdated!),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 5) {
      return 'just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
