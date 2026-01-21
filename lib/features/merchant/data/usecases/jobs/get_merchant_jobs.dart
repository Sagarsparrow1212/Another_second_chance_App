import '../../models/jobs/jobs_model.dart';
import '../../repositories/jobs/jobs_repository.dart';

class GetMerchantJobsUseCase {
  final JobsMerchantRepository repository;

  GetMerchantJobsUseCase(this.repository);

  Future<JobsMerchantListResponse> call(String merchantId) async {
    return await repository.getJobsForMerchant(merchantId);
  }
}
