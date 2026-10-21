import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_logo.dart';
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
      backgroundColor: AppColors.brandIndigo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradientVivid),
        child: Stack(
          children: [
            // Decorative glowing orbs
            Positioned(top: -80, right: -60, child: _orb(260, 0.10)),
            Positioned(bottom: -120, left: -80, child: _orb(320, 0.08)),
            Positioned(top: 140, left: -40, child: _orb(110, 0.06)),
            SafeArea(
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const AppLogo(size: 76, withShadow: false),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Brand Title & Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandWordmark(fontSize: 36, onDark: true),
                        SizedBox(width: 8),
                        _AiPill(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Speak with confidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.4,
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
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadiusLarge,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.errorBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage ?? 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Đang đồng bộ dữ liệu phiên học...',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _AiPill extends StatelessWidget {
  const _AiPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.brandAmber,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF3B0764),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
