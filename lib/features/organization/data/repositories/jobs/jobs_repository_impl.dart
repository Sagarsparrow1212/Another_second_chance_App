import 'package:homelyhope/features/organization/data/datasources/jobs/jobs_remote_datasource.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:homelyhope/features/organization/data/repositories/jobs/jobs_repository.dart';

class JobsRepositoryImpl implements JobsRepository {
  final JobsRemoteDatasource remoteDatasource;

  JobsRepositoryImpl(this.remoteDatasource);

  @override
  Future<JobsListResponse> getJobs({int page = 1, int limit = 100}) async {
    return await remoteDatasource.getJobs(page: page, limit: limit);
  }

  @override
  Future<JobDetailModel> getJobDetail(String jobId) async {
    return await remoteDatasource.getJobDetail(jobId);
  }

  @override
  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    print('🔗 [JOBS REPOSITORY] deleteJob called with ID: $jobId');
    try {
      print('🔗 [JOBS REPOSITORY] Calling remoteDatasource.deleteJob...');
      final result = await remoteDatasource.deleteJob(jobId);
      print('🔗 [JOBS REPOSITORY] RemoteDatasource returned result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [JOBS REPOSITORY] Error in deleteJob: $e');
      print('❌ [JOBS REPOSITORY] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
