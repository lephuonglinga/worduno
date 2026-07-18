enum CoachStarFilter {
  all,
  starred,
  notStarred;

  String get label => switch (this) {
        CoachStarFilter.all => 'Tất cả',
        CoachStarFilter.starred => 'Yêu thích',
        CoachStarFilter.notStarred => 'Chưa yêu thích',
      };
}
