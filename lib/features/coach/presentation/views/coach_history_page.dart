import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/feature_signatures.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../domain/entities/coach_entities.dart';
import '../viewmodels/coach_history_view_model.dart';

class CoachHistoryPage extends StatefulWidget {
  const CoachHistoryPage({super.key});

  @override
  State<CoachHistoryPage> createState() => _CoachHistoryPageState();
}

class _CoachHistoryPageState extends State<CoachHistoryPage> {
  late final CoachHistoryViewModel _viewModel;
  AppNavigationNotifier? _navigationNotifier;

  @override
  void initState() {
    super.initState();
    _viewModel = CoachHistoryViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadTerms();
      _navigationNotifier = context.read<AppNavigationNotifier>();
      _navigationNotifier!.addListener(_onNavigationChanged);
    });
  }

  void _onNavigationChanged() {
    final config = _navigationNotifier?.configuration;
    if (config == null) return;
    if (config.tab == AppTab.profile &&
        config.profileSection == ProfileSection.coachHistory &&
        config.coachStack.length == 1) {
      _viewModel.loadTerms();
    }
  }

  @override
  void dispose() {
    _navigationNotifier?.removeListener(_onNavigationChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachHistoryViewModel>.value(
      value: _viewModel,
      child: Consumer<CoachHistoryViewModel>(
        builder: (context, vm, _) {
          final showFab = !vm.isLoading &&
              vm.errorMessage == null &&
              vm.terms.isNotEmpty;

          return Scaffold(
            backgroundColor: AppColors.cream,
            appBar: WordunoAppBar(
              title: 'Lịch sử AI Coach',
              onBack: () =>
                  context.read<AppNavigationNotifier>().popProfileToHub(),
            ),
            floatingActionButton: showFab
                ? FloatingActionButton.extended(
                    onPressed: () {
                      context
                          .read<AppNavigationNotifier>()
                          .startCoachFromHistory();
                    },
                    backgroundColor: FeatureSignatures.coachBg,
                    foregroundColor: FeatureSignatures.coachInk,
                    icon: const Icon(FeatureSignatures.coachIcon),
                    label: const Text(
                      'Bắt đầu Coach',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
            body: _buildBody(context, vm),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CoachHistoryViewModel vm) {
    if (vm.isLoading) {
      return const AppLoading(message: 'Loading history...');
    }
    if (vm.errorMessage != null) {
      return AppErrorView(
        message: vm.errorMessage!,
        onRetry: vm.loadTerms,
      );
    }
    if (vm.terms.isEmpty) {
      return _EmptyHistory(
        onStart: () {
          context.read<AppNavigationNotifier>().startCoachFromHistory();
        },
      );
    }
    return RefreshIndicator(
      onRefresh: vm.loadTerms,
      color: FeatureSignatures.coachInk,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
        itemCount: vm.terms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final term = vm.terms[index];
          return _TermCard(
            term: term,
            onTap: () {
              context.read<AppNavigationNotifier>().openCoachTermDetail(
                    unitId: term.unitId,
                    termId: term.termId,
                  );
            },
            onDelete: () => _confirmDeleteTerm(context, vm, term),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTerm(
    BuildContext context,
    CoachHistoryViewModel vm,
    CoachHistoryTerm term,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all feedback?'),
        content: Text(
          'Remove all coaching feedback for "${term.word}"? Explanation will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteAllFeedbacks(term);
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FeatureSignatures.coachBg,
                borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
              ),
              child: const Icon(
                FeatureSignatures.coachIcon,
                size: 36,
                color: FeatureSignatures.coachInk,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có lịch sử AI Coach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các từ đã luyện sẽ hiện ở đây theo Level và Unit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(FeatureSignatures.coachIcon),
                label: const Text(
                  'Bắt đầu Coach',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: FeatureSignatures.coachBg,
                  foregroundColor: FeatureSignatures.coachInk,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusBtn),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.onTap,
    required this.onDelete,
  });

  final CoachHistoryTerm term;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.word,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${term.levelCode.toUpperCase()} · ${term.unitName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FeatureSignatures.coachInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      term.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CoachHistoryViewModel.formatDateTime(term.lastCoachedAt)} · ${term.feedbackCount} feedback',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.light,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.light,
                onPressed: onDelete,
                tooltip: 'Delete all feedback',
              ),
              const Icon(Icons.chevron_right, color: AppColors.light),
            ],
          ),
        ),
      ),
    );
  }
}
