class MerchantRegistrationRequest {
  final String businessName;
  final String businessEmail;
  final String phoneNumber;
  final String password;
  final String businessType;
  final String address;
  final String city;
  final String state;
  final String contactPersonName;
  final String contactPersonDesignation;
  final String? gstCertificatePath;
  final String? businessLicensePath;
  final String? photoIdPath;

  MerchantRegistrationRequest({
    required this.businessName,
    required this.businessEmail,
    required this.phoneNumber,
    required this.password,
    required this.businessType,
    required this.address,
    required this.city,
    required this.state,
    required this.contactPersonName,
    required this.contactPersonDesignation,
    this.gstCertificatePath,
    this.businessLicensePath,
    this.photoIdPath,
  });
}

class MerchantRegistrationResponse {
  final bool success;
  final String message;
  final MerchantDetailModel? data;

  MerchantRegistrationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MerchantRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return MerchantRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? MerchantDetailModel.fromJson(json['data'])
          : null,
    );
  }
}

class MerchantDetailModel {
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

  MerchantDetailModel({
    this.id,
    required this.name,
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
  });

  factory MerchantDetailModel.fromJson(Map<String, dynamic> json) {
    return MerchantDetailModel(
      id: json['id'] ?? json['_id'] ?? "",
      name: json['name'] ?? json['businessName'] ?? "",
      email: json['email'] ?? json['businessEmail'] ?? "",
      emergencyContactEmail: json['emergencyContactEmail'] ?? "",
      orgType: json['orgType'] ?? json['businessType'] ?? "",
      streetAddress: json['streetAddress'] ?? json['address'] ?? "",
      city: json['city'] ?? "",
      state: json['state'] ?? "",
      zipCode: json['zipCode'] ?? "",
      country: json['country'] ?? "",
      contactPerson: json['contactPerson'] ?? json['contactPersonName'] ?? "",
      contactPhone: json['contactPhone'] ?? json['phoneNumber'] ?? "",
      currentStatus: json['currentStatus'] ?? "",
      verified: json['verified'] ?? false,
      resubmitted: json['resubmitted'] ?? false,
      createdAt: json['createdAt'] ?? "",

      documents: (json["documents"] as List<dynamic>? ?? [])
          .map((e) => OrgDocument.fromJson(e))
          .toList(),

      photos: (json["photos"] as List<dynamic>? ?? [])
          .map((e) => OrgPhoto.fromJson(e))
          .toList(),

      rejection: json["rejection"] != null
          ? OrgRejection.fromJson(json["rejection"])
          : null,
    );
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
}
