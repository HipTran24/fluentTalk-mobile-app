import 'package:english_mobile_app/features/conversation/presentation/live_voice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'call starts only on explicit tap and no fake transcripts are displayed',
      (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LiveVoiceScreen())));
    expect(find.text('Bắt đầu nói chuyện'), findsOneWidget);
    expect(find.text('Phụ đề trực tiếp'), findsNothing);
    expect(find.text('Đang kết nối…'), findsNothing);
    expect(find.textContaining('âm thanh micro được gửi đến Google'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Bắt đầu nói chuyện'));
    await tester.tap(find.text('Bắt đầu nói chuyện'));
    await tester.pump();
    expect(find.text('Chưa cấu hình kết nối máy chủ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      '320dp with 200 percent type has reachable call button and voice selector',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(320, 640), textScaler: TextScaler.linear(2)),
                child: LiveVoiceScreen()))));
    await tester.ensureVisible(find.text('Bắt đầu nói chuyện'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
