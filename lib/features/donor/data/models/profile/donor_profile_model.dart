class DonorProfileModel {
  final String id;
  final String name;
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String preferredDonationType;
  final bool verified;
  final bool isActive;
  final String userEmail;
  final bool isUserVerified;
  final bool isUserActive;
  final String createdAt;
  final String updatedAt;

  DonorProfileModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.preferredDonationType,
    required this.verified,
    required this.isActive,
    required this.userEmail,
    required this.isUserVerified,
    required this.isUserActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DonorProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return DonorProfileModel(
      id: data['id'] ?? data['_id'] ?? '',
      name: data['name'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      preferredDonationType: data['preferredDonationType'] ?? '',
      verified: data['verified'] ?? false,
      isActive: data['isActive'] ?? false,
      userEmail: data['userEmail'] ?? '',
      isUserVerified: data['isUserVerified'] ?? false,
      isUserActive: data['isUserActive'] ?? false,
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
    );
  }
}
