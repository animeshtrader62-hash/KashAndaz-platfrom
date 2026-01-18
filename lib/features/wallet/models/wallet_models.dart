class WalletBalance {
  final double totalEarned;
  final double pending;
  final double available;
  final double withdrawn;

  WalletBalance({
    required this.totalEarned,
    required this.pending,
    required this.available,
    required this.withdrawn,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0,
      available: (json['available'] as num?)?.toDouble() ?? 0,
      withdrawn: (json['withdrawn'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WithdrawalItem {
  final String id;
  final double amount;
  final String status;
  final String? upiId;
  final DateTime requestedAt;
  final DateTime? completedAt;

  WithdrawalItem({
    required this.id,
    required this.amount,
    required this.status,
    this.upiId,
    required this.requestedAt,
    this.completedAt,
  });

  factory WithdrawalItem.fromJson(Map<String, dynamic> json) {
    return WithdrawalItem(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      upiId: json['upi_id'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}

class WalletData {
  final WalletBalance balance;
  final List<WithdrawalItem> recentWithdrawals;

  WalletData({
    required this.balance,
    required this.recentWithdrawals,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final withdrawals = (json['recent_withdrawals'] as List? ?? [])
        .map((item) => WithdrawalItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return WalletData(
      balance: WalletBalance.fromJson(json['balance'] as Map<String, dynamic>),
      recentWithdrawals: withdrawals,
    );
  }
}

class BankDetails {
  final String accountNumber;
  final String ifsc;
  final String accountHolderName;

  BankDetails({
    required this.accountNumber,
    required this.ifsc,
    required this.accountHolderName,
  });

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'ifsc': ifsc,
      'account_holder_name': accountHolderName,
    };
  }
}

class WithdrawalRequest {
  final double amount;
  final String method;
  final String? upiId;
  final BankDetails? bankDetails;

  WithdrawalRequest({
    required this.amount,
    required this.method,
    this.upiId,
    this.bankDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
      if (upiId != null) 'upi_id': upiId,
      if (bankDetails != null) 'bank_details': bankDetails!.toJson(),
    };
  }
}

class WithdrawalResponse {
  final String withdrawalId;
  final double amount;
  final String status;
  final String message;
  final DateTime requestedAt;

  WithdrawalResponse({
    required this.withdrawalId,
    required this.amount,
    required this.status,
    required this.message,
    required this.requestedAt,
  });

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalResponse(
      withdrawalId: json['withdrawal_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String? ?? '',
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }
}