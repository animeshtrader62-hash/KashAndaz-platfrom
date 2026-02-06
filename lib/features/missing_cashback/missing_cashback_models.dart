class MissingCashbackRequest {
  final String id;
  final String storeId;
  final String storeName;
  final String orderId;
  final double orderAmount;
  final DateTime orderDate;
  final double? expectedCashback;
  final String? screenshotUrl;
  final String? notes;
  final String status;
  final String? adminComment;
  final DateTime createdAt;

  const MissingCashbackRequest({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.orderId,
    required this.orderAmount,
    required this.orderDate,
    required this.expectedCashback,
    required this.screenshotUrl,
    required this.notes,
    required this.status,
    required this.adminComment,
    required this.createdAt,
  });

  factory MissingCashbackRequest.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return MissingCashbackRequest(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      orderAmount: toDouble(json['order_amount']) ?? 0,
      orderDate: DateTime.tryParse(json['order_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      expectedCashback: toDouble(json['expected_cashback']),
      screenshotUrl: json['screenshot_url']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      adminComment: json['admin_comment']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
