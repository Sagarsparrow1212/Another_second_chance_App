import '../../models/sign_up/merchant_registration_model.dart';
import '../../repositories/sign_up/merchant_repository_impl.dart';

class RegisterMerchantUseCase {
  final MerchantRepositoryImpl repository;

  RegisterMerchantUseCase(this.repository);

  Future<MerchantRegistrationResponse> call(
    MerchantRegistrationRequest request,
  ) async {
    return await repository.register(request);
  }

  Future<MerchantDetailModel> getMerchantDetails() async {
    return await repository.getMerchantDetails();
  }
}
