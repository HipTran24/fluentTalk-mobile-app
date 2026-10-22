import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'controllers/auth_controller.dart';
import '../domain/auth_state.dart';

/// Screen 03 — Sign In / Sign Up / Password Recovery
/// Compliant with ESP-PLAN-001 Appendix B5 & AUTH-01..05
class AuthScreen extends ConsumerStatefulWidget {
  final String? initialMode;

  const AuthScreen({
    super.key,
    this.initialMode,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _agreeTerms = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Live Password Strength Checkers
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));

  @override
  void initState() {
    super.initState();
    final isSignUp = widget.initialMode == 'signup';
    _tabController = TabController(length: 2, vsync: this, initialIndex: isSignUp ? 1 : 0);
    _passwordController.addListener(() {
      if (_tabController.index == 1) {
        setState(() {}); // Re-render password checklist
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isSignUp = _tabController.index == 1;

    if (isSignUp && !_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản dịch vụ & Chính sách bảo mật.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    final controller = ref.read(authControllerProvider.notifier);

    if (isSignUp) {
      final success = await controller.signUp(
        email: email,
        password: password,
        displayName: name,
      );
      if (success && mounted) {
        context.go('/onboarding/goal');
      }
    } else {
      final success = await controller.signIn(
        email: email,
        password: password,
      );
      if (success && mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState.needsOnboarding) {
          context.go('/onboarding/goal');
        } else {
          context.go('/home');
        }
      }
    }
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSending = false;
    String? resetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: AppSpacing.pageHorizontal,
              right: AppSpacing.pageHorizontal,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.sheetRadius,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Khôi phục mật khẩu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhập email của bạn, chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: resetEmailController,
                  hintText: 'name@example.com',
                  label: 'Địa chỉ Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (resetError != null) ...[
                  const SizedBox(height: 6),
                  Text(resetError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  text: 'Gửi liên kết khôi phục',
                  isLoading: isSending,
                  onPressed: () async {
                    setModalState(() {
                      isSending = true;
                      resetError = null;
                    });
                    final email = resetEmailController.text.trim();
                    final success = await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
                    setModalState(() => isSending = false);

                    if (success && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi email khôi phục mật khẩu! Vui lòng kiểm tra hộp thư.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else if (ctx.mounted) {
                      setModalState(() {
                        resetError = ref.read(authControllerProvider).errorMessage ?? 'Không thể gửi email.';
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSignUp = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const AppLogoWordmark(logoSize: 28, fontSize: 17),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softBackdrop),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Greeting
                Text(
                  isSignUp ? 'Tạo tài khoản mới ✨' : 'Chào mừng trở lại 👋',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSignUp
                      ? 'Bắt đầu hành trình nói tiếng Anh — tạo tài khoản để cá nhân hóa lộ trình và lưu trữ lịch sử phản xạ.'
                      : 'Đăng nhập để tiếp tục các phiên luyện cùng AI Coach của bạn.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
                ),

                if (authState.isDemo) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'DEMO MODE: Chế độ dùng thử cục bộ (cách ly hoàn toàn)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                if (authState.isUnconfigured || authState.status == AuthStatus.error) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.errorMessage ??
                                'Dịch vụ xác thực Supabase chưa khả dụng. Vui lòng kiểm tra lại cấu hình hoặc kết nối mạng.',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).restoreSession(),
                          child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Top Tab Switcher: Đăng nhập / Đăng ký
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.inputLarge),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (idx) => setState(() {}),
                    indicator: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppRadius.input - 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandViolet.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Đăng nhập', height: 44),
                      Tab(text: 'Đăng ký tài khoản', height: 44),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Error Banner Display (Human-readable error)
                if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Input: Display Name (Sign Up only)
                if (isSignUp) ...[
                  AppTextField(
                    controller: _nameController,
                    label: 'Họ và tên của bạn',
                    hintText: 'VD: Nguyễn Minh Khoa',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập họ và tên của bạn.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Input: Email
                AppTextField(
                  controller: _emailController,
                  label: 'Địa chỉ Email',
                  hintText: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ email.';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Địa chỉ email không hợp lệ.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Input: Password
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hintText: isSignUp ? 'Tối thiểu 8 ký tự' : 'Nhập mật khẩu',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    if (isSignUp && val.length < 8) {
                      return 'Mật khẩu phải từ 8 ký tự trở lên.';
                    }
                    return null;
                  },
                ),

                // Password Strength Checklist Helper (Sign Up only)
                if (isSignUp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yêu cầu mật khẩu an toàn:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        _buildRequirementItem('Tối thiểu 8 ký tự', _hasMinLength),
                        _buildRequirementItem('Chứa ít nhất 1 chữ số (0-9)', _hasDigit),
                        _buildRequirementItem('Chứa ít nhất 1 chữ in hoa (A-Z)', _hasUppercase),
                      ],
                    ),
                  ),
                ],

                // Options Row: Remember Me & Forgot Password
                if (!isSignUp) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          ),
                          const Text(
                            'Ghi nhớ đăng nhập',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordSheet,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _agreeTerms,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _agreeTerms = val ?? true),
                      ),
                      const Expanded(
                        child: Text(
                          'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư của FluentTalk.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Primary Submit Button with Loading Double-submit protection
                PrimaryButton(
                  text: isSignUp ? 'Đăng ký tài khoản' : 'Đăng nhập',
                  isLoading: authState.isLoading,
                  icon: isSignUp ? Icons.person_add_alt_1 : Icons.login_rounded,
                  onPressed: _submit,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Switch Tab Link Bottom
                Center(
                  child: TextButton(
                    onPressed: () {
                      _tabController.animateTo(isSignUp ? 0 : 1);
                      setState(() {});
                    },
                    child: Text(
                      isSignUp ? 'Đã có tài khoản? Đăng nhập ngay' : 'Chưa có tài khoản? Đăng ký miễn phí',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? AppColors.success : AppColors.textMuted,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
