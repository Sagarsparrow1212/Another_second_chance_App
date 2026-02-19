class WalletResponse {
  final bool success;
  final String message;
  final WalletData? data;

  WalletResponse({required this.success, required this.message, this.data});

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? WalletData.fromJson(json['data']) : null,
    );
  }
}

class WalletData {
  final Wallet wallet;
  final List<WalletTransaction> recentTransactions;

  WalletData({required this.wallet, required this.recentTransactions});

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      wallet: Wallet.fromJson(json['wallet'] ?? {}),
      recentTransactions:
          (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => WalletTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Wallet {
  final String id;
  final double currentBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final String currency;
  final bool isActive;

  Wallet({
    required this.id,
    required this.currentBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.currency,
    required this.isActive,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? '',
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      isActive: json['isActive'] ?? false,
    );
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // CREDIT, DEBIT, WITHDRAWAL
  final String description;
  final String status;
  final DateTime createdAt;
  final String? referenceModel;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.referenceModel,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      referenceModel: json['referenceModel'],
    );
  }
}
