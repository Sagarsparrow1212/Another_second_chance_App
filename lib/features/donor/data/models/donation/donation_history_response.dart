class DonationHistoryResponse {
  final bool success;
  final String message;
  final DonationHistoryData? data;

  DonationHistoryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DonationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DonationHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DonationHistoryData.fromJson(json['data'])
          : null,
    );
  }
}

class DonationHistoryData {
  final List<DonationHistoryItem> donations;
  final DonationPagination? pagination;

  DonationHistoryData({required this.donations, this.pagination});

  factory DonationHistoryData.fromJson(Map<String, dynamic> json) {
    return DonationHistoryData(
      donations:
          (json['donations'] as List<dynamic>?)
              ?.map((e) => DonationHistoryItem.fromJson(e))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? DonationPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class DonationHistoryItem {
  final String id;
  final String donationId;
  final String donationType;
  final double amount;
  final double fee;
  final double netAmount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final HomelessInfo? homeless;
  final OrganizationInfo? organization;

  DonationHistoryItem({
    required this.id,
    required this.donationId,
    required this.donationType,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.homeless,
    this.organization,
  });

  factory DonationHistoryItem.fromJson(Map<String, dynamic> json) {
    return DonationHistoryItem(
      id: json['_id'] ?? '',
      donationId: json['donationId'] ?? '',
      donationType: json['donationType'] ?? 'Money',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'Pending',
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      homeless: json['homelessId'] != null && json['homelessId'] is Map
          ? HomelessInfo.fromJson(json['homelessId'])
          : null,
      organization:
          json['organizationId'] != null && json['organizationId'] is Map
          ? OrganizationInfo.fromJson(json['organizationId'])
          : null,
    );
  }
}

class HomelessInfo {
  final String id;
  final String fullName;

  HomelessInfo({required this.id, required this.fullName});

  factory HomelessInfo.fromJson(Map<String, dynamic> json) {
    return HomelessInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
    );
  }
}

class OrganizationInfo {
  final String id;
  final String orgName;

  OrganizationInfo({required this.id, required this.orgName});

  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      id: json['_id'] ?? '',
      orgName: json['orgName'] ?? 'Unknown',
    );
  }
}

class DonationPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  DonationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory DonationPagination.fromJson(Map<String, dynamic> json) {
    return DonationPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}
