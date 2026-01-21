import '../../models/myprofile/myprofile_model.dart';

abstract class ProfileMerchantRepository {
  Future<MyProfileModel> getMyProfile();
}
