/// Merchant profile model
class MyProfileModel {
  final String id;
  final String businessName;
  final String businessEmail;
  final String email;
  final String phoneNumber;
  final String businessType;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String contactPersonName;
  final String contactDesignation;
  final String gstCertificate;
  final String businessLicense;
  final String photoId;
  final bool verified;
  final bool isActive;
  final String userEmail;
  final bool isUserVerified;
  final bool isUserActive;
  final String createdAt;
  final String updatedAt;

  MyProfileModel({
    required this.id,
    required this.businessName,
    required this.businessEmail,
    required this.email,
    required this.phoneNumber,
    required this.businessType,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.contactPersonName,
    required this.contactDesignation,
    required this.gstCertificate,
    required this.businessLicense,
    required this.photoId,
    required this.verified,
    required this.isActive,
    required this.userEmail,
    required this.isUserVerified,
    required this.isUserActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
    return MyProfileModel(
      id: json['id'] ?? json['_id'] ?? '',
      businessName: json['businessName'] ?? '',
      businessEmail: json['businessEmail'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      businessType: json['businessType'] ?? '',
      streetAddress: json['streetAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? '',
      contactPersonName: json['contactPersonName'] ?? '',
      contactDesignation: json['contactDesignation'] ?? '',
      gstCertificate: json['gstCertificate'] ?? '',
      businessLicense: json['businessLicense'] ?? '',
      photoId: json['photoId'] ?? '',
      verified: json['verified'] ?? false,
      isActive: json['isActive'] ?? true,
      userEmail: json['userEmail'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      isUserActive: json['isUserActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'businessEmail': businessEmail,
      'email': email,
      'phoneNumber': phoneNumber,
      'businessType': businessType,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'contactPersonName': contactPersonName,
      'contactDesignation': contactDesignation,
      'gstCertificate': gstCertificate,
      'businessLicense': businessLicense,
      'photoId': photoId,
      'verified': verified,
      'isActive': isActive,
      'userEmail': userEmail,
      'isUserVerified': isUserVerified,
      'isUserActive': isUserActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Response model for merchant profile API
class MyProfileResponse {
  final bool success;
  final String message;
  final MyProfileModel data;

  MyProfileResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory MyProfileResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] ?? json;
    return MyProfileResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      data: MyProfileModel.fromJson(dataJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data.toJson()};
  }
}
