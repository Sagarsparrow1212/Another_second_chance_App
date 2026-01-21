class HomelessDashboardQuickStats {
  final QuickStatItem? totalJobs;
  final QuickStatItem appliedJobs;
  final QuickStatItem? matchingJobs;
  final QuickStatItem totalDonations;
  final QuickStatItem? totalDonationsCount;
  final QuickStatItem recentDonations;
  final QuickStatItem activeJobs;
  final QuickStatItem? pendingJobs;
  final QuickStatItem? organizations;
  final QuickStatItem? merchants;

  HomelessDashboardQuickStats({
    this.totalJobs,
    required this.appliedJobs,
    this.matchingJobs,
    required this.totalDonations,
    this.totalDonationsCount,
    required this.recentDonations,
    required this.activeJobs,
    this.pendingJobs,
    this.organizations,
    this.merchants,
  });

  factory HomelessDashboardQuickStats.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse QuickStatItem
    QuickStatItem? _parseQuickStat(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        return QuickStatItem.fromJson(value);
      }
      return null;
    }

    return HomelessDashboardQuickStats(
      totalJobs: _parseQuickStat(json['totalJobs']),
      appliedJobs: QuickStatItem.fromJson(
        json['appliedJobs'] is Map
            ? json['appliedJobs'] as Map<String, dynamic>
            : {},
      ),
      matchingJobs: _parseQuickStat(json['matchingJobs']),
      totalDonations: QuickStatItem.fromJson(
        json['totalDonations'] is Map
            ? json['totalDonations'] as Map<String, dynamic>
            : {},
      ),
      totalDonationsCount: _parseQuickStat(json['totalDonationsCount']),
      recentDonations: QuickStatItem.fromJson(
        json['recentDonations'] is Map
            ? json['recentDonations'] as Map<String, dynamic>
            : {},
      ),
      activeJobs: QuickStatItem.fromJson(
        json['activeJobs'] is Map
            ? json['activeJobs'] as Map<String, dynamic>
            : {},
      ),
      pendingJobs: _parseQuickStat(json['pendingJobs']),
      organizations: _parseQuickStat(json['organizations']),
      merchants: _parseQuickStat(json['merchants']),
    );
  }
}

class QuickStatItem {
  final String title;
  final int value;
  final String description;
  final String icon;
  final String? formatted;

  QuickStatItem({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    this.formatted,
  });

  factory QuickStatItem.fromJson(Map<String, dynamic> json) {
    // Safely parse value - handle int, double, or string
    int _parseValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return QuickStatItem(
      title: json['title']?.toString() ?? '',
      value: _parseValue(json['value']),
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      formatted: json['formatted']?.toString(),
    );
  }
}

class RecentJob {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final SalaryRange? salaryRange;
  final JobLocation? location;
  final PostedBy? postedBy;
  final String daysAgo;
  final DateTime? createdAt;

  RecentJob({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.salaryRange,
    this.location,
    this.postedBy,
    required this.daysAgo,
    this.createdAt,
  });

  factory RecentJob.fromJson(Map<String, dynamic> json) {
    return RecentJob(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      salaryRange:
          json['salaryRange'] != null &&
              json['salaryRange'] is Map<String, dynamic>
          ? SalaryRange.fromJson(json['salaryRange'] as Map<String, dynamic>)
          : null,
      location:
          json['location'] != null && json['location'] is Map<String, dynamic>
          ? JobLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      postedBy:
          json['postedBy'] != null && json['postedBy'] is Map<String, dynamic>
          ? PostedBy.fromJson(json['postedBy'] as Map<String, dynamic>)
          : null,
      daysAgo: json['timeAgo']?.toString() ?? json['daysAgo']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class SalaryRange {
  final int min;
  final int max;

  SalaryRange({required this.min, required this.max});

  factory SalaryRange.fromJson(Map<String, dynamic> json) {
    return SalaryRange(min: json['min'] ?? 0, max: json['max'] ?? 0);
  }
}

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
}

class PostedBy {
  final String id;
  final String name;
  final String type; // 'merchant' or 'organization'

  PostedBy({required this.id, required this.name, required this.type});

  factory PostedBy.fromJson(Map<String, dynamic> json) {
    return PostedBy(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['businessName'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class RecentDonation {
  final String id;
  final String donationId;
  final String title;
  final String description;
  final String donorEmail;
  final String donorName;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final String? organization;
  final DateTime createdAt;
  final String timeAgo;
  final int? daysAgo;

  RecentDonation({
    required this.id,
    required this.donationId,
    required this.title,
    required this.description,
    required this.donorEmail,
    required this.donorName,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.organization,
    required this.createdAt,
    required this.timeAgo,
    this.daysAgo,
  });

  factory RecentDonation.fromJson(Map<String, dynamic> json) {
    // Helper to parse amount
    double _parseAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RecentDonation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      donationId: json['donationId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      donorEmail: json['donor']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      organization: json['organization']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeAgo: json['timeAgo']?.toString() ?? '',
      daysAgo: json['daysAgo'] is int
          ? json['daysAgo'] as int
          : json['daysAgo'] != null
          ? int.tryParse(json['daysAgo'].toString())
          : null,
    );
  }
}

class DashboardInsights {
  final List<CategoryCount> jobsByCategory;
  final List<StatusCount> jobsByStatus;

  DashboardInsights({required this.jobsByCategory, required this.jobsByStatus});

  factory DashboardInsights.fromJson(Map<String, dynamic> json) {
    return DashboardInsights(
      jobsByCategory:
          (json['jobsByCategory'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e))
              .toList() ??
          [],
      jobsByStatus:
          (json['jobsByStatus'] as List<dynamic>?)
              ?.map((e) => StatusCount.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryCount {
  final String category;
  final int count;

  CategoryCount({required this.category, required this.count});

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class StatusCount {
  final String status;
  final int count;

  StatusCount({required this.status, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(status: json['status'] ?? '', count: json['count'] ?? 0);
  }
}

class UserInfo {
  final String homelessId;
  final String fullName;
  final String? organizationId;

  UserInfo({
    required this.homelessId,
    required this.fullName,
    this.organizationId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      homelessId: json['homelessId'] ?? '',
      fullName: json['fullName'] ?? '',
      organizationId: json['organizationId'],
    );
  }
}

class HomelessDashboardResponse {
  final HomelessDashboardQuickStats quickStats;
  final List<RecentJob> recentJobs;
  final List<RecentDonation> recentDonations;
  final DashboardInsights insights;
  final UserInfo userInfo;

  HomelessDashboardResponse({
    required this.quickStats,
    required this.recentJobs,
    required this.recentDonations,
    required this.insights,
    required this.userInfo,
  });

  factory HomelessDashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    // Helper to safely parse List from dynamic value
    List<RecentDonation> _parseRecentDonations(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return RecentDonation.fromJson(e);
                }
                return null;
              } catch (_) {
                return null;
              }
            })
            .whereType<RecentDonation>()
            .toList();
      }
      // If it's a Map, try to extract values
      if (value is Map) {
        final values = value.values.toList();
        return values
            .map((e) {
              try {
                if (e is Map<String, dynamic>) {
                  return RecentDonation.fromJson(e);
                }
                return null;
              } catch (_) {
                return null;
              }
            })
            .whereType<RecentDonation>()
            .toList();
      }
      return [];
    }
    
    return HomelessDashboardResponse(
      quickStats: HomelessDashboardQuickStats.fromJson(
        data['quickStats'] ?? {},
      ),
      recentJobs:
          (data['recentJobs'] as List<dynamic>?)
              ?.map((e) => RecentJob.fromJson(e))
              .toList() ??
          [],
      recentDonations: _parseRecentDonations(data['recentDonations']),
      insights: DashboardInsights.fromJson(data['insights'] ?? {}),
      userInfo: UserInfo.fromJson(data['userInfo'] ?? {}),
    );
  }
}
