import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/merchant/data/datasources/applicants/applicants_remote_datasource.dart';
import 'package:homelyhope/features/merchant/data/models/applicants/merchant_job_application_model.dart';
import 'package:homelyhope/features/merchant/data/repositories/applicants/applicants_repository.dart';

final applicantsDioProvider = Provider((ref) => Dio());

final applicantsRemoteDatasourceProvider = Provider<ApplicantsRemoteDatasource>(
  (ref) {
    return ApplicantsRemoteDatasource(ref.watch(applicantsDioProvider));
  },
);

final applicantsRepositoryProvider = Provider<ApplicantsRepository>((ref) {
  return ApplicantsRepositoryImpl(
    ref.watch(applicantsRemoteDatasourceProvider),
  );
});

final merchantApplicationsProvider =
    FutureProvider.autoDispose<List<MerchantJobApplicationModel>>((ref) async {
      print('Initializing merchantApplicationsProvider...');
      final repository = ref.watch(applicantsRepositoryProvider);
      return await repository.getMerchantApplications();
    });
