import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/payment/payment_success_request.dart';

class PaymentRemoteDatasource {
  final Dio dio;

  PaymentRemoteDatasource(this.dio);

  Future<void> confirmPaymentSuccess(PaymentSuccessRequest request) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/payments/success';

      final response = await dio.post(
        url,
        data: request.toJson(),
        options: Options(headers: headers),
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to confirm payment',
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }
}
