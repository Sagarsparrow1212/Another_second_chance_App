import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/homeless_people/homeless_model.dart';

class HomelessRemoteDatasource {
  final Dio dio;

  HomelessRemoteDatasource(this.dio);

  // Get homeless users by organization ID
  Future<HomelessListResponse> getHomelessByOrganization(
    String organizationId, {
    String? search,
  }) async {
    try {
      final headers = await getHeaders();
      String url = '$apiBaseUrl/homeless/organization/$organizationId';

      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      await Future.delayed(const Duration(seconds: 5));
      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return HomelessListResponse.fromJson(response.data);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch homeless users',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  // Register a new homeless person
  Future<Map<String, dynamic>> registerHomeless({
    required String username,
    required String password,
    required String fullName,
    required int age,
    required String gender,
    required List<String> skillset,
    required String experience,
    required String location,
    required String address,
    required String contactPhone,
    required String contactEmail,
    required String bio,
    required List<String> languages,
    required String healthConditions,
    required String organizationId,
    required String organizationCutPercentage,
    File? profilePicture,
  }) async {
    try {
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
        'fullName': fullName,
        'age': age.toString(),
        'gender': gender,
        'skillset': jsonEncode(skillset),
        'experience': experience,
        'location': location,
        'address': address,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'bio': bio,
        'languages': jsonEncode(languages),
        'healthConditions': healthConditions,
        'organizationId': organizationId,
        'organizationCutPercentage': organizationCutPercentage,
      });

      // Add profile picture if provided
      if (profilePicture != null) {
        final fileName = profilePicture.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePicture',
            await MultipartFile.fromFile(
              profilePicture.path,
              filename: fileName,
            ),
          ),
        );
      }

      final response = await dio.post(
        '$apiBaseUrl/homeless/register',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to register homeless person',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: msg,
      );
    }
  }

  // Update homeless person
  Future<Map<String, dynamic>> updateHomeless({
    required String homelessId,
    required String token,
    String? fullName,
    int? age,
    String? gender,
    List<String>? skillset,
    String? experience,
    String? location,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? bio,
    List<String>? languages,
    String? healthConditions,
    String? organizationCutPercentage,
    File? profilePicture,
    File? verificationDocument,
  }) async {
    try {
      final formDataMap = <String, dynamic>{};

      // Only add fields that are provided (partial update support)
      if (fullName != null && fullName.isNotEmpty) {
        formDataMap['fullName'] = fullName;
      }
      if (age != null) {
        formDataMap['age'] = age.toString();
      }
      if (gender != null && gender.isNotEmpty) {
        formDataMap['gender'] = gender;
      }
      if (skillset != null && skillset.isNotEmpty) {
        formDataMap['skillset'] = jsonEncode(skillset);
      }
      if (experience != null) {
        formDataMap['experience'] = experience;
      }
      if (location != null) {
        formDataMap['location'] = location;
      }
      if (address != null) {
        formDataMap['address'] = address;
      }
      if (contactPhone != null && contactPhone.isNotEmpty) {
        formDataMap['contactPhone'] = contactPhone;
      }
      if (contactEmail != null && contactEmail.isNotEmpty) {
        formDataMap['contactEmail'] = contactEmail;
      }
      if (bio != null) {
        formDataMap['bio'] = bio;
      }
      if (languages != null) {
        formDataMap['languages'] = jsonEncode(languages);
      }
      if (healthConditions != null) {
        formDataMap['healthConditions'] = healthConditions;
      }
      if (organizationCutPercentage != null) {
        formDataMap['organizationCutPercentage'] = organizationCutPercentage;
      }

      final formData = FormData.fromMap(formDataMap);

      // Add profile picture if provided
      if (profilePicture != null) {
        final fileName = profilePicture.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profilePicture',
            await MultipartFile.fromFile(
              profilePicture.path,
              filename: fileName,
            ),
          ),
        );
      }

      // Add verification document if provided
      if (verificationDocument != null) {
        final fileName = verificationDocument.path.split('/').last;
        formData.files.add(
          MapEntry(
            'verificationDocument',
            await MultipartFile.fromFile(
              verificationDocument.path,
              filename: fileName,
            ),
          ),
        );
      }

      final response = await dio.put(
        '$apiBaseUrl/homeless/$homelessId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to update homeless person',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: msg,
      );
    }
  }

  // Get homeless by ID - returns enhanced detail response
  Future<HomelessDetailResponse> getHomelessById(String homelessId) async {
    try {
      final headers = await getHeaders();
      await Future.delayed(const Duration(seconds: 5));
      final response = await dio.get(
        '$apiBaseUrl/homeless/$homelessId',
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        return HomelessDetailResponse.fromJson(response.data);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch homeless person',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
