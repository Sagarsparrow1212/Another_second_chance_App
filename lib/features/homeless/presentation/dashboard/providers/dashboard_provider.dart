import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/dashboard/dashboard_remote_datasource.dart';
import '../../../data/models/dashboard/dashboard_model.dart';

// Dio provider
final homelessDashboardDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final homelessDashboardRemoteDatasourceProvider = Provider(
  (ref) => HomelessDashboardRemoteDatasource(
    ref.watch(homelessDashboardDioProvider),
  ),
);

// Dashboard data provider
final homelessDashboardProvider = FutureProvider<HomelessDashboardResponse>((
  ref,
) async {
  final datasource = ref.watch(homelessDashboardRemoteDatasourceProvider);
  return await datasource.getDashboard();
});
