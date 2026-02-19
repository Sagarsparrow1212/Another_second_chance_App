import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/dashboard/donor_dashboard_response.dart';

class DonorDashboardRemoteDatasource {
  final Dio dio;

  DonorDashboardRemoteDatasource(this.dio);

  Future<DonorDashboardData> getDashboardStats() async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/donors/dashboard';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return DonorDashboardResponse.fromJson(response.data).data!;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch dashboard stats',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }
}
