import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/providers.dart';
import 'missing_cashback_models.dart';
import 'missing_cashback_service.dart';

final missingCashbackServiceProvider = Provider<MissingCashbackService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MissingCashbackService(apiClient);
});

final myMissingCashbackProvider = FutureProvider.autoDispose<List<MissingCashbackRequest>>((ref) async {
  final service = ref.watch(missingCashbackServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return service.myRequests(cancelToken: cancelToken);
});
