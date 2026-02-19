import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/merchant/data/models/applicants/merchant_job_application_model.dart';

class ApplicantsRemoteDatasource {
  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApplicantsRemoteDatasource(this.dio);

  Future<List<MerchantJobApplicationModel>> getMerchantApplications() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // TODO: Replace with actual endpoint when available
      final url = '$apiBaseUrl/merchants/applications/received';

      print('Fetching applications from: $url');
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Applications response status: ${response.statusCode}');
      print('Applications response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((json) => MerchantJobApplicationModel.fromJson(json))
            .toList();
      }

      throw Exception(
        'Failed to fetch applications: ${response.data['message']}',
      );
    } on DioException catch (e) {
      print('Error fetching applications (DioError): $e');
      print('Response: ${e.response?.data}');
      // Fallback to mock data for now if backend fails, but log it clearly
      return _getMockApplications();
    } catch (e) {
      print('Error fetching applications (General): $e');
      return _getMockApplications();
    }
  }

  Future<void> approveApplication(String applicationId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = '$apiBaseUrl/applications/$applicationId/approve';

      await dio.patch(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? 'Failed to approve application';
      throw Exception(msg);
    }
  }

  List<MerchantJobApplicationModel> _getMockApplications() {
    return [
      MerchantJobApplicationModel.fromJson({
        '_id': '507f1f77bcf86cd799439011',
        'status': 'pending',
        'appliedAt': DateTime.now()
            .subtract(Duration(days: 1))
            .toIso8601String(),
        'jobId': {
          '_id': '507f1f77bcf86cd799439012',
          'title': 'Warehouse Assistant',
          'status': 'active',
          'createdAt': DateTime.now()
              .subtract(Duration(days: 5))
              .toIso8601String(),
        },
        'applicantId': {
          '_id': '507f1f77bcf86cd799439013',
          'fullName': 'John Doe',
          'email': 'john.doe@example.com',
          'phoneNumber': '+1234567890',
        },
      }),
      MerchantJobApplicationModel.fromJson({
        '_id': '507f1f77bcf86cd799439014',
        'status': 'approved',
        'appliedAt': DateTime.now()
            .subtract(Duration(days: 2))
            .toIso8601String(),
        'jobId': {
          '_id': '507f1f77bcf86cd799439015',
          'title': 'Delivery Driver',
          'status': 'active',
          'createdAt': DateTime.now()
              .subtract(Duration(days: 10))
              .toIso8601String(),
        },
        'applicantId': {
          '_id': '507f1f77bcf86cd799439016',
          'fullName': 'Jane Smith',
          'email': 'jane.smith@example.com',
        },
      }),
      MerchantJobApplicationModel.fromJson({
        '_id': '507f1f77bcf86cd799439017',
        'status': 'pending',
        'appliedAt': DateTime.now()
            .subtract(Duration(hours: 5))
            .toIso8601String(),
        'jobId': {
          '_id': '507f1f77bcf86cd799439018',
          'title': 'Warehouse Assistant',
          'status': 'active',
          'createdAt': DateTime.now()
              .subtract(Duration(days: 5))
              .toIso8601String(),
        },
        'applicantId': {
          '_id': '507f1f77bcf86cd799439019',
          'fullName': 'Mike Johnson',
          'email': 'mike.j@example.com',
        },
      }),
    ];
  }
}
