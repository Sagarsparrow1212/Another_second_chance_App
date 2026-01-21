import 'package:dio/dio.dart';
import '../../../../../core/contanst/contanst.dart';
import '../../../../common/auth/data/services/auth_storage_service.dart';

import '../../models/myprofile/myprofile_model.dart';

class ProfileMerchantRemoteDatasource {
  final Dio dio;
  ProfileMerchantRemoteDatasource(this.dio);

  Future<MyProfileModel> getMyProfile() async {
    try {
      final token = await AuthStorageService.getToken();
      final response = await dio.get(
        '$apiBaseUrl/merchants/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('profle response: ${response.data}');
      final profileResponse = MyProfileResponse.fromJson(response.data);
      return profileResponse.data;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
