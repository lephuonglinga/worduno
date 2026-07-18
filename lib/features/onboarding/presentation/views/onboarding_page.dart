import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/feature_signatures.dart';
import '../../../../core/utils/activity_prefs.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _index = 0;

  static final _slides = [
    (
      color: FeatureSignatures.learnBg,
      ink: FeatureSignatures.learnInk,
      icon: FeatureSignatures.learnIcon,
      title: 'Học từ vựng theo Flashcard',
      body: 'Lật thẻ, nghe phát âm chuẩn và ghi nhớ từ mới mỗi ngày.',
    ),
    (
      color: FeatureSignatures.examBg,
      ink: FeatureSignatures.examInk,
      icon: FeatureSignatures.examIcon,
      title: 'Kiểm tra đa dạng dạng câu hỏi',
      body: 'Từ trắc nghiệm, nối từ đến câu hỏi do AI tự sinh ra.',
    ),
    (
      color: FeatureSignatures.coachBg,
      ink: FeatureSignatures.coachInk,
      icon: FeatureSignatures.coachIcon,
      title: 'Luyện viết cùng AI Coach',
      body: 'Viết câu, nhận phản hồi tức thì về ngữ pháp và cách dùng từ.',
    ),
  ];

  Future<void> _finish() async {
    await ActivityPrefs.setSeenOnboarding();
    widget.onFinished();
  }

  void _next() {
    if (_index < _slides.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: slide.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(58),
                    topRight: Radius.circular(78),
                    bottomLeft: Radius.circular(72),
                    bottomRight: Radius.circular(52),
                  ),
                ),
                child: Icon(slide.icon, size: 48, color: slide.ink),
              ),
              const SizedBox(height: 28),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final on = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: on ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: on ? AppColors.lavenderInk : AppColors.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Bỏ qua'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _index == _slides.length - 1 ? 'Bắt đầu' : 'Tiếp tục',
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
