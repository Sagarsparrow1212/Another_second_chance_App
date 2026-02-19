import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/dashboard/dashboard_model.dart';

class HomelessDashboardRemoteDatasource {
  final Dio dio;

  HomelessDashboardRemoteDatasource(this.dio);

  /// Get homeless dashboard data
  Future<HomelessDashboardResponse> getDashboard() async {
    try {
      final headers = await getHeaders();
      print('headers: $headers');
      final url = '$apiBaseUrl/dashboard/homeless';
      print('url: $url');
      await Future.delayed(const Duration(seconds: 2));
      final response = await dio.get(url, options: Options(headers: headers));
      print('response: ${response.data}');
      if (response.data['success'] == true) {
        print('response: ${response.data}');
        return HomelessDashboardResponse.fromJson(response.data);
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
