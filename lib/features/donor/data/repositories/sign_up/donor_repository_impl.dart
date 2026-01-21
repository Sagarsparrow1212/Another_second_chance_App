import '../../datasources/sign_up/donor_remote_datasource.dart';
import '../../models/sign_up/donor_registration_model.dart';

class DonorRepositoryImpl {
  final DonorRemoteDatasource remoteDatasource;

  DonorRepositoryImpl(this.remoteDatasource);

  Future<DonorRegistrationResponse> register(
    DonorRegistrationRequest request,
  ) async {
    return await remoteDatasource.register(request);
  }

  Future<DonorDetailModel> getOrganizationDetails() async {
    return await remoteDatasource.getOrganizationDetails();
  }

  Future<DonorRegistrationResponse> updateDonor(
    String donorId,
    DonorRegistrationRequest request,
  ) async {
    return await remoteDatasource.updateDonor(donorId, request);
  }
}
