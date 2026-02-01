import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_colors.dart';

/// Custom header widget with window controls
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Draggable area
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(
                color: Colors.transparent,
              ),
            ),

          // Content
          Row(
            children: [
              // macOS traffic lights spacing
              if (Platform.isMacOS) const SizedBox(width: 78),

              // App icon and title
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    const Text(
                      'DevPortMonitor',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Windows controls
              if (Platform.isWindows) ...[
                _WindowButton(
                  icon: Icons.remove,
                  onPressed: () => windowManager.minimize(),
                ),
                _WindowButton(
                  icon: Icons.crop_square,
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
                _WindowButton(
                  icon: Icons.close,
                  onPressed: () => windowManager.close(),
                  isClose: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 52,
          color: _isHovered
              ? (widget.isClose ? AppColors.error : AppColors.elevated)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            color: _isHovered && widget.isClose
                ? Colors.white
                : AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
