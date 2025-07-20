import 'package:flutter/material.dart';
import '../theme.dart';

enum ButtonVariant {
  primary,      // default
  destructive,  // destructive
  outline,      // outline
  secondary,    // secondary
  ghost,        // ghost
  link,         // link
}

enum ButtonSize {
  defaultSize,  // default
  small,        // sm
  large,        // lg
  icon,         // icon
}

class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;
  final Widget? icon;

  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.defaultSize,
    this.disabled = false,
    this.icon,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  Widget build(BuildContext context) {
    final isEnabled = !disabled && onPressed != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), // transition-colors
          height: _getHeight(),
          width: size == ButtonSize.icon ? _getHeight() : null,
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isEnabled),
            border: variant == ButtonVariant.outline 
                ? Border.all(color: AppColors.border) 
                : null,
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: icon!,
                ),
                if (text != null || child != null) const SizedBox(width: 8), // gap-2
              ],
              if (text != null)
                Text(
                  text!,
                  style: TextStyle(
                    color: _getTextColor(isEnabled),
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w500, // font-medium
                    decoration: variant == ButtonVariant.link 
                        ? TextDecoration.underline 
                        : null,
                  ),
                  textAlign: TextAlign.center,
                )
              else if (child != null)
                DefaultTextStyle(
                  style: TextStyle(
                    color: _getTextColor(isEnabled),
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w500,
                  ),
                  child: child!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36.0; // h-9
      case ButtonSize.large:
        return 44.0; // h-11
      case ButtonSize.icon:
      case ButtonSize.defaultSize:
      default:
        return 40.0; // h-10
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12.0); // px-3
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32.0); // px-8
      case ButtonSize.icon:
        return EdgeInsets.zero;
      case ButtonSize.defaultSize:
      default:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0); // px-4 py-2
    }
  }

  double _getBorderRadius() {
    return size == ButtonSize.small || size == ButtonSize.large 
        ? 6.0 // rounded-md
        : 6.0; // rounded-md (기본값도 같음)
  }

  double _getFontSize() {
    return 14.0; // text-sm
  }

  Color _getBackgroundColor(bool isEnabled) {
    if (!isEnabled) {
      return Colors.grey.withOpacity(0.5);
    }

    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.destructive:
        return AppColors.destructive;
      case ButtonVariant.outline:
        return AppColors.background;
      case ButtonVariant.secondary:
        return AppColors.secondary;
      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _getTextColor(bool isEnabled) {
    if (!isEnabled) {
      return Colors.grey;
    }

    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primaryForeground;
      case ButtonVariant.destructive:
        return AppColors.destructiveForeground;
      case ButtonVariant.outline:
        return AppColors.foreground;
      case ButtonVariant.secondary:
        return AppColors.secondaryForeground;
      case ButtonVariant.ghost:
        return AppColors.foreground;
      case ButtonVariant.link:
        return AppColors.primary;
    }
  }
}

// Convenience constructors for different variants
class PrimaryButton extends AppButton {
  const PrimaryButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.primary);
}

class DestructiveButton extends AppButton {
  const DestructiveButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.destructive);
}

class OutlineButton extends AppButton {
  const OutlineButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.outline);
}

class SecondaryButton extends AppButton {
  const SecondaryButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.secondary);
}

class GhostButton extends AppButton {
  const GhostButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.ghost);
}

class LinkButton extends AppButton {
  const LinkButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.disabled,
    super.icon,
  }) : super(variant: ButtonVariant.link);
} 