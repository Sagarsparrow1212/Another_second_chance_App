import '../../datasources/jobs/job_remote_datasource.dart';
import '../../models/jobs/jobs_model.dart';
import '../../repositories/jobs/jobs_repository.dart';

class JobsMerchantRepositoryImpl implements JobsMerchantRepository {
  final JobsMerchantRemoteDatasource remoteDatasource;
  JobsMerchantRepositoryImpl(this.remoteDatasource);

  @override
  Future<JobsMerchantListResponse> getJobsForMerchant(String merchantId) async {
    return await remoteDatasource.getJobsForMerchant(merchantId);
  }
}
