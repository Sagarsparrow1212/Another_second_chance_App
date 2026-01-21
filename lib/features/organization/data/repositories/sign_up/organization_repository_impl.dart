import 'package:homelyhope/features/organization/data/datasources/sign_up/organization_remote_datasource.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';

class OrganizationRepositoryImpl {
  final OrganizationRemoteDatasource remoteDatasource;

  OrganizationRepositoryImpl(this.remoteDatasource);

  Future<OrganizationDetailModel> register(
    OrganizationDetailModel model,
  ) async {
    return await remoteDatasource.register(model);
  }

  Future<OrganizationDetailModel> getOrganizationDetails() async {
    return await remoteDatasource.getOrganizationDetails();
  }

  Future<OrganizationDetailModel> updateOrganizationDetails(
    OrganizationDetailModel model,
    String id,
  ) async {
    print('🔗 [ORG REPOSITORY] updateOrganizationDetails called with ID: $id');
    try {
      print(
        '🔗 [ORG REPOSITORY] Calling remoteDatasource.updateOrganizationDetails...',
      );
      final result = await remoteDatasource.updateOrganizationDetails(
        model,
        id,
      );
      print('🔗 [ORG REPOSITORY] RemoteDatasource returned result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ORG REPOSITORY] Error in updateOrganizationDetails: $e');
      print('❌ [ORG REPOSITORY] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
