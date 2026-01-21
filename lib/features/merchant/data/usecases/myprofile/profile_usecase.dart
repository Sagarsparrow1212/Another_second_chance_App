import '../../models/myprofile/myprofile_model.dart';
import '../../repositories/myprofile/profile_repository.dart';

class ProfileMerchantUseCase {
  final ProfileMerchantRepository repository;
  ProfileMerchantUseCase(this.repository);

  Future<MyProfileModel> call() async {
    return await repository.getMyProfile();
  }
}
