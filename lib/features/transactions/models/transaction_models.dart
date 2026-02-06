/// Transaction status enum
enum TransactionStatus {
  pending,
  confirmed,
  cancelled,
  paid;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.paid:
        return 'Paid';
    }
  }

  static TransactionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TransactionStatus.pending;
      case 'confirmed':
        return TransactionStatus.confirmed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'paid':
        return TransactionStatus.paid;
      default:
        return TransactionStatus.pending;
    }
  }
}

/// Transaction model
class Transaction {
  final String id;
  final String storeName;
  final String? storeLogo;
  final String orderId;
  final double purchaseAmount;
  final double cashbackAmount;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? paidAt;

  Transaction({
    required this.id,
    required this.storeName,
    this.storeLogo,
    required this.orderId,
    required this.purchaseAmount,
    required this.cashbackAmount,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.paidAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      storeName: json['store_name'] as String,
      storeLogo: json['store_logo'] as String?,
      orderId: json['order_id'] as String,
      purchaseAmount: (json['purchase_amount'] as num).toDouble(),
      cashbackAmount: (json['cashback_amount'] as num).toDouble(),
      status: TransactionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'store_logo': storeLogo,
      'order_id': orderId,
      'purchase_amount': purchaseAmount,
      'cashback_amount': cashbackAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

/// Transaction detail model (with more information)
class TransactionDetail extends Transaction {
  final String clickId;
  final String cashbackRate;
  final String statusDescription;
  final String? cancelledReason;

  TransactionDetail({
    required super.id,
    required super.storeName,
    super.storeLogo,
    required super.orderId,
    required super.purchaseAmount,
    required super.cashbackAmount,
    required super.status,
    required super.createdAt,
    super.confirmedAt,
    super.paidAt,
    required this.clickId,
    required this.cashbackRate,
    required this.statusDescription,
    this.cancelledReason,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] as String,
      storeName: json['store_name'] as String,
      storeLogo: json['store_logo'] as String?,
      orderId: json['order_id'] as String,
      purchaseAmount: (json['purchase_amount'] as num).toDouble(),
      cashbackAmount: (json['cashback_amount'] as num).toDouble(),
      status: TransactionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      clickId: json['click_id'] as String,
      cashbackRate: json['cashback_rate'] as String,
      statusDescription: json['status_description'] as String,
      cancelledReason: json['cancelled_reason'] as String?,
    );
  }
}
