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
      print(headers);
      print('$apiBaseUrl/wallet');

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

  Future<List<WalletTransaction>> getTransactions(String filter) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/wallet/transactions?filter=$filter';
      
      final response = await dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> transactionsJson = response.data['data']['transactions'];
        return transactionsJson
            .map((json) => WalletTransaction.fromJson(json))
            .toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to fetch transactions',
        );
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
}
