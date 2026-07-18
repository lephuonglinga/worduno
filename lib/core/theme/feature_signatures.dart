import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Canonical Learn / Exam / Coach visual signature used across Home and the rest of the app.
abstract final class FeatureSignatures {
  // Học từ vựng
  static const learnBg = AppColors.mint;
  static const learnInk = AppColors.mintInk;
  static const learnIcon = Icons.menu_book_outlined;

  // Kiểm tra
  static const examBg = AppColors.peach;
  static const examInk = AppColors.peachInk;
  static const examIcon = Icons.track_changes_outlined;

  // AI Coach
  static const coachBg = AppColors.pink;
  static const coachInk = AppColors.pinkInk;
  static const coachIcon = Icons.chat_bubble_outline_rounded;
}
