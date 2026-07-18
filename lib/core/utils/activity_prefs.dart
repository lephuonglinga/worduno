import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Simple prefs-backed daily learn count + streak for Home extras.
class ActivityPrefs {
  ActivityPrefs._();

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<int> dailyLearnCount() async {
    final prefs = await _prefs;
    final date = prefs.getString(AppConstants.dailyLearnDateKey);
    if (date != _todayKey()) {
      return 0;
    }
    return prefs.getInt(AppConstants.dailyLearnCountKey) ?? 0;
  }

  static Future<int> recordKnow() async {
    final prefs = await _prefs;
    final today = _todayKey();
    final date = prefs.getString(AppConstants.dailyLearnDateKey);
    var count = prefs.getInt(AppConstants.dailyLearnCountKey) ?? 0;
    if (date != today) {
      count = 0;
    }
    count += 1;
    await prefs.setString(AppConstants.dailyLearnDateKey, today);
    await prefs.setInt(AppConstants.dailyLearnCountKey, count);
    await recordActivity();
    return count;
  }

  static Future<int> streakCount() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.streakCountKey) ?? 0;
  }

  /// Call on Know / exam complete / coach feedback submit.
  static Future<int> recordActivity() async {
    final prefs = await _prefs;
    final today = _todayKey();
    final last = prefs.getString(AppConstants.lastActiveDateKey);
    var streak = prefs.getInt(AppConstants.streakCountKey) ?? 0;

    if (last == today) {
      return streak;
    }

    if (last != null) {
      final lastDate = DateTime.tryParse(last);
      final todayDate = DateTime.tryParse(today);
      if (lastDate != null && todayDate != null) {
        final gap = todayDate.difference(lastDate).inDays;
        if (gap == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await prefs.setString(AppConstants.lastActiveDateKey, today);
    await prefs.setInt(AppConstants.streakCountKey, streak);
    return streak;
  }

  static Future<bool> homeBannerDismissed() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.homeBannerDismissedKey) ?? false;
  }

  static Future<void> dismissHomeBanner() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.homeBannerDismissedKey, true);
  }

  static Future<({String? level, String? unit, String? unitId})>
      lastUnit() async {
    final prefs = await _prefs;
    return (
      level: prefs.getString(AppConstants.lastUnitLevelKey),
      unit: prefs.getString(AppConstants.lastUnitNameKey),
      unitId: prefs.getString(AppConstants.lastUnitIdKey),
    );
  }

  static Future<void> saveLastUnit({
    required String level,
    required String unit,
    required String unitId,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.lastUnitLevelKey, level);
    await prefs.setString(AppConstants.lastUnitNameKey, unit);
    await prefs.setString(AppConstants.lastUnitIdKey, unitId);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
  }
}
