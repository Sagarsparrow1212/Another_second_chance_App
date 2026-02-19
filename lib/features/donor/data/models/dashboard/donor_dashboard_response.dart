class DonorDashboardResponse {
  final bool success;
  final String message;
  final DonorDashboardData? data;

  DonorDashboardResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DonorDashboardResponse.fromJson(Map<String, dynamic> json) {
    return DonorDashboardResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DonorDashboardData.fromJson(json['data'])
          : null,
    );
  }
}

class DonorDashboardData {
  final double totalDonated;
  final int totalDonations;
  final int organizationsCount;

  DonorDashboardData({
    required this.totalDonated,
    required this.totalDonations,
    required this.organizationsCount,
  });

  factory DonorDashboardData.fromJson(Map<String, dynamic> json) {
    return DonorDashboardData(
      totalDonated: (json['totalDonated'] as num?)?.toDouble() ?? 0.0,
      totalDonations: json['totalDonations'] ?? 0,
      organizationsCount: json['organizationsCount'] ?? 0,
    );
  }
}
