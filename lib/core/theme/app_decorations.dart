import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared radii and shadows from Lexia preview.
abstract final class AppDecorations {
  static const radiusChip = 12.0;
  static const radiusBtn = 14.0;
  static const radiusCard = 20.0;
  static const radiusSm = 12.0;
  static const radiusMd = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 26.0;
  static const radiusPill = 999.0;

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radiusCard),
        boxShadow: shadowMd,
      );

  static BoxDecoration pillButton(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusBtn),
        boxShadow: shadowSm,
      );

  /// Soft blob path used behind icons / avatars.
  static const blobPath =
      'M46.5,-58.6C58.9,-49.2,66.4,-33.5,68.9,-17.4C71.4,-1.3,68.9,15.2,60.6,28.4C52.4,41.7,38.4,51.7,23.2,58.3C8.1,64.9,-8.1,68.1,-23.5,64.3C-38.9,60.6,-53.5,49.9,-61.7,35.6C-69.9,21.2,-71.6,3.2,-67.6,-12.8C-63.6,-28.8,-53.9,-42.9,-41,-52C-28.1,-61.1,-14,-65.2,1.9,-68C17.9,-70.7,34.1,-68,46.5,-58.6Z';
}
