import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

import '../../models/profile/donor_profile_model.dart';

class DonorProfileRemoteDatasource {
  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DonorProfileRemoteDatasource(this.dio);

  Future<DonorProfileModel> getMyProfile() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      log('Fetching donor profile...');
      await Future.delayed(const Duration(seconds: 2));
      log('Donor profile request: $token');
      final response = await dio.get(
        '$apiBaseUrl/donors/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      log('Donor profile response: ${response.data}');
      return DonorProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      log('Donor profile error: ${e.response?.data}');
      final msg = e.response?.data?['message'] ?? 'Failed to fetch profile';
      throw Exception(msg);
    }
  }
}
