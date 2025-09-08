import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final Widget buttonChild = _buildButtonChild();

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      
      case ButtonVariant.text:
      case ButtonVariant.secondary:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle _getButtonStyle() {
    final colors = _getColors();
    final sizes = _getSizes();

    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppColors.lightGrey;
        }
        return colors['background'];
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.disabled)) {
          return AppColors.mediumGrey;
        }
        return colors['foreground'];
      }),
      side: variant == ButtonVariant.outline
          ? MaterialStateProperty.all(
              BorderSide(color: colors['border'] ?? AppColors.primary))
          : null,
      padding: MaterialStateProperty.all(
        padding ?? EdgeInsets.symmetric(
          horizontal: sizes['horizontal']!,
          vertical: sizes['vertical']!,
        ),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        ),
      ),
      textStyle: MaterialStateProperty.all(
        TextStyle(
          fontSize: sizes['fontSize'],
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: MaterialStateProperty.all(
        variant == ButtonVariant.primary || variant == ButtonVariant.danger
            ? 2.0
            : 0.0,
      ),
    );
  }

  Map<String, Color?> _getColors() {
    switch (variant) {
      case ButtonVariant.primary:
        return {
          'background': backgroundColor ?? AppColors.primary,
          'foreground': foregroundColor ?? AppColors.white,
          'border': null,
        };
      
      case ButtonVariant.secondary:
        return {
          'background': backgroundColor ?? AppColors.lightGrey,
          'foreground': foregroundColor ?? AppColors.darkGrey,
          'border': null,
        };
      
      case ButtonVariant.outline:
        return {
          'background': backgroundColor ?? Colors.transparent,
          'foreground': foregroundColor ?? AppColors.primary,
          'border': AppColors.primary,
        };
      
      case ButtonVariant.text:
        return {
          'background': backgroundColor ?? Colors.transparent,
          'foreground': foregroundColor ?? AppColors.primary,
          'border': null,
        };
      
      case ButtonVariant.danger:
        return {
          'background': backgroundColor ?? AppColors.error,
          'foreground': foregroundColor ?? AppColors.white,
          'border': null,
        };
    }
  }

  Map<String, double> _getSizes() {
    switch (size) {
      case ButtonSize.small:
        return {
          'horizontal': 16.0,
          'vertical': 8.0,
          'fontSize': 14.0,
        };
      
      case ButtonSize.medium:
        return {
          'horizontal': 24.0,
          'vertical': 16.0,
          'fontSize': 16.0,
        };
      
      case ButtonSize.large:
        return {
          'horizontal': 32.0,
          'vertical': 20.0,
          'fontSize': 18.0,
        };
    }
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return SizedBox(
        height: _getSizes()['fontSize']! + 2,
        width: _getSizes()['fontSize']! + 2,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary || variant == ButtonVariant.danger
                ? AppColors.white
                : AppColors.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const CustomIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size ?? 48,
      height: size ?? 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor ?? AppColors.darkGrey,
          size: iconSize ?? 24,
        ),
        padding: padding ?? EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool isExtended;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomFloatingActionButton({
    Key? key,
    this.onPressed,
    required this.icon,
    this.label,
    this.isExtended = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? AppColors.white,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      child: Icon(icon),
    );
  }
}