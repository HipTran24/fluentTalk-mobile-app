import 'package:dio/dio.dart';

/// Safe application error. Raw HTTP bodies, credentials and provider exception
/// strings are deliberately excluded from diagnostic output and UI messages.
class ApiFailure implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;
  final bool canRetry;

  const ApiFailure({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
    this.canRetry = false,
  });

  factory ApiFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final payload = error.response?.data;
    final serverCode = payload is Map ? payload['code'] : null;
    final rawRequestId = payload is Map ? payload['requestId'] : null;
    final requestId = rawRequestId is String &&
            RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(rawRequestId)
        ? rawRequestId
        : null;
    final cancelled = error.type == DioExceptionType.cancel;
    final badCertificate = error.type == DioExceptionType.badCertificate;
    final connectionError = error.type == DioExceptionType.connectionError;
    final timeout = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
    final code = cancelled
        ? 'CANCELLED'
        : badCertificate
            ? 'TLS_ERROR'
            : timeout
                ? 'TIMEOUT'
                : status == 401
                    ? 'UNAUTHENTICATED'
                    : status == 403
                        ? serverCode == 'ACCOUNT_SUSPENDED'
                            ? 'ACCOUNT_SUSPENDED'
                            : 'FORBIDDEN'
                        : status == 404
                            ? 'NOT_FOUND'
                            : status == 409
                                ? 'CONFLICT'
                                : status == 429
                                    ? 'QUOTA_EXCEEDED'
                                    : status == null
                                        ? connectionError
                                            ? 'NETWORK_ERROR'
                                            : 'TRANSPORT_ERROR'
                                        : serverCode is String &&
                                                RegExp(r'^[A-Z_]{1,64}$')
                                                    .hasMatch(serverCode)
                                            ? serverCode
                                            : 'SERVER_ERROR';
    return ApiFailure(
      code: code,
      message: switch (code) {
        'CANCELLED' => 'Yêu cầu đã dừng.',
        'TIMEOUT' => 'Kết nối quá thời gian. Bạn có thể thử lại.',
        'UNAUTHENTICATED' => 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
        'ACCOUNT_SUSPENDED' =>
          'Tài khoản đang bị tạm khóa. Vui lòng liên hệ quản trị viên.',
        'FORBIDDEN' => 'Bạn không có quyền thực hiện thao tác này.',
        'NOT_FOUND' => 'Không tìm thấy nội dung này.',
        'CONFLICT' => 'Yêu cầu xung đột. Hãy tải lại trước khi tiếp tục.',
        'AI_NOT_CONFIGURED' => 'Dịch vụ Tom chưa được cấu hình trên máy chủ.',
        'AI_ACCESS_DENIED' =>
          'API key hoặc quyền truy cập Gemini Live chưa hợp lệ. Kiểm tra cấu hình máy chủ.',
        'AI_RATE_LIMITED' =>
          'Gemini đã hết hạn mức hoặc đang quá tải. Kiểm tra quota/billing rồi thử lại.',
        'AI_UNAVAILABLE' => 'Chưa kết nối được Gemini. Vui lòng thử lại sau.',
        'AI_TIMEOUT' =>
          'Tom phản hồi quá lâu. Bạn có thể thử lại cùng tin nhắn.',
        'AI_INVALID_RESPONSE' =>
          'Tom chưa trả về phản hồi hợp lệ. Hãy thử lại.',
        'MODE_UNAVAILABLE' => 'Chế độ luyện tập này chưa sẵn sàng.',
        'IDEMPOTENCY_STATE_UNAVAILABLE' =>
          'Chưa khôi phục được kết quả cũ. Không gửi lượt mới.',
        'QUOTA_EXCEEDED' => 'Bạn đã đạt giới hạn sử dụng. Hãy thử lại sau.',
        'NETWORK_ERROR' => 'Không thể kết nối. Hãy kiểm tra mạng và thử lại.',
        'TLS_ERROR' => 'Không thể xác minh kết nối an toàn tới máy chủ.',
        _ when status == 400 => 'Dữ liệu chưa hợp lệ. Hãy kiểm tra và thử lại.',
        _ => 'Dịch vụ tạm thời chưa sẵn sàng. Hãy thử lại sau.',
      },
      statusCode: status,
      requestId: requestId,
      canRetry: !cancelled &&
          !badCertificate &&
          (timeout || connectionError || status == 502 || status == 503),
    );
  }

  @override
  String toString() =>
      'ApiFailure($code${requestId == null ? '' : ', $requestId'})';
}
