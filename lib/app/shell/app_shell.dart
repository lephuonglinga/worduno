import 'package:flutter/material.dart';

import '../routes/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/feature_signatures.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.body,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _TabItem(
                  icon: Icons.home_outlined,
                  label: 'Trang chủ',
                  selected: currentTab == AppTab.home,
                  onTap: () => onTabSelected(AppTab.home),
                ),
                _TabItem(
                  icon: FeatureSignatures.learnIcon,
                  label: 'Học tập',
                  selected: currentTab == AppTab.study,
                  onTap: () => onTabSelected(AppTab.study),
                ),
                _TabItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Thống kê',
                  selected: currentTab == AppTab.dashboard,
                  onTap: () => onTabSelected(AppTab.dashboard),
                ),
                _TabItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Hồ sơ',
                  selected: currentTab == AppTab.profile,
                  onTap: () => onTabSelected(AppTab.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? AppColors.lavender : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
