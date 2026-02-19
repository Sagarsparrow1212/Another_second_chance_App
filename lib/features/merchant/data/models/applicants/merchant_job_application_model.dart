import 'package:homelyhope/features/merchant/data/models/jobs/jobs_model.dart';

class MerchantJobApplicationModel {
  final String id;
  final JobModel job;
  final ApplicantModel applicant;
  final String status;
  final String appliedAt;
  final String? notes;

  MerchantJobApplicationModel({
    required this.id,
    required this.job,
    required this.applicant,
    required this.status,
    required this.appliedAt,
    this.notes,
  });

  factory MerchantJobApplicationModel.fromJson(Map<String, dynamic> json) {
    return MerchantJobApplicationModel(
      id: json['_id'] ?? json['id'] ?? '',
      job: JobModel.fromJson(json['jobId'] ?? {}),
      applicant: ApplicantModel.fromJson(
        json['homelessId'] ?? json['applicantId'] ?? {},
      ),
      status: json['status'] ?? 'pending',
      appliedAt: json['appliedAt'] ?? '',
      notes: json['notes'],
    );
  }
}

class ApplicantModel {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;

  ApplicantModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
  });

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Applicant',
      email: json['contactEmail'] ?? json['email'] ?? '',
      photoUrl: json['profilePicture'] ?? json['photoUrl'],
      phoneNumber: json['contactPhone'] ?? json['phoneNumber'],
    );
  }
}
