import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/sign_up/donor_registration_model.dart';

class DonorRemoteDatasource {
  final Dio dio;
  DonorRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<DonorRegistrationResponse> register(
    DonorRegistrationRequest request,
  ) async {
    try {
      final response = await dio.post(
        '$apiBaseUrl/donors/register',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.data['success'] == true) {
        return DonorRegistrationResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<DonorDetailModel> getOrganizationDetails() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      await Future.delayed(const Duration(seconds: 5));
      final response = await dio.get(
        '$apiBaseUrl/organizations/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as DonorDetailModel;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Update donor profile
  Future<DonorRegistrationResponse> updateDonor(
    String donorId,
    DonorRegistrationRequest request,
  ) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Create update payload - exclude password if it's the placeholder
      final updateData = request.toJson();
      if (updateData['password'] == 'NO_CHANGE') {
        updateData.remove('password');
      }

      final response = await dio.put(
        '$apiBaseUrl/donors/$donorId',
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data['success'] == true) {
        return DonorRegistrationResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Update failed');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
