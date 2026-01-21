import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';

abstract class JobsRepository {
  Future<JobsListResponse> getJobs({int page = 1, int limit = 100});
  Future<JobDetailModel> getJobDetail(String jobId);
  Future<Map<String, dynamic>> deleteJob(String jobId);
}
