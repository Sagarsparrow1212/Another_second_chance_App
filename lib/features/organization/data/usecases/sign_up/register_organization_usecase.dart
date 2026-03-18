import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';
import 'package:homelyhope/features/organization/data/repositories/sign_up/organization_repository_impl.dart';

class RegisterOrganizationUseCase {
  final OrganizationRepositoryImpl repository;

  RegisterOrganizationUseCase(this.repository);

  Future<OrganizationRegistrationResponse> call(
    OrganizationDetailModel model,
  ) async {
    return await repository.register(model);
  }

  Future<OrganizationDetailModel> getOrganizationDetails() async {
    return await repository.getOrganizationDetails();
  }

  Future<OrganizationDetailModel> updateOrganizationDetails(
    OrganizationDetailModel model,
    String id,
  ) async {
    print('🔗 [ORG USECASE] updateOrganizationDetails called with ID: $id');
    try {
      print('🔗 [ORG USECASE] Calling repository.updateOrganizationDetails...');
      final result = await repository.updateOrganizationDetails(model, id);
      print('🔗 [ORG USECASE] Repository returned result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [ORG USECASE] Error in updateOrganizationDetails: $e');
      print('❌ [ORG USECASE] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
