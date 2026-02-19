import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

/// Simple model for homeless person (for donor view)
class HomelessPerson {
  final String id;
  final String fullName;
  final String? profilePicture;
  final int? age;
  final String? gender;

  final String? location;
  final String? healthConditions;
  final String? bio;
  final List<String>? skills;
  final OrganizationInfo? organization;
  final String? contactPhone;
  final String? contactEmail;

  HomelessPerson({
    required this.id,
    required this.fullName,
    this.profilePicture,
    this.age,
    this.gender,
    this.location,
    this.healthConditions,
    this.bio,
    this.skills,
    this.organization,
    this.contactPhone,
    this.contactEmail,
  });

  factory HomelessPerson.fromJson(Map<String, dynamic> json) {
    return HomelessPerson(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'Unknown',
      profilePicture: json['profilePicture'],
      age: json['age'],
      gender: json['gender'],
      location: json['location'],
      healthConditions: json['healthConditions'],
      bio: json['bio'],
      skills: json['skillset'] != null
          ? List<String>.from(json['skillset'])
          : json['skills'] != null
          ? List<String>.from(json['skills'])
          : null,
      organization: json['organization'] is Map<String, dynamic>
          ? OrganizationInfo.fromJson(
              json['organization'] as Map<String, dynamic>,
            )
          : null,
      contactPhone: json['contactPhone'] ?? json['phone'],
      contactEmail: json['contactEmail'] ?? json['email'],
    );
  }
}

class OrganizationInfo {
  final String id;
  final String name;
  final String? city;
  final String? state;

  OrganizationInfo({
    required this.id,
    required this.name,
    this.city,
    this.state,
  });

  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
    );
  }
}

class HomelessListByOrgResponse {
  final bool success;
  final List<HomelessPerson> homeless;
  final String message;

  HomelessListByOrgResponse({
    required this.success,
    required this.homeless,
    required this.message,
  });

  factory HomelessListByOrgResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final homelessList = <HomelessPerson>[];

    if (data is List) {
      for (final item in data) {
        homelessList.add(HomelessPerson.fromJson(item));
      }
    }

    return HomelessListByOrgResponse(
      success: json['success'] ?? false,
      homeless: homelessList,
      message: json['message'] ?? '',
    );
  }
}

/// Pagination model for homeless list
class HomelessPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  HomelessPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory HomelessPagination.fromJson(Map<String, dynamic> json) {
    return HomelessPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}

/// Response model for all homeless API (GET /api/v1/homeless)
class AllHomelessResponse {
  final bool success;
  final List<HomelessPerson> homeless;
  final HomelessPagination pagination;
  final String message;

  AllHomelessResponse({
    required this.success,
    required this.homeless,
    required this.pagination,
    required this.message,
  });

  factory AllHomelessResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final homelessList = <HomelessPerson>[];

    if (data != null && data['homeless'] is List) {
      for (final item in data['homeless']) {
        homelessList.add(HomelessPerson.fromJson(item));
      }
    }

    return AllHomelessResponse(
      success: json['success'] ?? false,
      homeless: homelessList,
      pagination: data != null && data['pagination'] != null
          ? HomelessPagination.fromJson(data['pagination'])
          : HomelessPagination(
              currentPage: 1,
              totalPages: 1,
              totalItems: homelessList.length,
              itemsPerPage: 10,
            ),
      message: json['message'] ?? '',
    );
  }
}

class DonorHomelessRemoteDatasource {
  final Dio dio;

  DonorHomelessRemoteDatasource(this.dio);

  /// Get homeless people by organization ID
  /// @route GET /api/v1/homeless/organization/:organizationId
  /// @access Private
  Future<HomelessListByOrgResponse> getHomelessByOrganization(
    String organizationId,
  ) async {
    try {
      final headers = await getHeaders();
      await Future.delayed(const Duration(seconds: 2));
      final url = '$apiBaseUrl/homeless/organization/$organizationId';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == 'true') {
        return HomelessListByOrgResponse.fromJson(response.data);
      }

      return HomelessListByOrgResponse(
        success: false,
        homeless:
            (response.data['data']['homeless'] as List<dynamic>?)
                ?.map((item) => HomelessPerson.fromJson(item))
                .toList() ??
            [],
        message: response.data['message'] ?? 'Failed to fetch homeless people',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching homeless people: $e');
    }
  }

  /// Get homeless count by organization ID (for quick stats)
  Future<int> getHomelessCountByOrganization(String organizationId) async {
    try {
      final response = await getHomelessByOrganization(organizationId);
      return response.homeless.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all homeless people
  /// @route GET /api/v1/homeless
  /// @access Private (donor)
  Future<AllHomelessResponse> getAllHomeless({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await getHeaders();
      await Future.delayed(const Duration(seconds: 2));
      final url = '$apiBaseUrl/homeless?page=$page&limit=$limit';

      final response = await dio.get(url, options: Options(headers: headers));

      if (response.data['success'] == true) {
        return AllHomelessResponse.fromJson(response.data);
      }

      return AllHomelessResponse(
        success: false,
        homeless: [],
        pagination: HomelessPagination(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          itemsPerPage: 10,
        ),
        message: response.data['message'] ?? 'Failed to fetch homeless people',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching homeless people: $e');
    }
  }
}
