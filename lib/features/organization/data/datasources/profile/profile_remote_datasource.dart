import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

import '../../models/sign_up/organization_registration_model.dart';

class ProfileRemoteDatasource {
  final Dio dio;
  ProfileRemoteDatasource(this.dio);

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<OrganizationDetailModel> getOrganizationDetails() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      await Future.delayed(const Duration(seconds: 5));
      final response = await dio.get(
        '${baseUrl}/api/v1/organizations/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        // API response is likely wrapped in a 'data' field
        final responseData = response.data;
        final organizationData =
            responseData is Map<String, dynamic> &&
                responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        print(organizationData);
        return OrganizationDetailModel.fromJson(organizationData);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> deleteHomelessProfile(String homelessId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      print(
        '🗑️ [DATASOURCE] Starting deleteHomelessProfile for ID: $homelessId',
      );
      print('🗑️ [DATASOURCE] Calling: $apiBaseUrl/homeless/$homelessId');
      print('🗑️ [DATASOURCE] Token: ${token.substring(0, 20)}...');

      print('🗑️ [DATASOURCE] About to call dio.delete...');
      final response = await dio.delete(
        '$apiBaseUrl/homeless/$homelessId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('🗑️ [DATASOURCE] dio.delete completed!');

      print('✅ [DATASOURCE] Status Code: ${response.statusCode}');
      print('✅ [DATASOURCE] Response Data: ${response.data}');
      print('✅ [DATASOURCE] Response Type: ${response.data.runtimeType}');

      // Return response data with status code for better handling
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      // Add status code to response for easier success checking
      responseData['statusCode'] = response.statusCode;
      responseData['success'] =
          response.statusCode != null &&
          (response.statusCode! >= 200 && response.statusCode! < 300);

      return responseData;
    } on DioException catch (e) {
      print('❌ [DELETE API] DioException: ${e.message}');
      print('❌ [DELETE API] Response: ${e.response?.data}');
      print('❌ [DELETE API] Status Code: ${e.response?.statusCode}');
      final msg =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      print('❌ [DELETE API] General Exception: $e');
      rethrow;
    }
  }
}
