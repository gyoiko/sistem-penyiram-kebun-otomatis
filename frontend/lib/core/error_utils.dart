import 'package:dio/dio.dart';

String describeApiError(Object error) {
  if (error is DioException) {
    final response = error.response;
    final payload = response?.data;

    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      if (message is String && message.isNotEmpty) return message;
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Server tidak dapat dijangkau. Pastikan backend Laravel berjalan.';
    }

    return error.message ?? 'Terjadi kesalahan jaringan.';
  }

  return error.toString();
}
