import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Toast variant inspired by shadcn/ui Sonner
enum ToastVariant {
  default,
  success,
  error,
  warning,
}

class ToastSystem {
  static final _overlay = OverlayEntryPortal._();

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastVariant variant = ToastVariant.default,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? action,
    String? actionLabel,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        variant: variant,
        duration: duration,
        action: action,
        actionLabel: actionLabel,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      variant: ToastVariant.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      variant: ToastVariant.error,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      variant: ToastVariant.warning,
      duration: duration,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    this.title,
    required this.variant,
    required this.duration,
    this.action,
    this.actionLabel,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final ToastVariant variant;
  final Duration duration;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: _gradient(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColor(),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: _accentColor(),
                        width: 4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_icon(), color: _accentColor(), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null) ...[
                              Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.action != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            widget.action!();
                            widget.onDismiss();
                          },
                          child: Text(
                            widget.actionLabel ?? 'Action',
                            style: TextStyle(
                              color: _accentColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                        onPressed: widget.onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _gradient() {
    switch (widget.variant) {
      case ToastVariant.success:
        return LinearGradient(
          colors: [
            Colors.green.shade900.withValues(alpha: 0.9),
            Colors.green.shade800.withValues(alpha: 0.9),
          ],
        );
      case ToastVariant.error:
        return LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.9),
            Colors.red.shade800.withValues(alpha: 0.9),
          ],
        );
      case ToastVariant.warning:
        return LinearGradient(
          colors: [
            Colors.orange.shade900.withValues(alpha: 0.9),
            Colors.orange.shade800.withValues(alpha: 0.9),
          ],
        );
      case ToastVariant.default:
        return LinearGradient(
          colors: [
            AppColors.navyDeep.withValues(alpha: 0.9),
            AppColors.navy.withValues(alpha: 0.9),
          ],
        );
    }
  }

  Color _borderColor() {
    switch (widget.variant) {
      case ToastVariant.success:
        return Colors.green.withValues(alpha: 0.3);
      case ToastVariant.error:
        return Colors.red.withValues(alpha: 0.3);
      case ToastVariant.warning:
        return Colors.orange.withValues(alpha: 0.3);
      case ToastVariant.default:
        return AppColors.dividerColor;
    }
  }

  Color _accentColor() {
    switch (widget.variant) {
      case ToastVariant.success:
        return Colors.green.shade400;
      case ToastVariant.error:
        return Colors.red.shade400;
      case ToastVariant.warning:
        return Colors.orange.shade400;
      case ToastVariant.default:
        return AppColors.gold;
    }
  }

  IconData _icon() {
    switch (widget.variant) {
      case ToastVariant.success:
        return Icons.check_circle_rounded;
      case ToastVariant.error:
        return Icons.error_rounded;
      case ToastVariant.warning:
        return Icons.warning_rounded;
      case ToastVariant.default:
        return Icons.info_rounded;
    }
  }
}

class OverlayEntryPortal {
  OverlayEntryPortal._();
}
