class OrganizationDonationHistoryResponse {
  final bool success;
  final String message;
  final OrganizationDonationHistoryData? data;

  OrganizationDonationHistoryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OrganizationDonationHistoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationDonationHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? OrganizationDonationHistoryData.fromJson(json['data'])
          : null,
    );
  }
}

class OrganizationDonationHistoryData {
  final List<OrganizationDonationHistoryItem> donations;
  final OrganizationDonationPagination? pagination;

  OrganizationDonationHistoryData({required this.donations, this.pagination});

  factory OrganizationDonationHistoryData.fromJson(Map<String, dynamic> json) {
    return OrganizationDonationHistoryData(
      donations:
          (json['donations'] as List<dynamic>?)
              ?.map((e) => OrganizationDonationHistoryItem.fromJson(e))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? OrganizationDonationPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class OrganizationDonationHistoryItem {
  final String id;
  final String donationId;
  final String donationType;
  final double amount;
  final double fee;
  final double netAmount;
  final double homelessAmount;
  final double organizationAmount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final DateTime createdAt;
  final DonorInfo? donor;
  final HomelessInfo? homeless;
  // organizationId comes as string in the example
  final String? organizationId;

  OrganizationDonationHistoryItem({
    required this.id,
    required this.donationId,
    required this.donationType,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.homelessAmount,
    required this.organizationAmount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.donor,
    this.homeless,
    this.organizationId,
  });

  factory OrganizationDonationHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrganizationDonationHistoryItem(
      id: json['_id'] ?? '',
      donationId: json['donationId'] ?? '',
      donationType: json['donationType'] ?? 'Money',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      homelessAmount: (json['homelessAmount'] as num?)?.toDouble() ?? 0.0,
      organizationAmount:
          (json['organizationAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'Pending',
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      donor: json['donorId'] != null && json['donorId'] is Map
          ? DonorInfo.fromJson(json['donorId'])
          : null,
      homeless: json['homelessId'] != null && json['homelessId'] is Map
          ? HomelessInfo.fromJson(json['homelessId'])
          : null,
      organizationId: json['organizationId'] is String
          ? json['organizationId']
          : null,
    );
  }
}

class DonorInfo {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;

  DonorInfo({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory DonorInfo.fromJson(Map<String, dynamic> json) {
    return DonorInfo(
      id: json['_id'] ?? '',
      fullName: json['donorFullName'] ?? 'Unknown',
      email: json['donorEmail'] ?? '',
      phoneNumber: json['donorPhoneNumber'] ?? '',
    );
  }
}

class HomelessInfo {
  final String id;
  final String fullName;
  final String contactEmail;
  final String contactPhone;
  final double organizationCutPercentage;

  HomelessInfo({
    required this.id,
    required this.fullName,
    required this.contactEmail,
    required this.contactPhone,
    this.organizationCutPercentage = 0.0,
  });

  factory HomelessInfo.fromJson(Map<String, dynamic> json) {
    return HomelessInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      organizationCutPercentage:
          (json['organizationCutPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrganizationDonationPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  OrganizationDonationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory OrganizationDonationPagination.fromJson(Map<String, dynamic> json) {
    return OrganizationDonationPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}
