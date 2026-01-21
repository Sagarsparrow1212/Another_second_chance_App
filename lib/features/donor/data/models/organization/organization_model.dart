class OrganizationListResponse {
  bool success;
  String message;
  List<OrganizationModel> organizations;

  OrganizationListResponse({
    required this.success,
    required this.message,
    required this.organizations,
  });

  factory OrganizationListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    // Safely parse jobs list - handle if it's a string or not a list
    List<OrganizationModel> organizationsList = [];
    final organizationsData = data['organizations'];
    if (organizationsData is List) {
      organizationsList = organizationsData
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return OrganizationModel.fromJson(item);
              } else if (item is Map) {
                // Handle case where item is Map but not Map<String, dynamic>
                return OrganizationModel.fromJson(
                  Map<String, dynamic>.from(item),
                );
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<OrganizationModel>()
          .toList();
    } else if (organizationsData != null) {
      print(
        'Warning: organizations is not a list, got ${organizationsData.runtimeType}',
      );
    }

    return OrganizationListResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      organizations: organizationsList,
    );
  }
}

class OrganizationModel {
  final String id;
  final String name;
  final String email;
  final String emergencyContactEmail;
  final String orgType;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  int? homelessCount;

  final String country;
  final String contactPerson;
  final String contactPhone;
  final String currentStatus;
  final String latestRequestId;
  final String latestRejectionId;
  final bool verified;
  final bool resubmitted;
  final bool isResubmitted;
  final String createdAt;
  final String userEmail;
  final bool isUserVerified;
  final bool isUserActive;
  final String logo;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.email,
    required this.emergencyContactEmail,
    required this.orgType,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    this.homelessCount,
    required this.country,
    required this.contactPerson,
    required this.contactPhone,

    required this.currentStatus,
    required this.latestRequestId,
    required this.latestRejectionId,
    required this.verified,
    required this.resubmitted,
    required this.isResubmitted,
    required this.createdAt,
    required this.userEmail,
    required this.isUserVerified,
    required this.isUserActive,
    required this.logo,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emergencyContactEmail: json['emergencyContactEmail'] ?? '',
      orgType: json['orgType'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      homelessCount: json['homelessCount'] ?? 0,
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      currentStatus: json['currentStatus'] ?? '',
      latestRequestId: json['latestRequestId'] ?? '',
      latestRejectionId: json['latestRejectionId'] ?? '',
      verified: json['verified'] ?? false,
      resubmitted: json['resubmitted'] ?? false,
      isResubmitted: json['isResubmitted'] ?? false,
      createdAt: json['createdAt'] ?? '',
      userEmail: json['userEmail'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      isUserActive: json['isUserActive'] ?? false,
      logo: json['logo'] ?? '',
    );
  }
}

