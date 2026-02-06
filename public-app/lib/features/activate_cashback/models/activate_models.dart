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
    final deepLinkValue =
        (json['affiliate_redirect_url'] ?? json['deep_link'] ?? '').toString();
    return ActivateCashbackResponse(
      deepLink: deepLinkValue,
      clickId: (json['click_id'] ?? '').toString(),
      storeName: (json['store_name'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }
}
