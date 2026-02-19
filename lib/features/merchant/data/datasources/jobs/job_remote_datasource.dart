import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

import '../../models/jobs/jobs_model.dart';

class JobsMerchantRemoteDatasource {
  final Dio dio;
  JobsMerchantRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<JobsMerchantListResponse> getJobsForMerchant(String merchantId) async {
    // log('merchantId: $merchantId');
    try {
      final token = await _secureStorage.read(key: 'token');

      if (token == null) {
        throw Exception('Token is null');
      }
      log('apiBaseUrl: $apiBaseUrl');
      await Future.delayed(const Duration(seconds: 2));
      final response = await dio.get(
        '$apiBaseUrl/merchants/$merchantId/jobs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('response: ${response.data}');

      return JobsMerchantListResponse.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Create a new job posting
  Future<Map<String, dynamic>> createJob(
    Map<String, dynamic> jobData,
    String merchantId,
  ) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      log('Creating job with data: $jobData');

      final response = await dio.post(
        '$apiBaseUrl/merchants/$merchantId/jobs',
        data: jobData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      log('Create job response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      log('Create job error: ${e.response?.data}');
      final msg = e.response?.data?['message'] ?? 'Failed to create job';
      throw Exception(msg);
    }
  }

  /// Update an existing job posting
  Future<Map<String, dynamic>> updateJob(
    String jobId,
    Map<String, dynamic> jobData,
  ) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      log('Updating job $jobId with data: $jobData');

      final response = await dio.patch(
        '$apiBaseUrl/jobs/$jobId',
        data: jobData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      log('Update job response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      log('Update job error: ${e.response?.data}');
      final msg = e.response?.data?['message'] ?? 'Failed to update job';
      throw Exception(msg);
    }
  }

  /// Delete a job posting
  Future<void> deleteJob(String jobId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      log('Deleting job $jobId');

      final response = await dio.delete(
        '$apiBaseUrl/jobs/$jobId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      log('Delete job response: ${response.data}');
    } on DioException catch (e) {
      log('Delete job error: ${e.response?.data}');
      final msg = e.response?.data?['message'] ?? 'Failed to delete job';
      throw Exception(msg);
    }
  }
}
