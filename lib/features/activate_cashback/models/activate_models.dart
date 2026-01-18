/// Activate cashback response model
class ActivateCashbackResponse {
  final String deepLink;
  final String clickId;
  final String storeName;
  final String message;
  final DateTime? expiresAt;

  ActivateCashbackResponse({
    required this.deepLink,
    required this.clickId,
    required this.storeName,
    required this.message,
    this.expiresAt,
  });

  factory ActivateCashbackResponse.fromJson(Map<String, dynamic> json) {
    return ActivateCashbackResponse(
      deepLink: json['deep_link'] as String,
      clickId: json['click_id'] as String,
      storeName: json['store_name'] as String,
      message: json['message'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}
