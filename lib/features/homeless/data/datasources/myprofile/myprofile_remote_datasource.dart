import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../../../organization/data/models/homeless_people/homeless_model.dart';

class MyProfileRemoteDatasource {
  final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  MyProfileRemoteDatasource(this.dio);

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  /// Get current homeless user's profile
  Future<HomelessModel> getMyProfile() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }
      
      final response = await dio.get(
        '$apiBaseUrl/homeless/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('$apiBaseUrl/homeless/me');
      if (response.data['success'] == true) {
        return HomelessModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch profile');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
