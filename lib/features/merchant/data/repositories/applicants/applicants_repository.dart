import 'package:homelyhope/features/merchant/data/datasources/applicants/applicants_remote_datasource.dart';
import 'package:homelyhope/features/merchant/data/models/applicants/merchant_job_application_model.dart';
import 'package:dio/dio.dart';

abstract class ApplicantsRepository {
  Future<List<MerchantJobApplicationModel>> getMerchantApplications();
  Future<void> approveApplication(String applicationId);
  Future<void> rejectApplication(String applicationId);
}

class ApplicantsRepositoryImpl implements ApplicantsRepository {
  final ApplicantsRemoteDatasource remoteDatasource;

  ApplicantsRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<MerchantJobApplicationModel>> getMerchantApplications() async {
    try {
      return await remoteDatasource.getMerchantApplications();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> approveApplication(String applicationId) async {
    try {
      await remoteDatasource.approveApplication(applicationId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<void> rejectApplication(String applicationId) async {
    try {
      await remoteDatasource.rejectApplication(applicationId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
