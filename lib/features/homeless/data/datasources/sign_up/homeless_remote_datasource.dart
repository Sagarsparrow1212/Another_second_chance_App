import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/sign_up/homeless_registration_model.dart';

class HomelessRemoteDatasource {
  final Dio dio;
  HomelessRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<HomelessDetailModel> register(HomelessDetailModel model) async {
    try {
      // Create FormData for multipart/form-data
      final formData = FormData.fromMap({
        'email': model.email,
        'password': model.password,
        'orgName': model.name,
        'orgType': model.orgType,
        'streetAddress': model.streetAddress,
        'city': model.city,
        'state': model.state,
        'zipCode': model.zipCode,
        'country': model.country,
        if (model.contactPerson != null && model.contactPerson!.isNotEmpty)
          'contactPerson': model.contactPerson,
        if (model.emergencyContactEmail != null &&
            model.emergencyContactEmail!.isNotEmpty)
          'emergencyContactEmail': model.emergencyContactEmail,
        if (model.contactPhone != null && model.contactPhone!.isNotEmpty)
          'contactPhone': model.contactPhone,
      });

      // Add documents if provided
      if (model.documents != null && model.documents!.isNotEmpty) {
        for (var file in model.documents!) {
          final fileName = file.docUrl.split('/').last;
          formData.files.add(
            MapEntry(
              'documents',
              await MultipartFile.fromFile(file.docUrl, filename: fileName),
            ),
          );
        }
      }

      final response = await dio.post(
        '$apiBaseUrl/organizations/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data as HomelessDetailModel;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<HomelessDetailModel> getHomelessDetails() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      final response = await dio.get(
        '$apiBaseUrl/organizations/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as HomelessDetailModel;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
