import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../viewmodels/level_list_view_model.dart';

class LevelListPage extends StatefulWidget {
  const LevelListPage({super.key});

  @override
  State<LevelListPage> createState() => _LevelListPageState();
}

class _LevelListPageState extends State<LevelListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelListViewModel>().loadLevels();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LevelListViewModel>();

    final filtered = viewModel.levels
        .where((l) => l.code.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: LexiaAppBar(
        actions: [
          LexiaAppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: viewModel.reloadProgress ?? 'Tải lại từ vựng',
            isLoading: viewModel.isReloading,
            onPressed: viewModel.reloadLevels,
          ),
        ],
      ),
      body: _buildBody(context, viewModel, filtered),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LevelListViewModel viewModel,
    List<Level> filtered,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: _SearchBar(
              controller: _searchController,
              hint: 'Tìm level...',
            ),
          ),
        ),

        if (viewModel.isReloading && viewModel.reloadProgress != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: AppDecorations.card(),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lavenderInk,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viewModel.reloadProgress!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (viewModel.errorMessage != null && viewModel.levels.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: AppErrorBanner(message: viewModel.errorMessage!),
            ),
          ),

        if (viewModel.isLoading && viewModel.levels.isEmpty)
          const SliverFillRemaining(
            child: AppLoading(message: 'Đang tải level...'),
          )
        else if (viewModel.errorMessage != null && viewModel.levels.isEmpty)
          SliverFillRemaining(
            child: AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadLevels,
            ),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'Không tìm thấy level.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final level = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LevelCard(
                      level: level,
                      colorIndex: index,
                      onTap: () {
                        context.read<AppNavigationNotifier>().openStudyRoute(
                              HomeRoutePaths.unitList,
                              params: {'level': level.code},
                            );
                      },
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.inkSoft, size: 20),
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
          borderSide:
              const BorderSide(color: AppColors.lavender, width: 1.5),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.colorIndex,
    required this.onTap,
  });

  final Level level;
  final int colorIndex;
  final VoidCallback onTap;

  String _subtitle(String code) {
    final c = code.toLowerCase();
    if (c.contains('a1')) return 'Sơ cấp';
    if (c.contains('a2')) return 'Cơ bản';
    if (c.contains('b1')) return 'Trung cấp';
    if (c.contains('b2')) return 'Trung cấp cao';
    if (c.contains('c')) return 'Nâng cao';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.levelPalette(colorIndex);
    final pct = (level.progress * 100).round();
    final left = level.totalTerms - level.knownTerms;
    final subtitle = _subtitle(level.code);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.bg,
          borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
          boxShadow: AppDecorations.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level.code.toUpperCase().replaceAll('&', ' & '),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                '$subtitle · ${level.totalTerms} từ · $pct% đã thuộc',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.75),
                ),
              )
            else
              Text(
                '${level.totalTerms} từ · $pct% đã thuộc',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.75),
                ),
              ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.ink.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${level.knownTerms} đã thuộc · $left còn lại',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
