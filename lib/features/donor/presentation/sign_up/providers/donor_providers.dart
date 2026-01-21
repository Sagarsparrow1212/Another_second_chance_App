// Dio provider (reuse from auth if available, or create new)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/sign_up/donor_remote_datasource.dart';
import '../../../data/models/sign_up/donor_registration_model.dart';
import '../../../data/repositories/sign_up/donor_repository_impl.dart';
import '../../../data/usecases/sign_up/register_donor_usecase.dart';

final donorDioProvider = Provider((ref) => Dio());

// Datasource provider
final donorRemoteDatasourceProvider = Provider(
  (ref) => DonorRemoteDatasource(ref.watch(donorDioProvider)),
);

// Repository provider
final donorRepositoryProvider = Provider(
  (ref) => DonorRepositoryImpl(ref.watch(donorRemoteDatasourceProvider)),
);

// Usecase provider
final registerDonorUseCaseProvider = Provider(
  (ref) => RegisterDonorUseCase(ref.watch(donorRepositoryProvider)),
);

final getDonorDetailsUseCaseProvider = FutureProvider<DonorDetailModel>((
  ref,
) async {
  final useCase = RegisterDonorUseCase(ref.watch(donorRepositoryProvider));
  return await useCase.getDonorDetails();
});

final donorDetailsProvider = Provider<AsyncValue<DonorDetailModel>>((ref) {
  return ref.watch(getDonorDetailsUseCaseProvider);
});
