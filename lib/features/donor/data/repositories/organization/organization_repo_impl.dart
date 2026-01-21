import 'package:homelyhope/features/donor/data/models/organization/organization_model.dart';
import '../../datasources/organization/get_org_remote_datasource.dart';
import '../../repositories/organization/organization_repo.dart';

class GetAllOrganizationRepositoryImpl implements GetAllOrganizationRepository {
  final GetAllOrgRemoteDatasource remoteDatasource;
  GetAllOrganizationRepositoryImpl(this.remoteDatasource);

  @override
  Future<OrganizationListResponse> getAllOrganizations({
    int page = 1,
    int limit = 100,
  }) async {
    return await remoteDatasource.getOrganizations(page: page, limit: limit);
  }
}
