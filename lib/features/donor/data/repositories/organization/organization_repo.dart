import '../../models/organization/organization_model.dart';

abstract class GetAllOrganizationRepository {
  Future<OrganizationListResponse> getAllOrganizations({
    int page = 1,
    int limit = 100,
  });
}
