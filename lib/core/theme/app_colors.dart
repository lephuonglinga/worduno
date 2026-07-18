import 'package:flutter/material.dart';

/// Lexia pastel design palette — flat semantic colors (no gradients).
abstract final class AppColors {
  // Brand / semantic blocks
  static const lavender = Color(0xFFC9BFFA);
  static const lavenderInk = Color(0xFF5B4FDB);
  static const mint = Color(0xFFB8F1D9);
  static const mintInk = Color(0xFF1F8F63);
  static const peach = Color(0xFFFFD3B0);
  static const peachInk = Color(0xFFC5670E);
  static const pink = Color(0xFFFCC9DD);
  static const pinkInk = Color(0xFFD93C82);
  static const sun = Color(0xFFFFE9A8);
  static const sunInk = Color(0xFF9A7400);

  static const cream = Color(0xFFFDF8F0);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2B2640);
  static const inkSoft = Color(0xFF79738F);
  static const line = Color(0x172B2640); // ~9% ink

  // Legacy aliases (mapped to new palette so existing screens pick up style)
  static const bg = cream;
  static const white = card;
  static const greenDark = lavenderInk;
  static const greenMid = mintInk;
  static const green = mint;
  static const coralDark = peachInk;
  static const coralMid = peachInk;
  static const coral = peach;
  static const beige = peach;
  static const beigeLight = Color(0xFFFFF0E6);
  static const blue = Color(0xFFBEE3F8);
  static const purple = pink;
  static const mid = inkSoft;
  static const light = inkSoft;
  static const border = line;
  static const surface = cream;

  static const primary = lavenderInk;
  static const onPrimary = white;
  static const secondary = peachInk;
  static const error = pinkInk;
  static const errorBg = Color(0xFFFFEEF4);
  static const errorBorder = pink;
  static const success = mintInk;
  static const successBg = mint;
  static const warning = peachInk;
  static const warningBg = peach;

  static Color withAlpha27(Color color) => color.withValues(alpha: 0.27);
  static Color withAlpha33(Color color) => color.withValues(alpha: 0.2);
  static Color withAlpha55(Color color) => color.withValues(alpha: 0.33);

  static const levelPalettes = <LevelPalette>[
    LevelPalette(bg: Color(0xFFBEE3F8), accent: Color(0xFF2B6CB0)),
    LevelPalette(bg: Color(0xFFFFC9C9), accent: Color(0xFFC53030)),
    LevelPalette(bg: Color(0xFFD9F2C4), accent: Color(0xFF2F855A)),
    LevelPalette(bg: Color(0xFFE7C1F9), accent: Color(0xFF6B46C1)),
    LevelPalette(bg: Color(0xFFFFF0A3), accent: sunInk),
    LevelPalette(bg: Color(0xFFB6ECE3), accent: mintInk),
  ];

  static const unitPalettes = <UnitPalette>[
    UnitPalette(bg: mint, accent: mintInk),
    UnitPalette(bg: peach, accent: peachInk),
    UnitPalette(bg: pink, accent: pinkInk),
    UnitPalette(bg: lavender, accent: lavenderInk),
    UnitPalette(bg: sun, accent: sunInk),
    UnitPalette(bg: Color(0xFFBEE3F8), accent: Color(0xFF2B6CB0)),
  ];

  static LevelPalette levelPalette(int index) =>
      levelPalettes[index % levelPalettes.length];

  static UnitPalette unitPalette(int index) =>
      unitPalettes[index % unitPalettes.length];

  static LevelPalette levelPaletteForCode(String code) {
    final c = code.toLowerCase();
    if (c.contains('b1')) return levelPalettes[0];
    if (c.contains('b2')) return levelPalettes[1];
    if (c.contains('c')) return levelPalettes[2];
    return levelPalettes[indexFromCode(code)];
  }

  static int indexFromCode(String code) => code.toLowerCase().hashCode.abs();

  static WordStatusPalette wordStatus(String status) {
    switch (status.toLowerCase()) {
      case 'learned':
      case 'know':
        return const WordStatusPalette(bg: mint, fg: mintInk);
      case 'learning':
        return const WordStatusPalette(bg: peach, fg: peachInk);
      default:
        return const WordStatusPalette(
          bg: Color(0xFFBEE3F8),
          fg: Color(0xFF2B6CB0),
        );
    }
  }

  /// Softer status fills (flashcard definition face, etc.) — easier on text.
  static WordStatusPalette wordStatusSoft(String status) {
    switch (status.toLowerCase()) {
      case 'learned':
      case 'know':
        return const WordStatusPalette(bg: Color(0xFFE8F8F0), fg: mintInk);
      case 'learning':
        return const WordStatusPalette(bg: Color(0xFFFFF0E4), fg: peachInk);
      default:
        // Pastel blue — readable on cream app background
        return const WordStatusPalette(bg: Color(0xFFDCEEFF), fg: Color(0xFF2B6CB0));
    }
  }

  static ScorePalette examScore(double score) {
    if (score >= 0.8) {
      return const ScorePalette(bg: mint, fg: mintInk);
    }
    if (score >= 0.6) {
      return const ScorePalette(bg: sun, fg: sunInk);
    }
    return const ScorePalette(bg: peach, fg: peachInk);
  }
}

class LevelPalette {
  const LevelPalette({required this.bg, required this.accent});

  final Color bg;
  final Color accent;
}

class UnitPalette {
  const UnitPalette({required this.bg, required this.accent});

  final Color bg;
  final Color accent;
}

class WordStatusPalette {
  const WordStatusPalette({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

class ScorePalette {
  const ScorePalette({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}
