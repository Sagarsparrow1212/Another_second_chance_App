import 'package:dio/dio.dart';
import '../../models/wallet/wallet_response.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

class OrganizationWalletRemoteDatasource {
  final Dio dio;

  OrganizationWalletRemoteDatasource(this.dio);

  Future<WalletResponse> getWalletDetails() async {
    try {
      final headers = await getHeaders();
      final response = await dio.get(
        '$apiBaseUrl/wallet',
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        return WalletResponse.fromJson(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch wallet details',
        );
      }
    } catch (e) {
      throw Exception('Error fetching wallet details: $e');
    }
  }
}
