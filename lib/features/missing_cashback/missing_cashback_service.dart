import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/utils/constants.dart';
import 'missing_cashback_models.dart';

class MissingCashbackCreateRequest {
  final String storeId;
  final String orderId;
  final double orderAmount;
  final DateTime orderDate;
  final double? expectedCashback;
  final String? notes;
  final String? screenshotFileName;
  final Uint8List? screenshotBytes;
  final String? screenshotPath;

  const MissingCashbackCreateRequest({
    required this.storeId,
    required this.orderId,
    required this.orderAmount,
    required this.orderDate,
    required this.expectedCashback,
    required this.notes,
    required this.screenshotFileName,
    required this.screenshotBytes,
    required this.screenshotPath,
  });
}

class MissingCashbackService {
  final ApiClient _apiClient;

  MissingCashbackService(this._apiClient);

  Future<MissingCashbackRequest> create(MissingCashbackCreateRequest req) async {
    final formData = FormData.fromMap({
      'store_id': req.storeId,
      'order_id': req.orderId,
      'order_amount': req.orderAmount,
      'order_date': _toDateOnly(req.orderDate),
      if (req.expectedCashback != null) 'expected_cashback': req.expectedCashback,
      if (req.notes != null && req.notes!.trim().isNotEmpty) 'notes': req.notes!.trim(),
    });

    final hasScreenshot =
        (kIsWeb && req.screenshotBytes != null) || (!kIsWeb && req.screenshotPath != null && req.screenshotPath!.isNotEmpty);

    if (hasScreenshot) {
      formData.files.add(
        MapEntry(
          'screenshot',
          kIsWeb
              ? MultipartFile.fromBytes(
                  req.screenshotBytes!,
                  filename: req.screenshotFileName ?? 'screenshot.jpg',
                )
              : await MultipartFile.fromFile(
                  req.screenshotPath!,
                  filename: req.screenshotFileName,
                ),
        ),
      );
    }

    final res = await _apiClient.post(
      ApiConstants.missingCashback,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return MissingCashbackRequest.fromJson(data);
    }
    throw Exception('Unexpected response from server');
  }

  Future<List<MissingCashbackRequest>> myRequests({CancelToken? cancelToken}) async {
    final res = await _apiClient.get(ApiConstants.missingCashbackMy, cancelToken: cancelToken);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => MissingCashbackRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Unexpected response from server');
  }

  String _toDateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
