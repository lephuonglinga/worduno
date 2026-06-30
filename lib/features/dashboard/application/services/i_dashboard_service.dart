import '../models/dashboard_data.dart';

abstract class IDashboardService {
  Future<DashboardData> getDashboardData();
}
