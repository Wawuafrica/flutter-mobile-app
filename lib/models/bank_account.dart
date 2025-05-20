class BankAccount {
  final String id;
  final String userId;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String? swiftCode; // or IBAN, routing number, etc. depending on region
  final String? country;
  final bool isPrimary;

  BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.swiftCode,
    this.country,
    this.isPrimary = false,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      accountHolderName: json['account_holder_name'] as String,
      swiftCode: json['swift_code'] as String?,
      country: json['country'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder_name': accountHolderName,
      'swift_code': swiftCode,
      'country': country,
      'is_primary': isPrimary,
    };
  }
}
