import '../models/dashboard_data.dart';
import 'i_dashboard_service.dart';

class DashboardServiceImpl implements IDashboardService {
  @override
  Future<DashboardData> getDashboardData() async {
    // Return dummy data modeled exactly like the provided design screenshot
    return const DashboardData(
      overallProgress: 0.26, // 26%
      totalTerms: 1040,
      knownTerms: 268,
      learnedWordsCount: 268,
      learningWordsCount: 124,
      starredWordsCount: 47,
      examCount: 12,
      averageExamScore: 0.82, // 82%
      levelProgressList: [
        LevelProgressData(
          levelCode: 'B1',
          levelName: 'Intermediate',
          progress: 0.69,
          knownTerms: 185,
          totalTerms: 240,
        ),
        LevelProgressData(
          levelCode: 'B2',
          levelName: 'Upper Intermediate',
          progress: 0.38,
          knownTerms: 85,
          totalTerms: 220,
        ),
        LevelProgressData(
          levelCode: 'C1 & C2',
          levelName: 'Advanced',
          progress: 0.05,
          knownTerms: 23,
          totalTerms: 480,
        ),
      ],
      strongestUnits: [
        UnitProgressData(
          unitId: '1',
          unitName: 'Unit 1',
          progress: 1.0,
        ),
        UnitProgressData(
          unitId: '3',
          unitName: 'Unit 3',
          progress: 0.75,
        ),
        UnitProgressData(
          unitId: '2',
          unitName: 'Unit 2',
          progress: 0.71,
        ),
      ],
      weakestUnits: [
        UnitProgressData(
          unitId: '6',
          unitName: 'Unit 6',
          progress: 0.0,
        ),
        UnitProgressData(
          unitId: '5',
          unitName: 'Unit 5',
          progress: 0.12,
        ),
        UnitProgressData(
          unitId: '4',
          unitName: 'Unit 4',
          progress: 0.26,
        ),
      ],
      recentExams: [
        RecentExamItem(
          id: 'exam-1',
          dateLabel: 'Today',
          unitId: '1',
          unitName: 'Unit 1: Travel & Places',
          score: 0.50,
          questionCount: 10,
        ),
        RecentExamItem(
          id: 'exam-2',
          dateLabel: 'Yesterday',
          unitId: '2',
          unitName: 'Unit 2: Work & Career',
          score: 0.75,
          questionCount: 15,
        ),
        RecentExamItem(
          id: 'exam-3',
          dateLabel: 'Jun 17',
          unitId: '3',
          unitName: 'Unit 3: Health & Body',
          score: 0.85,
          questionCount: 12,
        ),
      ],
      recentCoachFeedback: [
        RecentCoachItem(
          id: 'coach-1',
          dateLabel: 'June 20',
          word: 'Resilience',
          sentence: 'Her resilience in difficult situations inspired everyone around her.',
          rating: 5,
        ),
        RecentCoachItem(
          id: 'coach-2',
          dateLabel: 'June 19',
          word: 'Eloquent',
          sentence: 'The eloquent speaker captivated the entire audience with ease.',
          rating: 4,
        ),
      ],
    );
  }
}
