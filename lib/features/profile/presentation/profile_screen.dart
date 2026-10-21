import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/sheets/confirm_sheet.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';

/// Screen 20 — Profile / Settings / Privacy
/// Compliant with ESP-PLAN-001 Appendix B22 & Privacy Safeguards
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final settings = ref.watch(profileSettingsControllerProvider);
    final settingsController = ref.read(profileSettingsControllerProvider.notifier);

    final user = authState.user;
    final userName = (user?.displayName.isNotEmpty == true) ? user!.displayName : 'Lê Nam';
    final userEmail = (user?.email.isNotEmpty == true) ? user!.email : 'nam.le@example.com';
    final userLevel = user?.level ?? UserLevel.a2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cá nhân & Cài đặt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Identity Card
              _buildUserCard(context, userName, userEmail, userLevel),

              const SizedBox(height: AppSpacing.lg),

              // 2. Vocabulary Notebook Shortcut Tile
              _buildVocabularyTile(context),

              const SizedBox(height: AppSpacing.lg),

              // 3. AI Voice & Speech Preferences
              _buildSectionTitle('Cấu hình gia sư AI & Âm thanh'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
                  title: const Text('Giọng nói AI Coach'),
                  subtitle: Text(settings.voiceName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    settingsController.setVoice(
                      settings.voiceName.contains('Nữ')
                          ? 'Giọng Nam trầm ấm (Journey-D)'
                          : 'Giọng Nữ chuẩn Anh - Mỹ (Journey-F)',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed_rounded, color: AppColors.primary),
                  title: const Text('Tốc độ đọc AI mặc định'),
                  subtitle: const Text('Áp dụng cho mọi câu thoại của gia sư'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${settings.defaultSpeed}x',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  onTap: () {
                    final nextSpeed = settings.defaultSpeed == 1.0 ? 1.25 : (settings.defaultSpeed == 1.25 ? 0.75 : 1.0);
                    settingsController.setDefaultSpeed(nextSpeed);
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              // 4. Notifications & Audio Privacy
              _buildSectionTitle('Thông báo & Quyền riêng tư (Audio Consent)'),
              _buildSettingsCard([
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                  title: const Text('Nhắc nhở học hàng ngày'),
                  subtitle: const Text('Thông báo lúc 20:00 để duy trì chuỗi Streak'),
                  value: settings.notifications,
                  onChanged: (val) => settingsController.setNotifications(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mic_none_rounded, color: AppColors.accent),
                  title: const Text('Lưu trữ file ghi âm (Audio Consent)'),
                  subtitle: const Text('Chỉ lưu tạm để bạn nghe lại, tự động xóa sau 30 ngày'),
                  value: settings.audioConsent,
                  onChanged: (val) => settingsController.setAudioConsent(val),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.warning),
                  title: const Text('Xóa toàn bộ bản ghi âm đã lưu'),
                  subtitle: const Text('Xóa sạch âm thanh khỏi bộ nhớ thiết bị'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final confirmed = await ConfirmSheet.show(
                      context,
                      title: 'Xóa toàn bộ ghi âm?',
                      message: 'Tất cả các tệp âm thanh giọng nói của bạn sẽ được xóa vĩnh viễn khỏi thiết bị.',
                      confirmText: 'Xóa vĩnh viễn',
                      isDestructive: true,
                    );
                    if (context.mounted && confirmed == true) {
                      await settingsController.deleteAllRecordings();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa sạch các bản ghi âm thành công.')),
                        );
                      }
                    }
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              // 4.5. Admin Console (Web & Mobile)
              _buildSectionTitle('Quản trị viên & Vận hành (Admin)'),
              _buildSettingsCard([
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent, size: 20),
                  ),
                  title: const Text('Bảng Điều hành Admin', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('KPI, Scenario CMS, Học viên & Cấu hình AI', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  onTap: () => context.push('/admin'),
                ),
              ]),

              const SizedBox(height: AppSpacing.lg),

              // 5. Account & Sign Out
              _buildSectionTitle('Tài khoản'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.textSecondary),
                  title: const Text('Đổi mật khẩu'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng kiểm tra email để đặt lại mật khẩu.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final confirmed = await ConfirmSheet.show(
                      context,
                      title: 'Đăng xuất tài khoản?',
                      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục đồng bộ tiến trình học tập.',
                      confirmText: 'Đăng xuất',
                      isDestructive: true,
                    );
                    if (context.mounted && confirmed == true) {
                      await authNotifier.signOut();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    }
                  },
                ),
              ]),

              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, String name, String email, UserLevel level) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.secondaryLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LevelChip(level: level),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: AppColors.secondaryLight,
          child: Icon(Icons.bookmark_outline_rounded, color: AppColors.primary),
        ),
        title: const Text(
          'Sổ tay từ vựng & Mẫu câu',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        subtitle: const Text(
          'Xem các biểu đạt bạn đã lưu trong khi giao tiếp',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        onTap: () => context.push('/profile/vocabulary'),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}
