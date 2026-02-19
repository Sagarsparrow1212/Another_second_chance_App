import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/datasources/payment/payment_remote_datasource.dart';
import '../../../data/models/payment/payment_success_request.dart';

// Dio provider
final paymentDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final paymentRemoteDatasourceProvider = Provider(
  (ref) => PaymentRemoteDatasource(ref.watch(paymentDioProvider)),
);

// StateNotifier for payment actions
class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  PaymentNotifier(this._datasource) : super(const AsyncValue.data(null));

  final PaymentRemoteDatasource _datasource;

  Future<void> confirmPaymentSuccess(PaymentSuccessRequest request) async {
    state = const AsyncValue.loading();
    try {
      await _datasource.confirmPaymentSuccess(request);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for payment notifier
final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<void>>((ref) {
      return PaymentNotifier(ref.watch(paymentRemoteDatasourceProvider));
    });
