class HomelessModel {
  final String id;
  final String? name;
  final String? fullName;
  final String? username;
  final String? email;
  final String? phone;
  final String? contactPhone;
  final String? contactEmail;
  final int? age;
  final String? gender;
  final List<String>? skills;
  final List<String>? skillset;
  final String? experience;
  final String? location;
  final String? address;
  final String? organizationCutPercentage;
  final String? bio;
  final List<String>? languages;
  final String? healthConditions;
  final String? profilePicture;
  final String? verificationDocument;
  final bool? verified;

  final String? createdAt;
  final String? organizationId;

  HomelessModel({
    required this.id,
    this.name,
    this.fullName,
    this.email,
    this.username,

    this.organizationCutPercentage,
    this.phone,
    this.contactPhone,
    this.contactEmail,
    this.age,
    this.gender,
    this.skills,
    this.skillset,
    this.experience,
    this.location,
    this.address,

    this.bio,
    this.languages,
    this.healthConditions,
    this.profilePicture,
    this.verificationDocument,
    this.verified,

    this.createdAt,
    this.organizationId,
  });

  factory HomelessModel.fromJson(Map<String, dynamic> json) {
    return HomelessModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      fullName: json['fullName'],
      username: json['username'],
      organizationCutPercentage: json['organizationCutPercentage'],
      email: json['email'] ?? json['contactEmail'],
      phone: json['phone'],
      contactPhone: json['contactPhone'] ?? json['phone'],
      contactEmail: json['contactEmail'] ?? json['email'],
      age: json['age'],
      gender: json['gender'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      skillset: json['skillset'] != null
          ? List<String>.from(json['skillset'])
          : null,
      experience: json['experience'],
      location: json['location'],
      address: json['address'],
      bio: json['bio'],
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      healthConditions: json['healthConditions'],
      profilePicture: json['profilePicture'],
      verificationDocument: json['verificationDocument'],
      verified: json['verified'],

      createdAt: json['createdAt'],
      organizationId: json['organizationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'fullName': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'age': age,
      'gender': gender,
      'skills': skills,
      'skillset': skillset,
      'experience': experience,
      'location': location,
      'address': address,
      'organizationCutPercentage': organizationCutPercentage,
      'bio': bio,
      'languages': languages,
      'healthConditions': healthConditions,
      'profilePicture': profilePicture,
      'verificationDocument': verificationDocument,
      'verified': verified,

      'createdAt': createdAt,
      'organizationId': organizationId,
    };
  }
}

// Response model for getHomelessByOrganization API
class HomelessListResponse {
  final List<HomelessModel> homeless;
  final Map<String, dynamic>? organization;

  HomelessListResponse({required this.homeless, this.organization});

  factory HomelessListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return HomelessListResponse(
      homeless: (data['homeless'] as List<dynamic>? ?? [])
          .map((item) => HomelessModel.fromJson(item))
          .toList(),
      organization: data['organization'] as Map<String, dynamic>?,
    );
  }
}

// Organization info model for detail view
class OrganizationInfo {
  final String id;
  final String name;
  final String? city;
  final String? state;

  OrganizationInfo({
    required this.id,
    required this.name,
    this.city,
    this.state,
  });

  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
    );
  }
}

// Enhanced detail response model that includes organization info
class HomelessDetailResponse {
  final HomelessModel homeless;
  final OrganizationInfo? organization;
  final bool? isActive;
  final String? userEmail;
  final bool? hasPassword;
  final String? updatedAt;

  HomelessDetailResponse({
    required this.homeless,
    this.organization,
    this.isActive,
    this.userEmail,
    this.hasPassword,
    this.updatedAt,
  });

  factory HomelessDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return HomelessDetailResponse(
      homeless: HomelessModel.fromJson(data),
      organization: data['organization'] != null
          ? OrganizationInfo.fromJson(data['organization'])
          : null,
      isActive: data['isActive'],
      userEmail: data['userEmail'],
      hasPassword: data['hasPassword'],
      updatedAt: data['updatedAt'],
    );
  }
}
