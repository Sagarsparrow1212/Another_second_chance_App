import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/dashboard/dashboard_model.dart';

class DashboardRemoteDatasource {
  final Dio dio;

  DashboardRemoteDatasource(this.dio);

  /// Get organization dashboard data
  Future<DashboardResponse> getDashboard() async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/organizations/me/dashboard';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return DashboardResponse.fromJson(response.data);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch dashboard data',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
