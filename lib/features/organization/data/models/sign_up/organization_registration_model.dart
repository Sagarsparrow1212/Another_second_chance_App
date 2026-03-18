class OrganizationDetailModel {
  final String? id;
  final String name;
  final String? password;
  final String email;
  final String? emergencyContactEmail;
  final String orgType;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String? logo;
  final String country;
  final String? contactPerson;
  final String? contactPhone;
  final String? currentStatus;
  final bool? verified;
  final bool? resubmitted;
  final String? createdAt;

  final List<OrgDocument>? documents;
  final List<OrgPhoto>? photos;

  final OrgRejection? rejection;

  final String? stripeAccountId;

  OrganizationDetailModel({
    this.id,
    required this.name,
    this.logo,
    this.password,
    required this.email,
    required this.emergencyContactEmail,
    required this.orgType,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.contactPerson,
    required this.contactPhone,
    this.currentStatus,
    this.verified,
    this.resubmitted,
    this.createdAt,

    required this.documents,
    this.photos,

    this.rejection,
    this.stripeAccountId,
  });

  factory OrganizationDetailModel.fromJson(Map<String, dynamic> json) {
    return OrganizationDetailModel(
      id: json['id'] ?? json['_id'] ?? "",
      name: json['name'] ?? json['orgName'] ?? "",
      email: json['email'] ?? "",
      emergencyContactEmail: json['emergencyContactEmail'] ?? "",
      orgType: json['orgType'] ?? "",
      streetAddress: json['streetAddress'] ?? "",
      city: json['city'] ?? "",
      state: json['state'] ?? "",
      zipCode: json['zipCode'] ?? "",
      country: json['country'] ?? "",
      logo: json['logo'] ?? "",
      contactPerson: json['contactPerson'] ?? "",
      contactPhone: json['contactPhone'] ?? "",
      currentStatus: json['currentStatus'] ?? json['status'] ?? "",
      verified: json['verified'] ?? json['isVerified'] ?? false,
      resubmitted: json['resubmitted'] ?? false,
      createdAt: json['createdAt'] ?? json['created_at'] ?? "",

      documents: (json["documents"] as List<dynamic>? ?? [])
          .map((e) => OrgDocument.fromJson(e))
          .toList(),

      photos: (json["photos"] as List<dynamic>? ?? [])
          .map((e) => OrgPhoto.fromJson(e))
          .toList(),

      rejection: json["rejection"] != null
          ? OrgRejection.fromJson(json["rejection"])
          : null,
      stripeAccountId: json['stripeAccountId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emergencyContactEmail': emergencyContactEmail,
      'orgType': orgType,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'currentStatus': currentStatus,
      'verified': verified,
      'resubmitted': resubmitted,
      'createdAt': createdAt,
      'documents': documents?.map((e) => e.toJson()).toList(),
      'photos': photos?.map((e) => e.toJson()).toList(),
      'rejection': rejection?.toJson(),
      'stripeAccountId': stripeAccountId,
    };
  }
}

class OrgPhoto {
  final String photoName;
  final String photoUrl;
  final String id;

  OrgPhoto({required this.photoName, required this.photoUrl, required this.id});

  factory OrgPhoto.fromJson(Map<String, dynamic> json) {
    return OrgPhoto(
      photoName: json["photoName"] ?? "",
      photoUrl: json["photoUrl"] ?? "",
      id: json["_id"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {'photoName': photoName, 'photoUrl': photoUrl, '_id': id};
  }
}

class OrgDocument {
  final String docName;
  final String docUrl;
  final String id;

  OrgDocument({required this.docName, required this.docUrl, required this.id});

  factory OrgDocument.fromJson(Map<String, dynamic> json) {
    return OrgDocument(
      docName: json["docName"] ?? "",
      docUrl: json["docUrl"] ?? "",
      id: json["_id"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {'docName': docName, 'docUrl': docUrl, '_id': id};
  }
}

class OrgRejection {
  final String reason;
  final String rejectedAt;

  OrgRejection({required this.reason, required this.rejectedAt});

  factory OrgRejection.fromJson(Map<String, dynamic> json) {
    return OrgRejection(
      reason: json["reason"] ?? "",
      rejectedAt: json["rejectedAt"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {'reason': reason, 'rejectedAt': rejectedAt};
  }
}

class OrganizationRegistrationResponse {
  final bool success;
  final String message;
  final String? accountLink; // <-- STRIPE URL
  final OrganizationDetailModel? data;

  OrganizationRegistrationResponse({
    required this.success,
    required this.message,
    this.accountLink,
    this.data,
  });

  factory OrganizationRegistrationResponse.fromJson(Map<String, dynamic> json) {
    // Expected structure: JSON -> data -> organization -> accountLinkUrl
    final data = json['data'] as Map<String, dynamic>?;
    final orgData = data?['organization'] as Map<String, dynamic>?;

    return OrganizationRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accountLink: orgData?['accountLinkUrl'],
      data: orgData != null ? OrganizationDetailModel.fromJson(orgData) : null,
    );
  }
}
