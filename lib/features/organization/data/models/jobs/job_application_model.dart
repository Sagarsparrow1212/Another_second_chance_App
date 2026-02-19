import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';

class JobApplicationModel {
  final String id;
  final JobModel job;
  final String status;
  final String appliedAt;
  final String? notes;

  JobApplicationModel({
    required this.id,
    required this.job,
    required this.status,
    required this.appliedAt,
    this.notes,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['_id'] ?? json['id'] ?? '',
      job: JobModel.fromJson(json['jobId'] ?? {}),
      status: json['status'] ?? 'pending',
      appliedAt: json['appliedAt'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'jobId': job.toJson(),
      'status': status,
      'appliedAt': appliedAt,
      'notes': notes,
    };
  }
}
