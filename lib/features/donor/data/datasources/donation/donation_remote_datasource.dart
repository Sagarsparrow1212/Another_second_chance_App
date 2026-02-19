import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/donation/donation_model.dart';
import '../../models/donation/donation_history_response.dart';

class DonationRemoteDatasource {
  final Dio dio;

  DonationRemoteDatasource(this.dio);

  /// Create a new donation
  Future<DonationResponse> createDonation(CreateDonationRequest request) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/donations';
      log('url: $url');
      final response = await dio.post(
        url,
        data: request.toJson(),
        options: Options(headers: headers),
      );
      log('response: ${response.data}');
      if (response.data['success'] == true) {
        log('response: ${response.data}');
        return DonationResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to create donation');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Get donations by donor ID
  Future<List<DonationModel>> getDonationsByDonor(String donorId) async {
    try {
      final headers = await getHeaders();
      await Future.delayed(const Duration(seconds: 2));
      final url = '$apiBaseUrl/donations/donor/$donorId';

      final response = await dio.get(url, options: Options(headers: headers));

      // Handle raw list response
      if (response.data is List) {
        return (response.data as List)
            .map((e) => DonationModel.fromJson(e))
            .toList();
      }

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((e) => DonationModel.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch donations');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Get donation by ID
  Future<DonationModel> getDonationById(String donationId) async {
    try {
      final headers = await getHeaders();
      await Future.delayed(const Duration(seconds: 2));
      final url = '$apiBaseUrl/donations/$donationId';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return DonationModel.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch donation');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Get donations by homeless ID (for homeless users to see their donations)
  /// Uses the endpoint /api/v1/donations/homeless/:homelessId
  /// The API automatically resolves to the current user's ID, so "me" or any ID works
  Future<List<DonationModel>> getDonationsByHomeless(String homelessId) async {
    try {
      final headers = await getHeaders();
      log('headers: $headers');
      log('homelessId: $homelessId');

      // Use "me" to automatically get current user's donations, or use specific ID
      final url = '$apiBaseUrl/donations/homeless/me';
      log('url: $url');
      await Future.delayed(const Duration(seconds: 2));
      final response = await dio.get(url, options: Options(headers: headers));

      // Handle raw list response
      if (response.data is List) {
        return (response.data as List)
            .map((e) => DonationModel.fromJson(e))
            .toList();
      }

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          return [];
        }

        // Handle nested structure: data.donations
        if (data is Map && data['donations'] != null) {
          final donations = data['donations'];
          if (donations is List) {
            return donations.map((e) => DonationModel.fromJson(e)).toList();
          }
        }

        // Fallback: if data is directly a list
        if (data is List) {
          return data.map((e) => DonationModel.fromJson(e)).toList();
        }

        return [];
      }
      throw Exception(response.data['message'] ?? 'Failed to fetch donations');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }

  /// Get my donation history
  Future<DonationHistoryResponse> getMyDonationHistory() async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/donations/my-history';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return DonationHistoryResponse.fromJson(response.data);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch donation history',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching donation history: $e');
    }
  }
}
