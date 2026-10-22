import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'primary_button.dart';

/// Reusable Error & Offline State Widget with Retry
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isOffline;

  const ErrorStateWidget({
    super.key,
    this.title = 'Đã có lỗi xảy ra',
    this.message = 'Không thể tải dữ liệu vào lúc này. Vui lòng thử lại.',
    this.onRetry,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOffline ? AppColors.warningBg : AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 48,
                color: isOffline ? AppColors.warning : AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isOffline ? 'Không có kết nối mạng' : title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isOffline
                  ? 'Vui lòng kiểm tra lại kết nối Wi-Fi hoặc 4G/5G trên thiết bị của bạn.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Thử lại',
                icon: Icons.refresh,
                onPressed: onRetry,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
