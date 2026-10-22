import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final emailOtpGatewayProvider =
    Provider<EmailOtpGateway>((ref) => EmailOtpGateway());

/// Supabase owns code generation, expiry, replay protection and rate limiting.
class EmailOtpGateway {
  Future<void> verify(String email, String code) async {
    final response = await Supabase.instance.client.auth.verifyOTP(
      email: email.trim(),
      token: code,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw const AuthException(
          'Không thể tạo phiên đăng nhập. Vui lòng thử lại.');
    }
  }

  Future<void> resend(String email) async {
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }
}

String otpErrorMessage(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'otp_expired':
      case 'access_denied':
        return 'Mã không đúng hoặc đã hết hạn. Hãy kiểm tra email hoặc gửi lại mã.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Bạn thao tác quá nhanh. Vui lòng đợi rồi thử lại.';
      case 'email_provider_disabled':
      case 'email_address_not_authorized':
        return 'Dịch vụ gửi email chưa sẵn sàng. Vui lòng liên hệ hỗ trợ.';
      default:
        return 'Không thể xác thực hoặc gửi email. Kiểm tra mã và thử lại sau.';
    }
  }
  return 'Không thể kết nối. Kiểm tra mạng rồi thử lại.';
}
