import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/profile/donor_profile_remote_datasource.dart';
import '../../../data/models/profile/donor_profile_model.dart';

final donorProfileDioProvider = Provider((ref) => Dio());

final donorProfileRemoteDatasourceProvider = Provider(
  (ref) => DonorProfileRemoteDatasource(ref.watch(donorProfileDioProvider)),
);

final donorProfileProvider = FutureProvider<DonorProfileModel>((ref) async {
  final datasource = ref.watch(donorProfileRemoteDatasourceProvider);
  return await datasource.getMyProfile();
});
