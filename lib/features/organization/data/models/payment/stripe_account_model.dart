class StripeAccountModel {
  final String id;
  final bool detailsSubmitted;
  final bool chargesEnabled;
  final bool payoutsEnabled;

  StripeAccountModel({
    required this.id,
    required this.detailsSubmitted,
    required this.chargesEnabled,
    required this.payoutsEnabled,
  });

  factory StripeAccountModel.fromJson(Map<String, dynamic> json) {
    print(json);
    return StripeAccountModel(
      id: json['id'] ?? '',
      detailsSubmitted: json['details_submitted'] ?? false,
      chargesEnabled: json['charges_enabled'] ?? false,
      payoutsEnabled: json['payouts_enabled'] ?? false,
    );
  }
}
