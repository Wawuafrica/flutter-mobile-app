class Wallet {
  final String userId;
  final double balance;
  final String currency;
  final DateTime? lastTransactionDate;
  // Other wallet-specific details like pending balance, etc.

  Wallet({
    required this.userId,
    required this.balance,
    required this.currency,
    this.lastTransactionDate,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      lastTransactionDate:
          json['last_transaction_date'] != null
              ? DateTime.parse(json['last_transaction_date'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
    };
  }
}
