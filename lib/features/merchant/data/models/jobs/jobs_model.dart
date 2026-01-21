 /// Salary range model for job
class SalaryRange {
  final int min;
  final int max;

  SalaryRange({required this.min, required this.max});

  factory SalaryRange.fromJson(Map<String, dynamic> json) {
    // Handle both int and string values from API
    final minValue = json['min'];
    final maxValue = json['max'];
    return SalaryRange(
      min: minValue is int
          ? minValue
          : (minValue is String ? int.tryParse(minValue) ?? 0 : 0),
      max: maxValue is int
          ? maxValue
          : (maxValue is String ? int.tryParse(maxValue) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }
}

/// Location model for job
class JobLocation {
  final String address;
  final double? lat;
  final double? lng;

  JobLocation({required this.address, this.lat, this.lng});

  factory JobLocation.fromJson(Map<String, dynamic> json) {
    return JobLocation(
      address: json['address'] ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'address': address, 'lat': lat, 'lng': lng};
  }
}

/// Merchant information model
class MerchantInfo {
  final String id;
  final String businessName;

  MerchantInfo({required this.id, required this.businessName});

  factory MerchantInfo.fromJson(Map<String, dynamic> json) {
    return MerchantInfo(
      id: json['_id'] ?? json['id'] ?? '',
      businessName: json['businessName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'businessName': businessName};
  }
}

/// Pagination model
class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    // Handle both int and string values from API
    int parseToInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Pagination(
      currentPage: parseToInt(json['currentPage'], 1),
      totalPages: parseToInt(json['totalPages'], 1),
      totalItems: parseToInt(json['totalItems'], 0),
      itemsPerPage: parseToInt(json['itemsPerPage'], 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
    };
  }
}

/// Job model
class JobModel {
  final String id;
  final SalaryRange? salaryRange;
  final JobLocation? location;
  final MerchantInfo? merchantId;
  final String title;
  final String description;
  final String category;
  final String status;
  final bool isDeleted;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int version;

  JobModel({
    required this.id,
    this.salaryRange,
    this.location,
    this.merchantId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.version = 0,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Safely parse nested objects - check if they are Maps before parsing
    SalaryRange? salaryRange;
    if (json['salaryRange'] != null && json['salaryRange'] is Map) {
      try {
        salaryRange = SalaryRange.fromJson(
          json['salaryRange'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('Error parsing salaryRange: $e');
      }
    }

    JobLocation? location;
    if (json['location'] != null && json['location'] is Map) {
      try {
        location = JobLocation.fromJson(
          json['location'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('Error parsing location: $e');
      }
    }

    MerchantInfo? merchantId;
    if (json['merchantId'] != null && json['merchantId'] is Map) {
      try {
        merchantId = MerchantInfo.fromJson(
          json['merchantId'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('Error parsing merchantId: $e');
      }
    }

    return JobModel(
      id: json['_id'] ?? json['id'] ?? '',
      salaryRange: salaryRange,
      location: location,
      merchantId: merchantId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'active',
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] is int
          ? json['__v']
          : (json['__v'] is String ? int.tryParse(json['__v']) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'salaryRange': salaryRange?.toJson(),
      'location': location?.toJson(),
      'merchantId': merchantId?.toJson(),
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }
}

/// Response model for jobs list API
class JobsMerchantListResponse {
  final bool success;
  final String message;
  final List<JobModel> jobs;
  final Pagination? pagination;

  JobsMerchantListResponse({
    required this.success,
    required this.message,
    required this.jobs,
    this.pagination,
  });

  factory JobsMerchantListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    // Safely parse jobs list - handle if it's a string or not a list
    List<JobModel> jobsList = [];
    final jobsData = data['jobs'];
    if (jobsData is List) {
      jobsList = jobsData
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return JobModel.fromJson(item);
              } else if (item is Map) {
                // Handle case where item is Map but not Map<String, dynamic>
                return JobModel.fromJson(Map<String, dynamic>.from(item));
              }
              print('Warning: job item is not a Map, got ${item.runtimeType}');
              return null;
            } catch (e, stackTrace) {
              print('Error parsing job item: $e');
              print('Stack trace: $stackTrace');
              return null;
            }
          })
          .whereType<JobModel>()
          .toList();
    } else if (jobsData != null) {
      print('Warning: jobs is not a list, got ${jobsData.runtimeType}');
    }

    return JobsMerchantListResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      jobs: jobsList,
      pagination: data['pagination'] != null && data['pagination'] is Map
          ? Pagination.fromJson(data['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'jobs': jobs.map((job) => job.toJson()).toList(),
        'pagination': pagination?.toJson(),
      },
    };
  }
}
