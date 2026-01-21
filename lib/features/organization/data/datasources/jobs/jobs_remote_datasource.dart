import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';

class JobsRemoteDatasource {
  final Dio dio;
  JobsRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  Future<JobsListResponse> getJobs({int page = 1, int limit = 100}) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      log('token: $token');
      if (token == null) {
        throw Exception('Token is null');
      }
      await Future.delayed(const Duration(seconds: 5));
      final url = '$apiBaseUrl/jobs?page=$page&limit=${limit + 1}';
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return JobsListResponse.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<JobDetailModel> getJobDetail(String jobId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      await Future.delayed(const Duration(seconds: 5));
      final url = '$apiBaseUrl/jobs/$jobId';
      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return JobDetailModel.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      print('🗑️ [JOBS DATASOURCE] Starting deleteJob for ID: $jobId');
      print('🗑️ [JOBS DATASOURCE] Calling: $apiBaseUrl/jobs/$jobId');
      print('🗑️ [JOBS DATASOURCE] Token: ${token.substring(0, 20)}...');

      print('🗑️ [JOBS DATASOURCE] About to call dio.delete...');
      final response = await dio.delete(
        '$apiBaseUrl/jobs/$jobId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('🗑️ [JOBS DATASOURCE] dio.delete completed!');

      print('✅ [JOBS DATASOURCE] Status Code: ${response.statusCode}');
      print('✅ [JOBS DATASOURCE] Response Data: ${response.data}');
      print('✅ [JOBS DATASOURCE] Response Type: ${response.data.runtimeType}');

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
      print('❌ [JOBS DATASOURCE] DioException: ${e.message}');
      print('❌ [JOBS DATASOURCE] Response: ${e.response?.data}');
      print('❌ [JOBS DATASOURCE] Status Code: ${e.response?.statusCode}');
      final msg =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      print('❌ [JOBS DATASOURCE] General Exception: $e');
      rethrow;
    }
  }
}
