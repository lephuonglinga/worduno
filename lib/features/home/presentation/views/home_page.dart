import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/feature_signatures.dart';
import '../../../../core/utils/activity_prefs.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _dailyCount = 0;
  int _streak = 0;
  bool _bannerDismissed = false;
  int _bannerIndex = 0;
  List<Level> _levels = const [];
  ({String? level, String? unit, String? unitId}) _lastUnit =
      (level: null, unit: null, unitId: null);
  bool _loading = true;

  static const _banners = [
    (
      color: FeatureSignatures.learnBg,
      ink: FeatureSignatures.learnInk,
      title: 'Học flashcard mỗi ngày',
      body: 'Lật thẻ và nghe phát âm để nhớ lâu hơn.',
    ),
    (
      color: FeatureSignatures.examBg,
      ink: FeatureSignatures.examInk,
      title: 'Thử kiểm tra đa dạng',
      body: 'Trắc nghiệm, nối từ và câu hỏi AI.',
    ),
    (
      color: FeatureSignatures.coachBg,
      ink: FeatureSignatures.coachInk,
      title: 'Luyện viết với AI Coach',
      body: 'Nhận phản hồi ngữ pháp ngay lập tức.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vocab = getIt<IVocabularyService>();
      final store = getIt<WordStateStore>();
      final levels = await vocab.getLevels();

      // Light progress: known counts per level via units.
      final enriched = <Level>[];
      for (final level in levels) {
        try {
          final units = await vocab.getUnits(level.code);
          var known = 0;
          var total = level.totalTerms;
          for (final unit in units) {
            await store.ensureLoaded(unit.id);
            known += store.knownCount(unit.id);
          }
          enriched.add(
            Level(code: level.code, totalTerms: total, knownTerms: known),
          );
        } catch (_) {
          enriched.add(level);
        }
      }

      final daily = await ActivityPrefs.dailyLearnCount();
      final streak = await ActivityPrefs.streakCount();
      final banner = await ActivityPrefs.homeBannerDismissed();
      final last = await ActivityPrefs.lastUnit();

      if (!mounted) return;
      setState(() {
        _levels = enriched;
        _dailyCount = daily;
        _streak = streak;
        _bannerDismissed = banner;
        _lastUnit = last;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavigationNotifier>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'hello sweetie',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        Text(
                          'Lexia',
                          style: GoogleFonts.baloo2(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.lavender,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'L',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lavenderInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Today + streak
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      bg: AppColors.mint,
                      label: 'Hôm nay',
                      value: '$_dailyCount từ',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      bg: AppColors.sun,
                      label: 'Streak',
                      value: '$_streak ngày',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Continue learning
              if (_lastUnit.level != null &&
                  _lastUnit.unit != null &&
                  _lastUnit.unitId != null)
                _ContinueCard(
                  level: _lastUnit.level!,
                  unit: _lastUnit.unit!,
                  onContinue: () => nav.openContinueLearning(
                    levelCode: _lastUnit.level!,
                    unitName: _lastUnit.unit!,
                    unitId: _lastUnit.unitId!,
                  ),
                ),

              const SizedBox(height: 8),
              const Text(
                'Bạn muốn làm gì?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // Shortcuts
              Row(
                children: [
                  Expanded(
                    child: _ShortcutTile(
                      bg: FeatureSignatures.learnBg,
                      ink: FeatureSignatures.learnInk,
                      icon: FeatureSignatures.learnIcon,
                      label: 'Học từ vựng',
                      onTap: nav.openStudyTab,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShortcutTile(
                      bg: FeatureSignatures.examBg,
                      ink: FeatureSignatures.examInk,
                      icon: FeatureSignatures.examIcon,
                      label: 'Kiểm tra',
                      onTap: () =>
                          nav.openHomeRoute(HomeRoutePaths.examConfig),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ShortcutTile(
                bg: FeatureSignatures.coachBg,
                ink: FeatureSignatures.coachInk,
                icon: FeatureSignatures.coachIcon,
                label: 'Luyện viết cùng AI Coach',
                fullWidth: true,
                onTap: () => nav.openHomeRoute(HomeRoutePaths.coachConfig),
              ),

              // Feature banner
              if (!_bannerDismissed) ...[
                const SizedBox(height: 20),
                _FeatureBanner(
                  slide: _banners[_bannerIndex % _banners.length],
                  index: _bannerIndex,
                  count: _banners.length,
                  onClose: () async {
                    await ActivityPrefs.dismissHomeBanner();
                    if (mounted) setState(() => _bannerDismissed = true);
                  },
                  onNext: () => setState(
                    () => _bannerIndex = (_bannerIndex + 1) % _banners.length,
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cấp độ của bạn',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: nav.openStudyTab,
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Row(
                  children: [
                    for (var i = 0; i < _levels.take(3).length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _MiniLevelCard(
                          level: _levels[i],
                          color: AppColors.levelPalette(i).bg,
                          onTap: () {
                            nav.openStudyLevel(_levels[i].code);
                          },
                        ),
                      ),
                    ],
                    if (_levels.isEmpty)
                      const Expanded(
                        child: Text(
                          'Chưa có level',
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.bg,
    required this.label,
    required this.value,
    this.icon,
  });

  final Color bg;
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.sunInk),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.baloo2(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.level,
    required this.unit,
    required this.onContinue,
  });

  final String level;
  final String unit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIẾP TỤC HỌC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04 * 12,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${level.toUpperCase()} · $unit',
            style: GoogleFonts.baloo2(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tiếp tục'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.bg,
    required this.ink,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  final Color bg;
  final Color ink;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: fullWidth ? double.infinity : null,
          constraints: BoxConstraints(minHeight: fullWidth ? 82 : 105),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: fullWidth
              ? Row(
                  children: [
                    Icon(icon, size: 30, color: ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: ink),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FeatureBanner extends StatelessWidget {
  const _FeatureBanner({
    required this.slide,
    required this.index,
    required this.count,
    required this.onClose,
    required this.onNext,
  });

  final ({Color color, Color ink, String title, String body}) slide;
  final int index;
  final int count;
  final VoidCallback onClose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: slide.color,
          borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: slide.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slide.body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: slide.ink.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(count, (i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: i == index ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == index
                              ? slide.ink
                              : slide.ink.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, size: 18, color: slide.ink),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLevelCard extends StatelessWidget {
  const _MiniLevelCard({
    required this.level,
    required this.color,
    required this.onTap,
  });

  final Level level;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (level.progress * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppDecorations.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level.code.toUpperCase().split('&').first.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                valueColor: const AlwaysStoppedAnimation(AppColors.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
