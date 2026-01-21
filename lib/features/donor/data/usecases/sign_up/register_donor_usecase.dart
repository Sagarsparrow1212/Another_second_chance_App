import '../../models/sign_up/donor_registration_model.dart';
import '../../repositories/sign_up/donor_repository_impl.dart';

class RegisterDonorUseCase {
  final DonorRepositoryImpl repository;

  RegisterDonorUseCase(this.repository);

  Future<DonorRegistrationResponse> call(
    DonorRegistrationRequest request,
  ) async {
    return await repository.register(request);
  }

  Future<DonorDetailModel> getDonorDetails() async {
    return await repository.getOrganizationDetails();
  }

  Future<DonorRegistrationResponse> updateDonor(
    String donorId,
    DonorRegistrationRequest request,
  ) async {
    return await repository.updateDonor(donorId, request);
  }
}
