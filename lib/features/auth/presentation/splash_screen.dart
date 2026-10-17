import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';
import 'controllers/auth_controller.dart';
import '../domain/auth_state.dart';

/// Screen 01 — Splash & Session Restoration
/// Compliant with ESP-PLAN-001 Appendix B3 & AUTH-05
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _hasTimeoutError = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _initSessionCheck();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initSessionCheck() async {
    setState(() => _hasTimeoutError = false);
    // Allow animation to play smoothly
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).restoreSession();

      if (!mounted) return;
      final authState = ref.read(authControllerProvider);

      switch (authState.status) {
        case AuthStatus.authenticated:
          context.go('/home');
          break;
        case AuthStatus.needsOnboarding:
          context.go('/onboarding/goal');
          break;
        case AuthStatus.unauthenticated:
          context.go('/welcome');
          break;
        case AuthStatus.error:
          setState(() => _hasTimeoutError = true);
          break;
        default:
          context.go('/welcome');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasTimeoutError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Brand Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Brand Title & Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'FluentTalk AI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Speak with confidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom State Indicators: Loading vs Network Error / Timeout
              if (_hasTimeoutError || authState.status == AuthStatus.error) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage ?? 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        text: 'Thử lại',
                        icon: Icons.refresh_rounded,
                        onPressed: _initSessionCheck,
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => context.go('/welcome'),
                        child: const Text('Bỏ qua & Tiếp tục ngoại tuyến'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ] else ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Đang đồng bộ dữ liệu phiên học...',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
