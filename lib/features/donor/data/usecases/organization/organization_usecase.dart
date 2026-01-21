import '../../models/organization/organization_model.dart';
import '../../repositories/organization/organization_repo.dart';

class GetAllOrganizationUseCase {
  final GetAllOrganizationRepository repository;
  GetAllOrganizationUseCase(this.repository);
  @override
  Future<OrganizationListResponse> call({int page = 1, int limit = 100}) async {
    return await repository.getAllOrganizations(page: page, limit: limit);
  }
}
