import '../../models/jobs/jobs_model.dart';

abstract class JobsMerchantRepository {
  Future<JobsMerchantListResponse> getJobsForMerchant(String merchantId);
}
