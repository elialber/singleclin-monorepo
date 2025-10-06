import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.flexibleSpace,
    this.bottom,
    this.systemOverlayStyle,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final SystemUiOverlayStyle? systemOverlayStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      elevation: elevation ?? 0,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.light,
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }
    return null;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

class SliverCustomAppBar extends StatelessWidget {
  const SliverCustomAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.expandedHeight = 200.0,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions,
      flexibleSpace:
          flexibleSpace ??
          FlexibleSpaceBar(
            title: Text(
              title,
              style: TextStyle(
                color: foregroundColor ?? AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor ?? AppColors.primary,
                    (backgroundColor ?? AppColors.primary).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }
    return null;
  }
}
