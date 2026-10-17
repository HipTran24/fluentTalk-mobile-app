import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../primary_button.dart';

/// Permission Explainer Modal Sheet
/// Compliant with Appendix B2, B11 & B23
class PermissionRationaleSheet extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onGrant;
  final VoidCallback? onCancel;

  const PermissionRationaleSheet({
    super.key,
    this.title = 'Cho phép truy cập Microphone',
    this.description =
        'Để luyện phát âm và trò chuyện trực tiếp với gia sư AI, ứng dụng cần quyền sử dụng micro. Bạn có thể bật hoặc tắt quyền lưu trữ âm thanh bất kỳ lúc nào trong Cài đặt riêng tư.',
    this.icon = Icons.mic_rounded,
    required this.onGrant,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PermissionRationaleSheet(
        onGrant: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sheetRadius,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Cho phép sử dụng',
              icon: Icons.check,
              onPressed: onGrant,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: const Text(
                'Để sau',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
