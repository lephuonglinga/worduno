import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/navigation/app_navigation_notifier.dart';
import '../theme/app_colors.dart';

/// Consistent back control wired to [AppNavigationNotifier].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  static void handleDefaultBack(BuildContext context) {
    context.read<AppNavigationNotifier>().popActive();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed ?? () => handleDefaultBack(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 22,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class WordunoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WordunoAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.centerTitle = true,
    this.titleStyle,
  });

  final String title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  static const _defaultTitleStyle = TextStyle(
    color: AppColors.ink,
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AppBackButton(onPressed: onBack),
            )
          : null,
      leadingWidth: showBack ? 50 : null,
      title: titleWidget ??
          Text(
            title,
            style: titleStyle ?? _defaultTitleStyle,
          ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      actions: actions,
    );
  }
}

/// Lexia-branded app bar used on study browsing screens.
class LexiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LexiaAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.title = 'Học tập',
  });

  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed:
                  onBack ?? () => AppBackButton.handleDefaultBack(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const Text(
            'Chọn một Level để bắt đầu',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

/// Icon action for [LexiaAppBar].
class LexiaAppBarIconButton extends StatelessWidget {
  const LexiaAppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lavenderInk,
              ),
            )
          : Icon(icon, color: AppColors.ink),
    );
  }
}
