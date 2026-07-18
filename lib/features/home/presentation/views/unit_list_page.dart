import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../viewmodels/unit_list_view_model.dart';

enum _SortMode { original, az, za }

class UnitListPage extends StatefulWidget {
  const UnitListPage({super.key, required this.levelCode});

  final String levelCode;

  @override
  State<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends State<UnitListPage> {
  late final UnitListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UnitListViewModel(levelCode: widget.levelCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadUnits();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UnitListViewModel>.value(
      value: _viewModel,
      child: const _UnitListView(),
    );
  }
}

class _UnitListView extends StatefulWidget {
  const _UnitListView();

  @override
  State<_UnitListView> createState() => _UnitListViewState();
}

class _UnitListViewState extends State<_UnitListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sort = _SortMode.original;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _levelSubtitle(String code) {
    final c = code.toLowerCase();
    if (c.contains('a1')) return 'Sơ cấp';
    if (c.contains('a2')) return 'Cơ bản';
    if (c.contains('b1')) return 'Trung cấp';
    if (c.contains('b2')) return 'Trung cấp cao';
    if (c.contains('c')) return 'Nâng cao';
    return '';
  }

  List<_IndexedUnit> _processUnits(List<Unit> units) {
    final indexed = units
        .asMap()
        .entries
        .map((e) => _IndexedUnit(index: e.key, unit: e.value))
        .where((u) => u.unit.name.toLowerCase().contains(_searchQuery))
        .toList();

    switch (_sort) {
      case _SortMode.original:
        return indexed;
      case _SortMode.az:
        return indexed..sort((a, b) => a.unit.name.compareTo(b.unit.name));
      case _SortMode.za:
        return indexed..sort((a, b) => b.unit.name.compareTo(a.unit.name));
    }
  }

  String _sortLabel(_SortMode mode) => switch (mode) {
        _SortMode.original => 'Thứ tự gốc',
        _SortMode.az => 'A–Z',
        _SortMode.za => 'Z–A',
      };

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<_SortMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortSheet(
        current: _sort,
        options: const [
          (_SortMode.original, 'Thứ tự gốc', Icons.format_list_numbered_outlined),
          (_SortMode.az, 'A–Z', Icons.sort_by_alpha_outlined),
          (_SortMode.za, 'Z–A', Icons.sort_by_alpha_outlined),
        ],
      ),
    );
    if (selected != null && mounted) {
      setState(() => _sort = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UnitListViewModel>();
    final levelCode = vm.levelCode;
    final subtitle = _levelSubtitle(levelCode);
    final totalTerms = vm.units.fold(0, (s, u) => s + u.totalTerms);
    final knownTerms = vm.units.fold(0, (s, u) => s + u.knownTerms);
    final processedUnits = _processUnits(vm.units);
    final overallPct = totalTerms == 0
        ? 0
        : ((knownTerms / totalTerms) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: WordunoAppBar(
        title: levelCode.toUpperCase(),
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle.isNotEmpty
                  ? '${levelCode.toUpperCase()} · $subtitle'
                  : levelCode.toUpperCase(),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              '${vm.units.length} unit · $overallPct% đã thuộc · $totalTerms từ',
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _SearchBar(
                controller: _searchController,
                hint: 'Tìm unit...',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _SortChipBtn(
                  label: 'Sắp xếp',
                  activeLabel:
                      _sort == _SortMode.original ? null : _sortLabel(_sort),
                  highlighted: _sort != _SortMode.original,
                  onTap: _openSortSheet,
                ),
              ),
            ),
          ),
          if (vm.isLoading)
            const SliverFillRemaining(
              child: AppLoading(message: 'Đang tải unit...'),
            )
          else if (vm.errorMessage != null)
            SliverFillRemaining(
              child: AppErrorView(
                message: vm.errorMessage!,
                onRetry: vm.loadUnits,
              ),
            )
          else if (processedUnits.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Không tìm thấy unit.',
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = processedUnits[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UnitCard(
                        unit: item.unit,
                        colorIndex: item.index,
                        onTap: () {
                          context.read<AppNavigationNotifier>().openStudyRoute(
                                HomeRoutePaths.termList,
                                params: {
                                  'level': vm.levelCode,
                                  'unit': item.unit.name,
                                  'unitId': item.unit.id,
                                },
                              );
                        },
                      ),
                    );
                  },
                  childCount: processedUnits.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndexedUnit {
  const _IndexedUnit({required this.index, required this.unit});
  final int index;
  final Unit unit;
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
          borderSide: const BorderSide(color: AppColors.lavender, width: 1.5),
        ),
      ),
    );
  }
}

class _SortChipBtn extends StatelessWidget {
  const _SortChipBtn({
    required this.label,
    required this.onTap,
    this.activeLabel,
    this.highlighted = false,
  });

  final String label;
  final String? activeLabel;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = highlighted || activeLabel != null;
    return Material(
      color: isActive ? AppColors.lavender : AppColors.card,
      borderRadius: BorderRadius.circular(AppDecorations.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDecorations.radiusChip),
            border: Border.all(
              color: isActive ? AppColors.lavender : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 16,
                color: isActive ? AppColors.lavenderInk : AppColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.lavenderInk : AppColors.inkSoft,
                ),
              ),
              if (activeLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· $activeLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.lavenderInk : AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({
    required this.current,
    required this.options,
  });

  final _SortMode current;
  final List<(_SortMode, String, IconData)> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sắp xếp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              for (final opt in options) ...[
                Material(
                  color: opt.$1 == current
                      ? AppColors.lavender
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, opt.$1),
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusBtn),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusBtn),
                        border: Border.all(
                          color: opt.$1 == current
                              ? AppColors.lavender
                              : AppColors.line,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opt.$3,
                            size: 20,
                            color: opt.$1 == current
                                ? AppColors.lavenderInk
                                : AppColors.inkSoft,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.$2,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: opt.$1 == current
                                    ? AppColors.lavenderInk
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                          if (opt.$1 == current)
                            const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.lavenderInk,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Display-only title: strip leading "Unit N" / "Unit N ·" if present in the name.
String _displayUnitName(String name) {
  final cleaned = name
      .replaceFirst(
        RegExp(r'^unit\s*\d+\s*[·•:\-–—]?\s*', caseSensitive: false),
        '',
      )
      .trim();
  return cleaned.isEmpty ? name : cleaned;
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.colorIndex,
    required this.onTap,
  });

  final Unit unit;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.unitPalette(colorIndex);
    final pct = (unit.progress * 100).round();
    final title = _displayUnitName(unit.name);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
            boxShadow: AppDecorations.shadowMd,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: pal.bg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  color: pal.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${unit.totalTerms} từ · $pct%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusPill),
                      child: LinearProgressIndicator(
                        value: unit.progress,
                        minHeight: 7,
                        backgroundColor: AppColors.line,
                        valueColor: AlwaysStoppedAnimation<Color>(pal.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
