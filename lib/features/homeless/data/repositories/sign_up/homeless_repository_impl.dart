import '../../datasources/sign_up/homeless_remote_datasource.dart';
import '../../models/sign_up/homeless_registration_model.dart';

class HomelessRepositoryImpl {
  final HomelessRemoteDatasource remoteDatasource;

  HomelessRepositoryImpl(this.remoteDatasource);

  Future<HomelessDetailModel> register(HomelessDetailModel model) async {
    return await remoteDatasource.register(model);
  }

  Future<HomelessDetailModel> getHomelessDetails() async {
    return await remoteDatasource.getHomelessDetails();
  }
}
