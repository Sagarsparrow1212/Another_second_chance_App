import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/sign_up/merchant_registration_model.dart';

class MerchantRemoteDatasource {
  final Dio dio;
  MerchantRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<MerchantRegistrationResponse> register(
    MerchantRegistrationRequest request,
  ) async {
    try {
      // Create FormData for multipart/form-data
      final formData = FormData.fromMap({
        'businessName': request.businessName,
        'businessEmail': request.businessEmail,
        'phoneNumber': request.phoneNumber,
        'password': request.password,
        'businessType': request.businessType,
        'address': request.address,
        'city': request.city,
        'state': request.state,
        'contactPersonName': request.contactPersonName,
        'contactPersonDesignation': request.contactPersonDesignation,
      });

      // Add file uploads if provided
      if (request.gstCertificatePath != null &&
          request.gstCertificatePath!.isNotEmpty) {
        final file = File(request.gstCertificatePath!);
        if (await file.exists()) {
          final fileName = request.gstCertificatePath!.split('/').last;
          formData.files.add(
            MapEntry(
              'gstCertificate',
              await MultipartFile.fromFile(
                request.gstCertificatePath!,
                filename: fileName,
              ),
            ),
          );
        }
      }

      if (request.businessLicensePath != null &&
          request.businessLicensePath!.isNotEmpty) {
        final file = File(request.businessLicensePath!);
        if (await file.exists()) {
          final fileName = request.businessLicensePath!.split('/').last;
          formData.files.add(
            MapEntry(
              'businessLicense',
              await MultipartFile.fromFile(
                request.businessLicensePath!,
                filename: fileName,
              ),
            ),
          );
        }
      }

      if (request.photoIdPath != null && request.photoIdPath!.isNotEmpty) {
        final file = File(request.photoIdPath!);
        if (await file.exists()) {
          final fileName = request.photoIdPath!.split('/').last;
          formData.files.add(
            MapEntry(
              'photoId',
              await MultipartFile.fromFile(
                request.photoIdPath!,
                filename: fileName,
              ),
            ),
          );
        }
      }

      final response = await dio.post(
        '$apiBaseUrl/merchants/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data['success'] == true) {
        return MerchantRegistrationResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<MerchantDetailModel> getMerchantDetails() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      final response = await dio.get(
        '$apiBaseUrl/organizations/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as MerchantDetailModel;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
