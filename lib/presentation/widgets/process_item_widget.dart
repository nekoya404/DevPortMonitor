import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/port_process.dart';
import '../viewmodels/process_monitor_viewmodel.dart';

/// Widget displaying a single process item
class ProcessItemWidget extends ConsumerStatefulWidget {
  final PortProcess process;

  const ProcessItemWidget({
    super.key,
    required this.process,
  });

  @override
  ConsumerState<ProcessItemWidget> createState() => _ProcessItemWidgetState();
}

class _ProcessItemWidgetState extends ConsumerState<ProcessItemWidget>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isKilling = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _killProcess() async {
    if (_isKilling) return;

    setState(() => _isKilling = true);

    final viewModel = ref.read(processMonitorProvider.notifier);
    final result = await viewModel.killProcess(widget.process, force: true);

    if (result.success) {
      await _animationController.forward();
    } else {
      setState(() => _isKilling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to kill process: ${result.errorMessage}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.rowHover : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered ? AppColors.borderLight : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.statusListening,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusListening.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Process info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Name and Port
                        Row(
                          children: [
                            // Process name
                            Expanded(
                              child: Text(
                                widget.process.friendlyName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Port badge
                            _buildClickableBadge(
                              ':${widget.process.port}',
                              AppColors.primary,
                              () => _copyToClipboard(
                                widget.process.port.toString(),
                                'Port',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Bottom row: Command and metadata
                        Row(
                          children: [
                            // Command (truncated)
                            Expanded(
                              child: Tooltip(
                                message: widget.process.command.isNotEmpty
                                    ? widget.process.command
                                    : widget.process.processName,
                                child: Text(
                                  widget.process.command.isNotEmpty
                                      ? widget.process.command
                                      : widget.process.processName,
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // PID badge
                            _buildClickableBadge(
                              'PID: ${widget.process.pid}',
                              AppColors.textTertiary,
                              () => _copyToClipboard(
                                widget.process.pid.toString(),
                                'PID',
                              ),
                            ),
                            const SizedBox(width: 6),

                            // User badge
                            _buildBadge(widget.process.user, AppColors.textTertiary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Kill button
                  _KillButton(
                    isHovered: _isHovered,
                    isKilling: _isKilling,
                    onPressed: _killProcess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildClickableBadge(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _KillButton extends StatefulWidget {
  final bool isHovered;
  final bool isKilling;
  final VoidCallback onPressed;

  const _KillButton({
    required this.isHovered,
    required this.isKilling,
    required this.onPressed,
  });

  @override
  State<_KillButton> createState() => _KillButtonState();
}

class _KillButtonState extends State<_KillButton> {
  bool _isButtonHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.isHovered || widget.isKilling ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: widget.isHovered || widget.isKilling ? 1.0 : 0.8,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isButtonHovered = true),
          onExit: (_) => setState(() => _isButtonHovered = false),
          child: Tooltip(
            message: 'Kill process',
            child: GestureDetector(
              onTap: widget.isKilling ? null : widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isKilling
                      ? AppColors.buttonDisabled
                      : (_isButtonHovered
                          ? AppColors.buttonDangerHover
                          : AppColors.buttonDanger),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isButtonHovered && !widget.isKilling
                      ? [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: widget.isKilling
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
