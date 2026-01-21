import '../../datasources/sign_up/merchant_remote_datasource.dart';
import '../../models/sign_up/merchant_registration_model.dart';

class MerchantRepositoryImpl {
  final MerchantRemoteDatasource remoteDatasource;

  MerchantRepositoryImpl(this.remoteDatasource);

  Future<MerchantRegistrationResponse> register(
    MerchantRegistrationRequest request,
  ) async {
    return await remoteDatasource.register(request);
  }

  Future<MerchantDetailModel> getMerchantDetails() async {
    return await remoteDatasource.getMerchantDetails();
  }
}
