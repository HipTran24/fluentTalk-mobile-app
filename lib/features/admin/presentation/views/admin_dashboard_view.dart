import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:english_mobile_app/core/theme/app_colors.dart';
import 'package:english_mobile_app/core/theme/app_radius.dart';
import 'package:english_mobile_app/core/theme/app_spacing.dart';
import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_controller.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_state.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/scenario_editor_dialog.dart';

class AdminDashboardView extends StatelessWidget {
  final AdminState state;
  final AdminController controller;

  const AdminDashboardView({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final kpi = state.kpiSummary;
    if (kpi == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trung tâm Điều hành & Đo lường KPI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? 'Cập nhật thời gian thực từ Gemini Gateway'
                          : 'Cập nhật thời gian thực từ Gemini Live Gateway & Hệ thống học tập',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                ElevatedButton.icon(
                  onPressed: () {
                    ScenarioEditorDialog.show(
                      context,
                      onSave: (scenario) => controller.saveScenario(scenario),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Thêm Kịch bản mới', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4 Executive KPI Cards (Responsive Grid)
          _buildKpiGrid(context, kpi, isMobile, isDesktop),
          const SizedBox(height: AppSpacing.xl),

          // Analytics Charts & Live Activity Feed (Side by side on desktop, stacked on mobile)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildWeeklyTrendCard(kpi)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 2, child: _buildLiveActivityFeed(kpi)),
              ],
            )
          else ...[
            _buildWeeklyTrendCard(kpi),
            const SizedBox(height: AppSpacing.lg),
            _buildLiveActivityFeed(kpi),
          ],
          const SizedBox(height: AppSpacing.xl),

          // Quick System Action Bar
          _buildQuickActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, AdminKpiSummary kpi, bool isMobile, bool isDesktop) {
    final cards = [
      AdminKpiCard(
        title: 'Tổng số Học viên',
        value: '${kpi.totalLearners}',
        subtitle: '${kpi.activeSessionsToday} học viên đang hoạt động',
        icon: Icons.people_alt_rounded,
        iconColor: AppColors.primaryLight,
        iconBgColor: AppColors.primary.withOpacity(0.2),
        growthText: kpi.totalLearners > 0 ? '+${kpi.learnerGrowthPct.toInt()}% MoM' : 'Khởi tạo',
        isPositiveGrowth: true,
      ),
      AdminKpiCard(
        title: 'Thời lượng Nói tích lũy',
        value: '${kpi.totalVoiceMinutes} phút',
        subtitle: 'Thời lượng thực hành thực tế',
        icon: Icons.mic_rounded,
        iconColor: AppColors.accent,
        iconBgColor: AppColors.accent.withOpacity(0.2),
        growthText: '+${kpi.voiceGrowthPct.toInt()}%',
        isPositiveGrowth: true,
      ),
      AdminKpiCard(
        title: 'Phiên thực hành hôm nay',
        value: '${kpi.activeSessionsToday}',
        subtitle: 'Cuộc gọi thoại & lượt Guided',
        icon: Icons.headset_mic_rounded,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.warning.withOpacity(0.2),
        growthText: 'Thời gian thực',
        isPositiveGrowth: true,
      ),
      AdminKpiCard(
        title: 'Mức tiêu thụ Token Gemini',
        value: kpi.geminiTokensUsed,
        subtitle: 'Hạn mức tháng: 5.0M Tokens',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFA855F7),
        iconBgColor: const Color(0xFFA855F7).withOpacity(0.2),
        growthText: 'Tối ưu',
        isPositiveGrowth: true,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else if (MediaQuery.of(context).size.width >= 600) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      );
    } else {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _buildWeeklyTrendCard(AdminKpiSummary kpi) {
    final rawMax = kpi.weeklyTrends.isEmpty
        ? 0
        : kpi.weeklyTrends.map((e) => e.voiceMinutes).reduce((a, b) => a > b ? a : b);
    final maxMinutes = rawMax > 0 ? rawMax : 60;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Thời lượng Luyện nói 7 ngày',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tổng 7 ngày: ${kpi.totalVoiceMinutes} phút',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: kpi.weeklyTrends.map((metric) {
                final barRatio = rawMax > 0 ? (metric.voiceMinutes / (maxMinutes * 1.15)) : 0.08;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${metric.voiceMinutes}p',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 120 * barRatio,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.dayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveActivityFeed(AdminKpiSummary kpi) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nhật ký Hoạt động Trực tiếp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kpi.recentActivities.length,
            separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFF1E293B)),
            itemBuilder: (context, index) {
              final act = kpi.recentActivities[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: act.type == 'session'
                        ? AppColors.primary.withOpacity(0.2)
                        : act.type == 'signup'
                            ? AppColors.accent.withOpacity(0.2)
                            : AppColors.warning.withOpacity(0.2),
                    child: Icon(
                      act.type == 'session'
                          ? Icons.call_made_rounded
                          : act.type == 'signup'
                              ? Icons.person_add_rounded
                              : Icons.auto_awesome_rounded,
                      size: 16,
                      color: act.type == 'session'
                          ? AppColors.primaryLight
                          : act.type == 'signup'
                              ? AppColors.accent
                              : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          act.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    act.timeAgo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Thao tác Quản trị nhanh:',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScenarioEditorDialog.show(
                context,
                onSave: (scenario) => controller.saveScenario(scenario),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: Text('Thêm Kịch bản mới', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              controller.switchTab(3); // Go to AI Config
            },
            icon: const Icon(Icons.settings_suggest_rounded, size: 16),
            label: Text('Điều chỉnh Prompt AI', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao lưu nhật ký hệ thống ra file audit_log.json')),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Xuất Báo cáo CSV/JSON', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
