import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/payment/organization_payment_datasource.dart';
import '../../../data/models/payment/stripe_account_model.dart';
import '../../myprofile/providers/profile_provider.dart';

final paymentDioProvider = Provider((ref) => Dio());

final organizationPaymentDatasourceProvider = Provider(
  (ref) => OrganizationPaymentRemoteDatasource(ref.watch(paymentDioProvider)),
);

final stripeAccountStatusProvider = FutureProvider<StripeAccountModel?>((
  ref,
) async {
  // 1. Get the organization profile details
  final orgProfile = await ref.watch(organizationProfileDetailsProvider.future);

  // 2. If there is no stripeAccountId, return null (meaning profile is not linked to Stripe yet)
  if (orgProfile.stripeAccountId == null ||
      orgProfile.stripeAccountId!.isEmpty) {
    return null;
  }

  // 3. Fetch the Stripe account status
  final datasource = ref.watch(organizationPaymentDatasourceProvider);
  return await datasource.getStripeAccountStatus(orgProfile.stripeAccountId!);
});

final connectBalanceProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  // 1. Get the organization profile details
  final orgProfile = await ref.watch(organizationProfileDetailsProvider.future);

  // 2. If there is no stripeAccountId, return null
  if (orgProfile.stripeAccountId == null ||
      orgProfile.stripeAccountId!.isEmpty) {
    return null;
  }

  // 3. Fetch the connect balance
  final datasource = ref.watch(organizationPaymentDatasourceProvider);
  return await datasource.getConnectBalance(orgProfile.stripeAccountId!);
});

/// Exposes a callable that fetches the Stripe onboarding URL on-demand.
/// Usage: await ref.read(getOnboardingLinkProvider)();
final getOnboardingLinkProvider = Provider<Future<String> Function()>((ref) {
  final datasource = ref.read(organizationPaymentDatasourceProvider);
  return datasource.getOnboardingLink;
});

final withdrawFundsProvider = Provider<Future<void> Function(double)>((ref) {
  final datasource = ref.read(organizationPaymentDatasourceProvider);
  return (double amount) => datasource.withdrawFunds(amount);
});
