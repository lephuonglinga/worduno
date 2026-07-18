class AppConstants {
  AppConstants._();

  static const String appName = 'Lexia';

  static const List<String> levels = ['B1', 'B2', 'C1&C2'];

  static const List<int> examQuestionCounts = [10, 20, 50, 100];
  static const List<int> coachWordCounts = [5, 10];
  static const int maxCoachWordCount = 10;

  static const String flashcardDefaultFaceKey = 'flashcard_default_face';
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String homeBannerDismissedKey = 'home_banner_dismissed';
  static const String dailyLearnCountKey = 'daily_learn_count';
  static const String dailyLearnDateKey = 'daily_learn_date';
  static const String streakCountKey = 'streak_count';
  static const String lastActiveDateKey = 'last_active_date';
  static const String lastUnitLevelKey = 'last_unit_level';
  static const String lastUnitNameKey = 'last_unit_name';
  static const String lastUnitIdKey = 'last_unit_id';
}
