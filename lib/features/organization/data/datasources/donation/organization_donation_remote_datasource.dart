import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/donation/organization_donation_history_response.dart';

class OrganizationDonationRemoteDatasource {
  final Dio dio;

  OrganizationDonationRemoteDatasource(this.dio);

  Future<OrganizationDonationHistoryResponse>
  getOrganizationDonationHistory() async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/donations/organization/my-history';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return OrganizationDonationHistoryResponse.fromJson(response.data);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch donation history',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching donation history: $e');
    }
  }
}
