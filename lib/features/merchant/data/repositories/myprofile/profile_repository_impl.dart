import '../../datasources/myprofile/profile_remote_datasource.dart';
import '../../models/myprofile/myprofile_model.dart';
import '../../repositories/myprofile/profile_repository.dart';

class ProfileMerchantRepositoryImpl implements ProfileMerchantRepository {
  final ProfileMerchantRemoteDatasource remoteDatasource;
  ProfileMerchantRepositoryImpl(this.remoteDatasource);
  @override
  Future<MyProfileModel> getMyProfile() async {
    return await remoteDatasource.getMyProfile();
  }
}
