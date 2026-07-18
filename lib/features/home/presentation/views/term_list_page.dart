import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/feature_signatures.dart';
import '../../../../core/utils/activity_prefs.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../core/utils/sort_utils.dart';
import '../../../../core/tts/presentation/speak_term.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../viewmodels/term_list_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum _ViewMode { list, flashcard }

enum _FilterMode { all, learned, learning, newWord, starred }

enum _FlashcardFace { term, definition }

// ─────────────────────────────────────────────────────────────────────────────
// Page entry point — owns ViewModel lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class TermListPage extends StatefulWidget {
  const TermListPage({
    super.key,
    required this.levelCode,
    required this.unitName,
    this.unitId,
  });

  final String levelCode;
  final String unitName;
  final String? unitId;

  @override
  State<TermListPage> createState() => _TermListPageState();
}

class _TermListPageState extends State<TermListPage> {
  late final TermListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TermListViewModel(
      levelCode: widget.levelCode,
      unitName: widget.unitName,
      unitId: widget.unitId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadTerms();
      final id = widget.unitId;
      if (id != null && id.isNotEmpty) {
        ActivityPrefs.saveLastUnit(
          level: widget.levelCode,
          unit: widget.unitName,
          unitId: id,
        );
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TermListViewModel>.value(
      value: _viewModel,
      child: const _TermListView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View (stateful for local UI state)
// ─────────────────────────────────────────────────────────────────────────────

class _TermListView extends StatefulWidget {
  const _TermListView();

  @override
  State<_TermListView> createState() => _TermListViewState();
}

class _TermListViewState extends State<_TermListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _ViewMode _viewMode = _ViewMode.list;
  _FilterMode _filter = _FilterMode.all;
  SortOrder _sort = SortOrder.original;
  _FlashcardFace _defaultFace = _FlashcardFace.term;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadDefaultFace();
  }

  Future<void> _loadDefaultFace() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.flashcardDefaultFaceKey);
    if (!mounted) return;
    setState(() {
      _defaultFace = raw == 'definition'
          ? _FlashcardFace.definition
          : _FlashcardFace.term;
    });
  }

  Future<void> _setDefaultFace(_FlashcardFace face) async {
    setState(() => _defaultFace = face);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.flashcardDefaultFaceKey,
      face == _FlashcardFace.definition ? 'definition' : 'term',
    );
  }

  Future<void> _speak(String text) => speakTermWithFeedback(context, text);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Term> _applyFilter(List<Term> terms, TermListViewModel vm) {
    final searched = terms
        .where((t) =>
            t.text.toLowerCase().contains(_searchQuery) ||
            t.definition.toLowerCase().contains(_searchQuery))
        .toList();

    final filtered = _filter == _FilterMode.all
        ? searched
        : searched.where((t) {
            final state = vm.getWordState(t.id);
            if (_filter == _FilterMode.starred) return state.isStarred;
            if (_filter == _FilterMode.learned) {
              return state.status == WordStatus.know;
            }
            if (_filter == _FilterMode.learning) {
              return state.status == WordStatus.learning;
            }
            if (_filter == _FilterMode.newWord) {
              return state.status == WordStatus.newWord;
            }
            return true;
          }).toList();

    return SortUtils.sortByName(
      items: filtered,
      nameSelector: (term) => term.text,
      order: _sort,
    );
  }

  String _sortLabel(SortOrder order) => switch (order) {
        SortOrder.original => 'Thứ tự gốc',
        SortOrder.aToZ => 'A–Z',
        SortOrder.zToA => 'Z–A',
      };

  String _filterLabel(_FilterMode mode) => switch (mode) {
        _FilterMode.all => 'Tất cả',
        _FilterMode.starred => 'Yêu thích',
        _FilterMode.learning => 'Đang học',
        _FilterMode.learned => 'Đã thuộc',
        _FilterMode.newWord => 'Mới',
      };

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<SortOrder>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChoiceSheet<SortOrder>(
        title: 'Sắp xếp',
        options: const [
          (SortOrder.original, 'Thứ tự gốc', Icons.format_list_numbered_outlined),
          (SortOrder.aToZ, 'A–Z', Icons.sort_by_alpha_outlined),
          (SortOrder.zToA, 'Z–A', Icons.sort_by_alpha_outlined),
        ],
        current: _sort,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<_FilterMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChoiceSheet<_FilterMode>(
        title: 'Lọc theo trạng thái',
        options: const [
          (_FilterMode.all, 'Tất cả', Icons.apps_outlined),
          (_FilterMode.newWord, 'Mới', Icons.fiber_new_rounded),
          (_FilterMode.starred, 'Yêu thích', Icons.star_outline_rounded),
          (_FilterMode.learning, 'Đang học', Icons.refresh_rounded),
          (_FilterMode.learned, 'Đã thuộc', Icons.check_circle_outline),
        ],
        current: _filter,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _filter = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TermListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: WordunoAppBar(
        title: vm.unitName,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vm.unitName,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              vm.isLoading
                  ? 'Đang tải...'
                  : '${vm.terms.length} từ · ${vm.levelCode.toUpperCase()}',
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
      body: vm.isLoading
          ? const AppLoading(message: 'Đang tải từ vựng...')
          : vm.errorMessage != null
              ? AppErrorView(
                  message: vm.errorMessage!,
                  onRetry: vm.loadTerms,
                )
              : _buildContent(vm),
    );
  }

  Widget _buildContent(TermListViewModel vm) {
    final displayTerms = _applyFilter(vm.terms, vm);
    final known = vm.terms
        .where((t) => vm.getWordState(t.id).status == WordStatus.know)
        .length;
    final pct = vm.terms.isEmpty ? 0 : ((known / vm.terms.length) * 100).round();

    return CustomScrollView(
      slivers: [
        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: _SearchBarField(
              controller: _searchController,
              hint: 'Tìm từ...',
            ),
          ),
        ),

        // Sort + Filter (preview-style) — opens modal sheets
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionChipBtn(
                  icon: Icons.sort_rounded,
                  label: 'Sắp xếp',
                  activeLabel:
                      _sort == SortOrder.original ? null : _sortLabel(_sort),
                  highlighted: _sort != SortOrder.original,
                  onTap: () => _openSortSheet(),
                ),
                const SizedBox(width: 8),
                _ActionChipBtn(
                  icon: Icons.filter_list_rounded,
                  label: 'Lọc',
                  activeLabel:
                      _filter == _FilterMode.all ? null : _filterLabel(_filter),
                  highlighted: _filter != _FilterMode.all,
                  onTap: () => _openFilterSheet(),
                ),
              ],
            ),
          ),
        ),

        // Progress mini
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Text(
              '$pct% đã thuộc · ${displayTerms.length}/${vm.terms.length} từ',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Actions: Học ngay (lavender) + Exam (peach) + Coach (pink)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                Expanded(
                  child: _PrimaryActionBtn(
                    icon: Icons.play_arrow_outlined,
                    label: 'Học ngay',
                    onTap: () {
                      context.read<AppNavigationNotifier>().openStudyRoute(
                            HomeRoutePaths.learn,
                            params: {
                              'level': vm.levelCode,
                              'unit': vm.unitName,
                              'unitId': vm.unitId,
                            },
                          );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _IconActionBtn(
                  icon: FeatureSignatures.examIcon,
                  bg: FeatureSignatures.examBg,
                  ink: FeatureSignatures.examInk,
                  onTap: () {
                    context.read<AppNavigationNotifier>().openStudyRoute(
                          HomeRoutePaths.examConfig,
                          params: {
                            'level': vm.levelCode,
                            'unit': vm.unitName,
                            'unitId': vm.unitId,
                          },
                        );
                  },
                ),
                const SizedBox(width: 10),
                _IconActionBtn(
                  icon: FeatureSignatures.coachIcon,
                  bg: FeatureSignatures.coachBg,
                  ink: FeatureSignatures.coachInk,
                  onTap: () {
                    context.read<AppNavigationNotifier>().openStudyRoute(
                          HomeRoutePaths.coachConfig,
                          params: {
                            'level': vm.levelCode,
                            'unit': vm.unitName,
                            'unitId': vm.unitId,
                          },
                        );
                  },
                ),
              ],
            ),
          ),
        ),

        // List / Flashcard toggle — below action buttons (preview)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: _ViewToggle(
              current: _viewMode,
              onChanged: (m) => setState(() => _viewMode = m),
            ),
          ),
        ),

        if (_viewMode == _ViewMode.flashcard)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  const Text(
                    'Mặt mặc định:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip2(
                    label: 'Từ',
                    selected: _defaultFace == _FlashcardFace.term,
                    onTap: () => _setDefaultFace(_FlashcardFace.term),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip2(
                    label: 'Nghĩa',
                    selected: _defaultFace == _FlashcardFace.definition,
                    onTap: () => _setDefaultFace(_FlashcardFace.definition),
                  ),
                ],
              ),
            ),
          ),

        // Content
        if (_viewMode == _ViewMode.list)
          displayTerms.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Không tìm thấy từ.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final term = displayTerms[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TermCard(
                            term: term,
                            state: vm.getWordState(term.id),
                            onSpeak: () => _speak(term.text),
                            onStarTapped: () => vm.toggleStar(term.id),
                            onKnowTapped: () =>
                                vm.updateStatus(term.id, WordStatus.know),
                            onLearningTapped: () => vm.updateStatus(
                              term.id,
                              WordStatus.learning,
                            ),
                          ),
                        );
                      },
                      childCount: displayTerms.length,
                    ),
                  ),
                )
        else
          displayTerms.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Không tìm thấy từ.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final term = displayTerms[i];
                        return _FlashcardListItem(
                          key: ValueKey(
                            'fc-${term.id}-${_defaultFace.name}',
                          ),
                          term: term,
                          state: vm.getWordState(term.id),
                          startOnDefinition:
                              _defaultFace == _FlashcardFace.definition,
                          onSpeak: () => _speak(term.text),
                          onStarTapped: () => vm.toggleStar(term.id),
                          onKnowTapped: () =>
                              vm.updateStatus(term.id, WordStatus.know),
                          onLearningTapped: () =>
                              vm.updateStatus(term.id, WordStatus.learning),
                        );
                      },
                      childCount: displayTerms.length,
                    ),
                  ),
                ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBarField extends StatelessWidget {
  const _SearchBarField({required this.controller, required this.hint});

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

class _ActionChipBtn extends StatelessWidget {
  const _ActionChipBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeLabel,
    this.highlighted = false,
  });

  final IconData icon;
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
                icon,
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

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<(T, String, IconData)> options;
  final T current;

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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              for (final opt in options) ...[
                _ChoiceRow(
                  icon: opt.$3,
                  label: opt.$2,
                  selected: opt.$1 == current,
                  onTap: () => Navigator.pop(context, opt.$1),
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

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
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
    return Material(
      color: selected ? AppColors.lavender : AppColors.card,
      borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
            border: Border.all(
              color: selected ? AppColors.lavender : AppColors.line,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.lavenderInk : AppColors.ink,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppColors.lavenderInk,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionBtn extends StatelessWidget {
  const _PrimaryActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lavender,
      borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.lavenderInk, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.lavenderInk,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  const _IconActionBtn({
    required this.icon,
    required this.bg,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: ink, size: 22),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.current, required this.onChanged});

  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _ToggleOption(
            icon: Icons.list_alt_outlined,
            label: 'List',
            selected: current == _ViewMode.list,
            onTap: () => onChanged(_ViewMode.list),
          ),
          _ToggleOption(
            icon: Icons.style_outlined,
            label: 'Flashcard',
            selected: current == _ViewMode.flashcard,
            onTap: () => onChanged(_ViewMode.flashcard),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.lavender : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDecorations.radiusChip),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip2 extends StatelessWidget {
  const _FilterChip2({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : AppColors.card,
          borderRadius: BorderRadius.circular(AppDecorations.radiusChip),
          border: Border.all(
            color: selected ? AppColors.lavender : AppColors.line,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.lavenderInk : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Term card (List view)
// ─────────────────────────────────────────────────────────────────────────────

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.state,
    required this.onSpeak,
    required this.onStarTapped,
    required this.onKnowTapped,
    required this.onLearningTapped,
  });

  final Term term;
  final UserWordState state;
  final VoidCallback onSpeak;
  final VoidCallback onStarTapped;
  final VoidCallback onKnowTapped;
  final VoidCallback onLearningTapped;

  String get _statusKey {
    return switch (state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  String get _statusLabel {
    return switch (state.status) {
      WordStatus.know => 'Đã thuộc',
      WordStatus.learning => 'Đang học',
      WordStatus.newWord => 'Mới',
    };
  }

  bool get _isLearned => state.status == WordStatus.know;
  bool get _isLearning => state.status == WordStatus.learning;

  @override
  Widget build(BuildContext context) {
    final statusPal = AppColors.wordStatus(_statusKey);
    final sl = _statusLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: term + status badge | icons ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      term.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusPal.bg,
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusPill),
                      ),
                      child: Text(
                        sl,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusPal.fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.volume_up_outlined,
                          size: 16, color: AppColors.ink),
                      padding: EdgeInsets.zero,
                      onPressed: onSpeak,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onStarTapped,
                    child: Icon(
                      state.isStarred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 20,
                      color: state.isStarred
                          ? AppColors.sunInk
                          : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            term.definition,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mid,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onKnowTapped,
                  child: _TermBtn(
                    icon: Icons.check_rounded,
                    label: 'Đã thuộc',
                    filled: _isLearned,
                    fillColor: AppColors.mintInk,
                    unfilledBg: AppColors.mint,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onLearningTapped,
                  child: _TermBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Đang học',
                    filled: _isLearning,
                    fillColor: AppColors.peachInk,
                    unfilledBg: AppColors.peach,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermBtn extends StatelessWidget {
  const _TermBtn({
    required this.icon,
    required this.label,
    required this.filled,
    required this.fillColor,
    this.unfilledBg,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color fillColor;
  final Color? unfilledBg;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? fillColor : (unfilledBg ?? fillColor.withValues(alpha: 0.15));
    final fg = filled ? AppColors.card : fillColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flashcard list item
// ─────────────────────────────────────────────────────────────────────────────

class _FlashcardListItem extends StatefulWidget {
  const _FlashcardListItem({
    super.key,
    required this.term,
    required this.state,
    required this.startOnDefinition,
    required this.onSpeak,
    required this.onStarTapped,
    required this.onKnowTapped,
    required this.onLearningTapped,
  });

  final Term term;
  final UserWordState state;
  final bool startOnDefinition;
  final VoidCallback onSpeak;
  final VoidCallback onStarTapped;
  final VoidCallback onKnowTapped;
  final VoidCallback onLearningTapped;

  @override
  State<_FlashcardListItem> createState() => _FlashcardListItemState();
}

class _FlashcardListItemState extends State<_FlashcardListItem> {
  late bool _isFlipped;

  @override
  void initState() {
    super.initState();
    _isFlipped = widget.startOnDefinition;
  }

  String get _statusKey {
    return switch (widget.state.status) {
      WordStatus.know => 'learned',
      WordStatus.learning => 'learning',
      WordStatus.newWord => 'new',
    };
  }

  String get _statusLabel {
    return switch (widget.state.status) {
      WordStatus.know => 'Đã thuộc',
      WordStatus.learning => 'Đang học',
      WordStatus.newWord => 'Mới',
    };
  }

  bool get _isLearned => widget.state.status == WordStatus.know;
  bool get _isLearning => widget.state.status == WordStatus.learning;

  void _toggleFlip() => setState(() => _isFlipped = !_isFlipped);

  @override
  Widget build(BuildContext context) {
    final statusPal = AppColors.wordStatus(_statusKey);
    final softPal = AppColors.wordStatusSoft(_statusKey);
    final sl = _statusLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleFlip,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: _isFlipped ? math.pi : 0,
                ),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeInOut,
                builder: (context, angle, child) {
                  final showBack = angle >= math.pi / 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildCardBack(statusPalSoft: softPal),
                          )
                        : _buildCardFront(statusPal, sl),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
              boxShadow: AppDecorations.shadowSm,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onSpeak,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onKnowTapped,
                    child: _TermBtn(
                      icon: Icons.check_rounded,
                      label: 'Đã thuộc',
                      filled: _isLearned,
                      fillColor: AppColors.mintInk,
                      unfilledBg: AppColors.mint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onLearningTapped,
                    child: _TermBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Đang học',
                      filled: _isLearning,
                      fillColor: AppColors.peachInk,
                      unfilledBg: AppColors.peach,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(WordStatusPalette statusPal, String statusLabel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onStarTapped,
              child: Icon(
                widget.state.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 22,
                color: widget.state.isStarred
                    ? AppColors.sunInk
                    : AppColors.inkSoft,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TỪ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink.withValues(alpha: 0.4),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.term.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusPal.bg,
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusPill),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusPal.fg,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chạm để lật',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.ink.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack({required WordStatusPalette statusPalSoft}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: statusPalSoft.bg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onStarTapped,
              child: Icon(
                widget.state.isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 22,
                color: widget.state.isStarred
                    ? AppColors.sunInk
                    : AppColors.inkSoft,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NGHĨA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusPalSoft.fg.withValues(alpha: 0.65),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.term.definition,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
