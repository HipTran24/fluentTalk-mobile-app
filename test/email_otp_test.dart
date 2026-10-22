import 'package:english_mobile_app/features/auth/data/email_otp_gateway.dart';
import 'package:english_mobile_app/features/auth/presentation/email_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeOtpGateway extends EmailOtpGateway {
  int verifications = 0;
  int resends = 0;
  String? email;
  String? code;
  @override
  Future<void> verify(String email, String code) async {
    verifications++;
    this.email = email;
    this.code = code;
    throw const AuthException('expired', code: 'otp_expired');
  }

  @override
  Future<void> resend(String email) async {
    resends++;
  }
}

void main() {
  testWidgets('validates locally, sends exact code and shows expired error',
      (tester) async {
    final gateway = FakeOtpGateway();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          emailOtpGatewayProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(
            home: EmailOtpScreen(email: 'learner@example.test'))));
    final submit = find.text('Xác thực và tiếp tục');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(gateway.verifications, 0);
    expect(
        find.text('Nhập đủ mã gồm 6–10 chữ số trong email.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('email-otp-input')), '123456');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(gateway.verifications, 1);
    expect(gateway.email, 'learner@example.test');
    expect(gateway.code, '123456');
    expect(
        find.textContaining('Mã không đúng hoặc đã hết hạn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resend is blocked for 60 seconds then starts a new cooldown',
      (tester) async {
    final gateway = FakeOtpGateway();
    var now = DateTime(2026);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          emailOtpGatewayProvider.overrideWithValue(gateway),
          otpClockProvider.overrideWithValue(() => now)
        ],
        child: const MaterialApp(
            home: EmailOtpScreen(email: 'learner@example.test'))));
    final initial = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Gửi lại mã sau 60s'));
    expect(initial.onPressed, isNull);
    now = now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));
    final resend = find.text('Chưa nhận được mã? Gửi lại');
    await tester.ensureVisible(resend);
    await tester.tap(resend);
    await tester.pump();
    expect(gateway.resends, 1);
    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('320dp at 200 percent with keyboard remains scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(320, 640),
                    textScaler: TextScaler.linear(2),
                    viewInsets: EdgeInsets.only(bottom: 280)),
                child: EmailOtpScreen(
                    email: 'very.long.email.address@example.test')))));
    await tester.ensureVisible(find.text('Quay lại / đổi email'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
