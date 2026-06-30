enum CoachStarFilter {
  all,
  starred,
  notStarred,
}

extension CoachStarFilterLabel on CoachStarFilter {
  String get label => switch (this) {
        CoachStarFilter.all => 'All words',
        CoachStarFilter.starred => 'Starred only',
        CoachStarFilter.notStarred => 'Not starred',
      };
}
