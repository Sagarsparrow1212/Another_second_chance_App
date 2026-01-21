import 'package:homelyhope/features/organization/data/datasources/profile/profile_remote_datasource.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';
import 'package:homelyhope/features/organization/data/repositories/profile/profile_respository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl(this.remoteDatasource);

  @override
  Future<OrganizationDetailModel> getOrganizationDetails() async {
    return await remoteDatasource.getOrganizationDetails();
  }

  Future<Map<String, dynamic>> deleteHomelessProfile(String homelessId) async {
    print('🔗 [REPOSITORY] deleteHomelessProfile called with ID: $homelessId');
    try {
      print(
        '🔗 [REPOSITORY] Calling remoteDatasource.deleteHomelessProfile...',
      );
      final result = await remoteDatasource.deleteHomelessProfile(homelessId);
      print('🔗 [REPOSITORY] RemoteDatasource returned result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [REPOSITORY] Error in deleteHomelessProfile: $e');
      print('❌ [REPOSITORY] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
