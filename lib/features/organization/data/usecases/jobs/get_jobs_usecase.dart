import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:homelyhope/features/organization/data/repositories/jobs/jobs_repository.dart';

class GetJobsUseCase {
  final JobsRepository repository;

  GetJobsUseCase(this.repository);

  Future<JobsListResponse> call({int page = 1, int limit = 100}) async {
    return await repository.getJobs(page: page, limit: limit);
  }

  Future<JobDetailModel> getJobDetail(String jobId) async {
    return await repository.getJobDetail(jobId);
  }

  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    print('🔗 [JOBS USECASE] deleteJob called with ID: $jobId');
    try {
      print('🔗 [JOBS USECASE] Calling repository.deleteJob...');
      final result = await repository.deleteJob(jobId);
      print('🔗 [JOBS USECASE] Repository returned result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [JOBS USECASE] Error in deleteJob: $e');
      print('❌ [JOBS USECASE] Stack trace: $stackTrace');
      print('❌ [JOBS USECASE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> applyJob(String jobId) async {
    return await repository.applyJob(jobId);
  }
}
