import '../../models/sign_up/homeless_registration_model.dart';

import '../../repositories/sign_up/homeless_repository_impl.dart';

class RegisterHomelessUseCase {
  final HomelessRepositoryImpl repository;

  RegisterHomelessUseCase(this.repository);

  Future<HomelessDetailModel> call(HomelessDetailModel model) async {
    return await repository.register(model);
  }

  Future<HomelessDetailModel> getHomelessDetails() async {
    return await repository.getHomelessDetails();
  }
}
