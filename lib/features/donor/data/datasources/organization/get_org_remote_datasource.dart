import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/contanst/contanst.dart';
import '../../models/organization/organization_model.dart';

class GetAllOrgRemoteDatasource {
  final Dio dio;

  GetAllOrgRemoteDatasource(this.dio);
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Fetch organizations. If the API paginates, this will attempt to
  /// fetch all pages by requesting subsequent `page` values.
  Future<OrganizationListResponse> getOrganizations({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        throw Exception('Token is null');
      }
      final uri = '$apiBaseUrl/organizations';

      final response = await dio.get(
        uri,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Parse first page
      final parsed = OrganizationListResponse.fromJson(response.data);
      print('First page orgs count: ${parsed.organizations}');
      
      // If API returned fewer items than total (pagination metadata), try to fetch remaining pages
      try {
        final data = response.data['data'] ?? response.data;
        final total =
            data['total'] ??
            data['meta']?['total'] ??
            data['pagination']?['total'];
        final perPage =
            data['perPage'] ??
            data['meta']?['per_page'] ??
            data['meta']?['perPage'] ??
            parsed.organizations.length;

        if (total != null && perPage != null) {
          final totalInt =
              int.tryParse(total.toString()) ??
              (total is int ? total : parsed.organizations.length);
          final perPageInt =
              int.tryParse(perPage.toString()) ??
              (perPage is int ? perPage : parsed.organizations.length);

          if (totalInt > parsed.organizations.length) {
            final pages = (totalInt / perPageInt).ceil();
            final allOrgs = <dynamic>[];
            // include first page items
            allOrgs.addAll(
              response.data['data']?['organizations'] ??
                  response.data['organizations'] ??
                  parsed.organizations,
            );

            for (var p = 2; p <= pages; p++) {
              try {
                final pageResp = await dio.get(
                  uri,
                  queryParameters: {'page': p, 'limit': perPageInt},
                  options: Options(headers: {'Authorization': 'Bearer $token'}),
                );
                final pageData = pageResp.data['data'] ?? pageResp.data;
                final pageOrgs =
                    pageData['organizations'] ?? pageResp.data['organizations'];
                if (pageOrgs is List) {
                  allOrgs.addAll(pageOrgs);
                }
              } catch (_) {
                // ignore individual page failures
              }
            }

            // Reconstruct OrganizationListResponse from collected items
            final combinedJson = {
              'success': response.data['success'] ?? true,
              'message': response.data['message'] ?? '',
              'data': {'organizations': allOrgs},
            };
            return OrganizationListResponse.fromJson(combinedJson);
          }
        }
      } catch (_) {
        // ignore parsing errors and return first page
      }

      return parsed;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    }
  }
}
