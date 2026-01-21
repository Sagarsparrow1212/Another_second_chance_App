import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/dashboard/dashboard_remote_datasource.dart';
import '../../../data/models/dashboard/dashboard_model.dart';

// Dio provider
final dashboardDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final dashboardRemoteDatasourceProvider = Provider(
  (ref) => DashboardRemoteDatasource(ref.watch(dashboardDioProvider)),
);

// Dashboard data provider
final dashboardProvider = FutureProvider<DashboardResponse>((ref) async {
  final datasource = ref.watch(dashboardRemoteDatasourceProvider);
  return await datasource.getDashboard();
});
