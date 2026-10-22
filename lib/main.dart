import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_content_wrapper.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  String? supabaseInitError;
  if (config.hasAuth) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
      );
    } catch (_) {
      supabaseInitError =
          'Không thể khởi tạo dịch vụ xác thực Supabase. Vui lòng kiểm tra lại cấu hình hoặc kết nối mạng.';
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseInitErrorProvider.overrideWithValue(supabaseInitError),
      ],
      child: const FluentTalkApp(),
    ),
  );
}

/// Root Application Widget
/// Compliant with ESP-PLAN-001 Foundation
class FluentTalkApp extends ConsumerWidget {
  const FluentTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final demoMode = ref.watch(appConfigProvider).demoMode;
    return MaterialApp.router(
      title: 'FluentTalk Tom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Screens are designed around light-mode tokens; force light for a consistent look.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!demoMode) return child;
        return ResponsiveContentWrapper(
          backgroundColor: const Color(0xFF0F172A),
          child: Semantics(
            container: true,
            label: 'Chế độ demo, dữ liệu minh họa',
            child: Banner(
              message: 'DEMO',
              location: BannerLocation.topEnd,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
