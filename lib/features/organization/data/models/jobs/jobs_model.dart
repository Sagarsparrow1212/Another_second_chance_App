/// Salary range model for job
class SalaryRange {
  final int min;
  final int max;

  SalaryRange({required this.min, required this.max});

  factory SalaryRange.fromJson(Map<String, dynamic> json) {
    return SalaryRange(min: json['min'] ?? 0, max: json['max'] ?? 0);
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
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
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

class JobDetailModel {
  final bool success;
  final String message;
  final JobModel job;

  JobDetailModel({
    required this.success,
    required this.message,
    required this.job,
  });

  factory JobDetailModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] ?? json;
    final jobJson = payload['job'] ?? payload;
    if (jobJson is! Map<String, dynamic>) {
      throw Exception('Invalid job payload');
    }
    return JobDetailModel(
      success: json['success'] ?? payload['success'] ?? false,
      message: json['message'] ?? payload['message'] ?? '',
      job: JobModel.fromJson(jobJson),
    );
  }
}

/// Job model
class JobModel {
  final String id;
  final SalaryRange? salaryRange;
  final JobLocation? location;
  final MerchantInfo? merchant;
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
    this.merchant,
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
    return JobModel(
      id: json['_id'] ?? json['id'] ?? '',
      salaryRange: json['salaryRange'] != null
          ? SalaryRange.fromJson(json['salaryRange'])
          : null,
      location: json['location'] != null
          ? JobLocation.fromJson(json['location'])
          : null,
      merchant: json['merchantId'] != null
          ? MerchantInfo.fromJson(json['merchantId'])
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'active',
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'salaryRange': salaryRange?.toJson(),
      'location': location?.toJson(),
      'merchantId': merchant?.toJson(),
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
class JobsListResponse {
  final bool success;
  final String message;
  final List<JobModel> jobs;
  final Pagination? pagination;

  JobsListResponse({
    required this.success,
    required this.message,
    required this.jobs,
    this.pagination,
  });

  factory JobsListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return JobsListResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      jobs: (data['jobs'] as List<dynamic>? ?? [])
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: data['pagination'] != null
          ? Pagination.fromJson(data['pagination'])
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
