import '../../models/sign_up/organization_registration_model.dart';

abstract class ProfileRepository {
  Future<OrganizationDetailModel> getOrganizationDetails();
  Future<Map<String, dynamic>> deleteHomelessProfile(String homelessId);
}
