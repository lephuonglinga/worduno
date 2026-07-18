import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/tts/presentation/speak_term.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../viewmodels/learn_session_view_model.dart';

class LearnSessionPage extends StatefulWidget {
  const LearnSessionPage({
    super.key,
    required this.levelCode,
    required this.unitName,
    this.unitId,
    this.initialTermId,
  });

  final String levelCode;
  final String unitName;
  final String? unitId;
  final String? initialTermId;

  @override
  State<LearnSessionPage> createState() => _LearnSessionPageState();
}

class _LearnSessionPageState extends State<LearnSessionPage> {
  late final LearnSessionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LearnSessionViewModel(
      levelCode: widget.levelCode,
      unitName: widget.unitName,
      unitId: widget.unitId,
      initialTermId: widget.initialTermId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadSession();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LearnSessionViewModel>.value(
      value: _viewModel,
      child: const _LearnSessionView(),
    );
  }
}

class _LearnSessionView extends StatefulWidget {
  const _LearnSessionView();

  @override
  State<_LearnSessionView> createState() => _LearnSessionViewState();
}

class _LearnSessionViewState extends State<_LearnSessionView> {
  String? _markAnim;
  double _dragDx = 0;

  Future<void> _speak(String text) => speakTermWithFeedback(context, text);

  Future<void> _markWithAnim(
    LearnSessionViewModel vm,
    Future<void> Function() action,
    String direction,
  ) async {
    if (_markAnim != null) return;
    setState(() => _markAnim = direction);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    await action();
    if (!mounted) return;
    setState(() => _markAnim = null);
  }

  String _statusKey(WordStatus status) => switch (status) {
        WordStatus.know => 'learned',
        WordStatus.learning => 'learning',
        WordStatus.newWord => 'new',
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LearnSessionViewModel>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: WordunoAppBar(
        title: 'Đang học',
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đang học',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              vm.unitName,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: vm.isLoading
          ? const AppLoading(message: 'Đang tải...')
          : vm.errorMessage != null
              ? AppErrorView(
                  message: vm.errorMessage!,
                  onRetry: vm.loadSession,
                )
              : vm.isEmptySession
                  ? _buildEmptyScreen(context)
                  : vm.isCompleted
                      ? _buildCompletionScreen(context)
                      : _buildSessionScreen(context, vm),
    );
  }

  Widget _buildCompletionScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
                boxShadow: AppDecorations.shadowMd,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.mintInk,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Hoàn thành!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn đã học xong unit này. Quay lại danh sách từ để xem tiến độ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            _ScaleButton(
              onTap: () => AppBackButton.handleDefaultBack(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
                ),
                child: const Center(
                  child: Text(
                    'Về danh sách từ',
                    style: TextStyle(
                      color: AppColors.lavenderInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Không có từ để học.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            _ScaleButton(
              onTap: () => AppBackButton.handleDefaultBack(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusBtn),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                    color: AppColors.lavenderInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionScreen(BuildContext context, LearnSessionViewModel vm) {
    final currentTerm = vm.currentTerm;
    if (currentTerm == null) {
      return const Center(
        child: Text(
          'Không có từ để học.',
          style: TextStyle(color: AppColors.inkSoft),
        ),
      );
    }

    final isStarred = vm.currentStarred;
    final softPal = AppColors.wordStatusSoft(_statusKey(vm.currentStatus));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Còn lại ${vm.remainingCards} thẻ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
            child: LinearProgressIndicator(
              value: vm.progress,
              minHeight: 9,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.mintInk,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Flashcard
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _markAnim == null ? vm.flipCard : null,
              onHorizontalDragStart: (_) => _dragDx = 0,
              onHorizontalDragUpdate: (details) {
                _dragDx += details.delta.dx;
              },
              onHorizontalDragEnd: (details) {
                if (_markAnim != null) return;
                final velocity = details.primaryVelocity ?? 0;
                if (_dragDx <= -64 || velocity < -200) {
                  _markWithAnim(vm, vm.markKnow, 'know');
                } else if (_dragDx >= 64 || velocity > 200) {
                  _markWithAnim(vm, vm.markLearning, 'learning');
                }
                _dragDx = 0;
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: vm.isFlipped ? math.pi : 0,
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  final isBack = val >= math.pi / 2;
                  final slideX = _markAnim == 'know'
                      ? 55.0
                      : _markAnim == 'learning'
                          ? -55.0
                          : 0.0;
                  final opacity = _markAnim == null ? 1.0 : 0.15;

                  return Opacity(
                    opacity: opacity,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(val)
                        ..translate(slideX, 0.0),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildCardBack(currentTerm, softPal),
                            )
                          : _buildCardFront(currentTerm),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Learning / Know actions (preview)
          Row(
            children: [
              Expanded(
                child: _ScaleButton(
                  onTap: () =>
                      _markWithAnim(vm, vm.markLearning, 'learning'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusBtn),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.peachInk,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đang học',
                          style: TextStyle(
                            color: AppColors.peachInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScaleButton(
                  onTap: () => _markWithAnim(vm, vm.markKnow, 'know'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius:
                          BorderRadius.circular(AppDecorations.radiusBtn),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.mintInk,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đã thuộc',
                          style: TextStyle(
                            color: AppColors.mintInk,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Toolbar: undo · shuffle · star · speaker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ToolbarBtn(
                icon: Icons.undo_rounded,
                enabled: vm.canUndo,
                onTap: vm.canUndo ? vm.undo : null,
              ),
              const SizedBox(width: 10),
              _ToolbarBtn(
                icon: Icons.shuffle_rounded,
                onTap: vm.shuffle,
              ),
              const SizedBox(width: 10),
              _ToolbarBtn(
                icon: isStarred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                ink: isStarred ? AppColors.sunInk : AppColors.ink,
                onTap: vm.toggleStarCurrent,
              ),
              const SizedBox(width: 10),
              _ToolbarBtn(
                icon: Icons.volume_up_outlined,
                onTap: () => _speak(currentTerm.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(Term currentTerm) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 14),
            Text(
              currentTerm.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chạm để lật',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(Term currentTerm, WordStatusPalette softPal) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: softPal.bg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NGHĨA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: softPal.fg.withValues(alpha: 0.65),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              currentTerm.definition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chạm để xem từ',
              style: TextStyle(
                fontSize: 13,
                color: softPal.fg.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.ink,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (ink ?? AppColors.ink)
        : AppColors.inkSoft.withValues(alpha: 0.35);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  const _ScaleButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
