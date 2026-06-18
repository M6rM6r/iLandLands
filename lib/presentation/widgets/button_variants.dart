import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Button variant system inspired by shadcn/ui CVA pattern
enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  gold,
}

enum ButtonSize {
  sm,
  default,
  lg,
  icon,
}

class ButtonVariants {
  static ButtonStyle style({
    ButtonVariant variant = ButtonVariant.primary,
    ButtonSize size = ButtonSize.default,
    bool fullWidth = false,
  }) {
    return ButtonStyle(
      backgroundColor: _backgroundColor(variant),
      foregroundColor: _foregroundColor(variant),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: _borderRadius(size)),
      ),
      padding: WidgetStateProperty.all(_padding(size)),
      minimumSize: fullWidth
          ? const Size.fromWidth(double.infinity)
          : _minimumSize(size),
      elevation: WidgetStateProperty.all(0),
      overlayColor: _overlayColor(variant),
      side: _borderSide(variant),
    );
  }

  static Color _backgroundColor(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.gold;
      case ButtonVariant.secondary:
        return AppColors.cardBg;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.destructive:
        return Colors.red.shade600;
      case ButtonVariant.gold:
        return AppColors.gold;
    }
  }

  static Color _foregroundColor(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.navy;
      case ButtonVariant.secondary:
        return AppColors.textPrimary;
      case ButtonVariant.outline:
        return AppColors.textPrimary;
      case ButtonVariant.ghost:
        return AppColors.textPrimary;
      case ButtonVariant.destructive:
        return Colors.white;
      case ButtonVariant.gold:
        return AppColors.navy;
    }
  }

  static MaterialStateProperty<Color?> _overlayColor(ButtonVariant variant) {
    return MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.pressed)) {
        switch (variant) {
          case ButtonVariant.primary:
            return AppColors.gold.withValues(alpha: 0.7);
          case ButtonVariant.secondary:
            return AppColors.cardBgLight;
          case ButtonVariant.outline:
            return AppColors.cardBgLight;
          case ButtonVariant.ghost:
            return AppColors.cardBgLight;
          case ButtonVariant.destructive:
            return Colors.red.shade700;
          case ButtonVariant.gold:
            return AppColors.gold.withValues(alpha: 0.7);
        }
      }
      if (states.contains(MaterialState.hovered)) {
        switch (variant) {
          case ButtonVariant.primary:
            return AppColors.gold.withValues(alpha: 0.9);
          case ButtonVariant.secondary:
            return AppColors.cardBgLight;
          case ButtonVariant.outline:
            return AppColors.cardBgLight;
          case ButtonVariant.ghost:
            return AppColors.cardBgLight;
          case ButtonVariant.destructive:
            return Colors.red.shade500;
          case ButtonVariant.gold:
            return AppColors.gold.withValues(alpha: 0.9);
        }
      }
      return null;
    });
  }

  static MaterialStateProperty<BorderSide?> _borderSide(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.outline:
        return MaterialStateProperty.all(
          BorderSide(color: AppColors.dividerColor),
        );
      default:
        return MaterialStateProperty.all(BorderSide.none);
    }
  }

  static BorderRadius _borderRadius(ButtonSize size) {
    switch (size) {
      case ButtonSize.sm:
      case ButtonSize.icon:
        return BorderRadius.circular(8);
      case ButtonSize.default:
      case ButtonSize.lg:
        return BorderRadius.circular(12);
    }
  }

  static EdgeInsets _padding(ButtonSize size) {
    switch (size) {
      case ButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.default:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case ButtonSize.icon:
        return EdgeInsets.zero;
    }
  }

  static Size _minimumSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.sm:
        return const Size(0, 36);
      case ButtonSize.default:
        return const Size(0, 44);
      case ButtonSize.lg:
        return const Size(0, 52);
      case ButtonSize.icon:
        return const Size(44, 44);
    }
  }
}

/// Reusable button widget with variant system
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.default,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ButtonVariants.style(
        variant: variant,
        size: size,
        fullWidth: fullWidth,
      ),
      child: isLoading
          ? SizedBox(
              height: _loadingSize(size),
              width: _loadingSize(size),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                child,
              ],
            ),
    );
  }

  double _loadingSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.sm:
      case ButtonSize.icon:
        return 16;
      case ButtonSize.default:
        return 20;
      case ButtonSize.lg:
        return 24;
    }
  }
}
