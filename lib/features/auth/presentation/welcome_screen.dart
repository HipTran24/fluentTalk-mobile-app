import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

/// Public introduction. Only advertises capabilities available in this build.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.forum_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text('FluentTalk AI',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary))),
                    ]),
                    const SizedBox(height: 40),
                    const Text('Tiếng Anh cho\nnhững cuộc trò chuyện thật.',
                        style: TextStyle(
                            fontSize: 32,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    const Text(
                        'Khám phá tình huống phù hợp với mục tiêu và trình độ của bạn, từ A0 đến C2.',
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.55,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 28),
                    const _CatalogBenefit(
                      icon: Icons.explore_outlined,
                      title: 'Gần với cuộc sống của bạn',
                      description:
                          'Giới thiệu bản thân, đời sống, du lịch và công việc.',
                    ),
                    const _CatalogBenefit(
                      icon: Icons.tune_rounded,
                      title: 'Tìm đúng nội dung cần học',
                      description: 'Lọc theo chủ đề, cấp độ hoặc từ khóa.',
                    ),
                    const _CatalogBenefit(
                      icon: Icons.flag_outlined,
                      title: 'Chuẩn bị trước mỗi tình huống',
                      description:
                          'Xem vai trò, mục tiêu và từ vựng gợi ý trước khi luyện tập.',
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Khám phá tình huống',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.push('/practice/scenarios'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () => context.push('/auth?mode=signin'),
                      child:
                          const Text('Đăng nhập', textAlign: TextAlign.center),
                    ),
                    Center(
                        child: TextButton(
                      onPressed: () => context.push('/auth?mode=signup'),
                      child: const Text('Tạo tài khoản',
                          textAlign: TextAlign.center),
                    )),
                    const SizedBox(height: 8),
                    const Text(
                        'Bạn có thể xem danh mục trước khi đăng nhập. Hội thoại trực tuyến đang được tích hợp.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CatalogBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _CatalogBenefit(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary)),
                ],
              )),
            ],
          ),
        ),
      );
}
