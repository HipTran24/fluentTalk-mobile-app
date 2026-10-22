import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../data/email_otp_gateway.dart';
import 'controllers/auth_controller.dart';

final otpClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// A single accessible field supports paste and platform OTP autofill.
class EmailOtpScreen extends ConsumerStatefulWidget {
  const EmailOtpScreen({super.key, this.email});
  final String? email;
  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  Timer? _timer;
  DateTime? _resendAt;
  bool _busy = false;
  String? _error;
  String? _notice;
  String get _email =>
      widget.email ??
      ref.read(authControllerProvider).pendingConfirmationEmail ??
      '';
  int get _seconds => _resendAt == null
      ? 0
      : (_resendAt!.difference(ref.read(otpClockProvider)()).inMilliseconds /
              1000)
          .ceil()
          .clamp(0, 60);

  @override
  void initState() {
    super.initState();
    _cooldown();
  }

  void _cooldown() {
    _resendAt = ref.read(otpClockProvider)().add(const Duration(seconds: 60));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(emailOtpGatewayProvider).verify(_email, _code.text.trim());
      if (!mounted) return;
      _code.clear();
      await ref.read(authControllerProvider.notifier).restoreSession();
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated || auth.needsOnboarding) {
        context.go(auth.needsOnboarding ? '/onboarding/goal' : '/home');
      } else {
        setState(() => _error = 'Email đã xác thực. Hãy quay lại đăng nhập.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = otpErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _seconds > 0) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(emailOtpGatewayProvider).resend(_email);
      if (!mounted) return;
      setState(() {
        _notice = 'Đã yêu cầu gửi lại mã. Kiểm tra cả thư mục Spam.';
        _code.clear();
        _cooldown();
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = otpErrorMessage(error);
          _cooldown();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = _email.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const AppLogoWordmark(logoSize: 28, fontSize: 17)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softBackdrop),
        child: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.secondaryLight,
                        child: Icon(Icons.mark_email_read_outlined,
                            size: 38, color: AppColors.primary)),
                    const SizedBox(height: 24),
                    const Text('Xác thực email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Text(
                        hasEmail
                            ? 'Nhập mã trong email xác nhận gửi đến'
                            : 'Hãy đăng ký tài khoản để nhận mã xác thực.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.5)),
                    if (hasEmail) ...[
                      const SizedBox(height: 8),
                      Text(_email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: const Key('email-otp-input'),
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10)
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6),
                        decoration: InputDecoration(
                            labelText: 'Mã xác thực',
                            hintText: 'Nhập mã OTP',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16))),
                        validator: (value) =>
                            RegExp(r'^\d{6,10}$').hasMatch(value ?? '')
                                ? null
                                : 'Nhập đủ mã gồm 6–10 chữ số trong email.',
                        onFieldSubmitted: (_) => _verify(),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.error))),
                      if (_notice != null)
                        Semantics(
                            liveRegion: true,
                            child: Text(_notice!,
                                style:
                                    const TextStyle(color: AppColors.success))),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          onPressed: _busy ? null : _verify,
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.all(18)),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.verified_user_outlined),
                          label: Text(
                              _busy ? 'Đang xử lý…' : 'Xác thực và tiếp tục')),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _busy || _seconds > 0 ? null : _resend,
                          child: Text(_seconds > 0
                              ? 'Gửi lại mã sau ${_seconds}s'
                              : 'Chưa nhận được mã? Gửi lại')),
                      const SizedBox(height: 12),
                      const Text(
                          'Kiểm tra thư mục Spam. Nếu nhận nhiều email, hãy dùng mã mới nhất. Không chia sẻ mã với người khác.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, height: 1.5)),
                    ],
                    const SizedBox(height: 20),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.go('/auth?mode=signup'),
                        child: const Text('Quay lại / đổi email')),
                  ],
                )),
          )),
        )),
      ),
    );
  }
}
