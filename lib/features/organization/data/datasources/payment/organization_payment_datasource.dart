import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../models/payment/stripe_account_model.dart';

class OrganizationPaymentRemoteDatasource {
  final Dio dio;

  OrganizationPaymentRemoteDatasource(this.dio);

  Future<StripeAccountModel> getStripeAccountStatus(String accountId) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/payments/account/$accountId';

      final response = await dio.get(url, options: Options(headers: headers));
      print(response.data);
      if (response.data['success'] == true && response.data['data'] != null) {
        return StripeAccountModel.fromJson(response.data['data']);
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch Stripe account status',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching Stripe account status: $e');
    }
  }

  Future<Map<String, dynamic>> getConnectBalance(String accountId) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/payments/connect-balance/$accountId';

      final response = await dio.get(url, options: Options(headers: headers));
      print('Connect balance response: ${response.data}');
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception(
        response.data['message'] ?? 'Failed to fetch connect balance',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error fetching connect balance: $e');
    }
  }

  /// Fetches a fresh Stripe Connect onboarding link from the backend.
  /// Returns the URL string that should be launched in the browser.
  Future<String> getOnboardingLink() async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/payments/onboarding-link';

      final response = await dio.get(url, options: Options(headers: headers));
      print('Onboarding link response: ${response.data}');

      if (response.data['success'] == true && response.data['data'] != null) {
        final onboardingUrl = response.data['data']['url'] as String?;
        if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
          return onboardingUrl;
        }
      }
      throw Exception(
        response.data['message'] ?? 'Failed to generate onboarding link',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error generating onboarding link: $e');
    }
  }

  Future<void> withdrawFunds(double amount) async {
    try {
      final headers = await getHeaders();
      final url = '$apiBaseUrl/payments/withdraw';

      final response = await dio.post(
        url,
        data: {'amount': amount},
        options: Options(headers: headers),
      );

      if (response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Failed to withdraw funds');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error withdrawing funds: $e');
    }
  }
}
