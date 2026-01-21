import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';

class OrganizationRemoteDatasource {
  final Dio dio;
  OrganizationRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<OrganizationDetailModel> register(
    OrganizationDetailModel model,
  ) async {
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

      // Check if request was successful
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }

      // Parse the response data
      final responseData = response.data;
      log('Registration response.data type: ${responseData.runtimeType}');
      log('Registration response.data: $responseData');

      // Handle different response structures
      Map<String, dynamic> organizationData;

      if (responseData is Map<String, dynamic>) {
        // Check if response has a 'data' field
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            organizationData = data;
          } else {
            throw Exception('Invalid response format: data field is not a Map');
          }
        } else {
          // Response data itself is the organization data
          organizationData = responseData;
        }
      } else {
        throw Exception('Invalid response format: response is not a Map');
      }

      log('organizationData keys: ${organizationData.keys.toList()}');
      return OrganizationDetailModel.fromJson(organizationData);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<OrganizationDetailModel> updateOrganizationDetails(
    OrganizationDetailModel model,
    String id,
  ) async {
    try {
      print(
        '🔗 [ORG DATASOURCE] Starting updateOrganizationDetails for ID: $id',
      );
      print('🔗 [ORG DATASOURCE] Calling: $apiBaseUrl/organizations/$id');

      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      print('🔗 [ORG DATASOURCE] Token obtained: ${token.substring(0, 20)}...');

      // Create FormData for multipart/form-data
      final formData = FormData.fromMap({
        'email': model.email,
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
        print(
          '🔗 [ORG DATASOURCE] Adding ${model.documents!.length} documents',
        );
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

      print('🔗 [ORG DATASOURCE] About to call dio.put...');
      final response = await dio.put(
        '$apiBaseUrl/organizations/$id',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      print('🔗 [ORG DATASOURCE] dio.put completed!');
      print('✅ [ORG DATASOURCE] Status Code: ${response.statusCode}');
      print('✅ [ORG DATASOURCE] Response Data: ${response.data}');

      // Check if request was successful
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }

      // Parse the response data
      final responseData = response.data;
      log('Registration response.data type: ${responseData.runtimeType}');
      log('Registration response.data: $responseData');

      // Handle different response structures
      Map<String, dynamic> organizationData;

      if (responseData is Map<String, dynamic>) {
        // Check if response has a 'data' field
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            organizationData = data;
          } else {
            throw Exception('Invalid response format: data field is not a Map');
          }
        } else {
          // Response data itself is the organization data
          organizationData = responseData;
        }
      } else {
        throw Exception('Invalid response format: response is not a Map');
      }

      log('organizationData keys: ${organizationData.keys.toList()}');
      return OrganizationDetailModel.fromJson(organizationData);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  Future<OrganizationDetailModel> getOrganizationDetails() async {
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
      if (response.statusCode == 200) {
        log('response.data type: ${response.data.runtimeType}');
        log('response.data: ${response.data}');
        // API response is likely wrapped in a 'data' field
        final responseData = response.data;
        final organizationData =
            responseData is Map<String, dynamic> &&
                responseData.containsKey('data')
            ? responseData['data']
            : responseData;

        if (organizationData is Map<String, dynamic>) {
          log('organizationData keys: ${organizationData.keys.toList()}');
        }
        return OrganizationDetailModel.fromJson(organizationData);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
