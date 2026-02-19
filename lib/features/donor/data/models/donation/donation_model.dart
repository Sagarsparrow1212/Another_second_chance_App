class DonationModel {
  final String donationId;
  final String donorId;
  final String? donorName;
  final String homelessId;
  final String? organizationId;
  final String donationType; // Money, Food, Clothes, Services, Other
  final double? amount;
  final String currency; // INR, USD, EUR
  final String status; // Pending, Completed, Cancelled, Failed
  final String? paymentMethod; // Cash, Bank Transfer, UPI, Credit Card, etc.
  final String? transactionId;
  final String? receiptNumber;
  final String? description;
  final String? notes;
  final Map<String, dynamic>? itemDetails; // For non-monetary donations
  final String? deliveryMethod; // Pickup, Delivery, In-Person
  final String? deliveryAddress;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DonationModel({
    required this.donationId,
    required this.donorId,
    this.donorName,
    required this.homelessId,
    this.organizationId,
    required this.donationType,
    this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.receiptNumber,
    this.description,
    this.notes,
    this.itemDetails,
    this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely extract ID from string or object
    String _extractId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map)
        return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      return value.toString();
    }

    String? _extractName(dynamic value) {
      if (value is Map) {
        return value['fullName']?.toString() ?? value['name']?.toString();
      }
      return null;
    }

    return DonationModel(
      donationId: json['donationId'] ?? json['_id'] ?? '',
      donorId: _extractId(json['donorId']),
      donorName: _extractName(json['donorId']),
      homelessId: _extractId(json['homelessId']),
      organizationId: json['organizationId'] != null
          ? _extractId(json['organizationId'])
          : null,
      donationType: json['donationType']?.toString() ?? '',
      amount: json['amount'] != null
          ? (json['amount'] is int
                ? json['amount'].toDouble()
                : json['amount'] is double
                ? json['amount']
                : double.tryParse(json['amount'].toString()))
          : null,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'Pending',
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      receiptNumber: json['receiptNumber']?.toString(),
      description: json['description']?.toString(),
      notes: json['notes']?.toString(),
      itemDetails: json['itemDetails'] is Map
          ? Map<String, dynamic>.from(json['itemDetails'])
          : null,
      deliveryMethod: json['deliveryMethod']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.tryParse(json['deliveryDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homelessId': homelessId,
      'donationType': donationType,
      if (amount != null) 'amount': amount,
      'currency': currency,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (transactionId != null) 'transactionId': transactionId,
      if (notes != null) 'notes': notes,
      if (itemDetails != null) 'itemDetails': itemDetails,
      if (deliveryMethod != null) 'deliveryMethod': deliveryMethod,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryDate != null) 'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }
}

class CreateDonationRequest {
  final String homelessId;
  final String donationType;
  final double? amount;
  final String currency;
  final String? description;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;

  CreateDonationRequest({
    required this.homelessId,
    required this.donationType,
    this.amount,
    this.currency = 'USD',
    this.description,
    this.paymentMethod,
    this.transactionId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'homelessId': homelessId,
      'donationType': donationType,
      if (amount != null) 'amount': amount,
      'currency': currency,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (transactionId != null) 'transactionId': transactionId,
      if (notes != null) 'notes': notes,
    };
  }
}

class DonationResponse {
  final bool success;
  final String message;
  final DonationModel? data;

  DonationResponse({required this.success, required this.message, this.data});

  factory DonationResponse.fromJson(Map<String, dynamic> json) {
    return DonationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? DonationModel.fromJson(json['data']) : null,
    );
  }
}
