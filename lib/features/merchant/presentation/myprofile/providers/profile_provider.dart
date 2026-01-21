import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/myprofile/profile_remote_datasource.dart';
import '../../../data/models/myprofile/myprofile_model.dart';
import '../../../data/repositories/myprofile/profile_repository_impl.dart';
import '../../../data/usecases/myprofile/profile_usecase.dart';

final profileDioProvider = Provider((ref) => Dio());

final profileMerchantRemoteDatasourceProvider = Provider(
  (ref) => ProfileMerchantRemoteDatasource(ref.watch(profileDioProvider)),
);

final profileMerchantRepositoryProvider = Provider(
  (ref) => ProfileMerchantRepositoryImpl(
    ref.watch(profileMerchantRemoteDatasourceProvider),
  ),
);

final profileMerchantUseCaseProvider = Provider(
  (ref) => ProfileMerchantUseCase(ref.watch(profileMerchantRepositoryProvider)),
);

final profileMerchantProvider = FutureProvider<MyProfileModel>((ref) async {
  final useCase = ref.watch(profileMerchantUseCaseProvider);
  return await useCase.call();
});
