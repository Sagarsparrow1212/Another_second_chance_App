class PaymentSuccessRequest {
  final String paymentIntentId;
  final String homelessId;
  final String donationType;
  final String message;
  final bool isAnonymous;

  PaymentSuccessRequest({
    required this.paymentIntentId,
    required this.homelessId,
    required this.donationType,
    required this.message,
    required this.isAnonymous,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentIntentId': paymentIntentId,
      'homelessId': homelessId,
      'donationType': donationType,
      'message': message,
      'isAnonymous': isAnonymous,
    };
  }
}
