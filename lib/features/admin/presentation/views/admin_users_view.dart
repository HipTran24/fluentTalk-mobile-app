import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:english_mobile_app/core/theme/app_colors.dart';
import 'package:english_mobile_app/core/theme/app_radius.dart';
import 'package:english_mobile_app/core/theme/app_spacing.dart';
import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_controller.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_state.dart';

class AdminUsersView extends StatelessWidget {
  final AdminState state;
  final AdminController controller;

  const AdminUsersView({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Danh bạ Học viên & Tiến độ (User Directory)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Theo dõi hoạt động, cấp độ và thời lượng thực hành của ${state.learners.length} học viên',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search & Filter Box
          _buildFilterBar(context),
          const SizedBox(height: AppSpacing.md),

          // User Table (Desktop) or User Cards (Mobile)
          if (isMobile)
            _buildMobileUserList(context)
          else
            _buildDesktopUserTable(context),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final levels = [
      {'id': 'all', 'label': 'Tất cả cấp độ'},
      {'id': 'a1', 'label': 'A1 - Beginner'},
      {'id': 'a2', 'label': 'A2 - Elementary'},
      {'id': 'b1', 'label': 'B1 - Intermediate'},
      {'id': 'b2', 'label': 'B2 - Upper-Int'},
      {'id': 'c1', 'label': 'C1 - Advanced'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (val) => controller.searchLearners(val),
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              hintText: 'Tìm kiếm theo tên hoặc email học viên...',
              hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.person_search_rounded, color: Color(0xFF94A3B8)),
              suffixIcon: state.userQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => controller.searchLearners(''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: levels.map((lvl) {
                final isSelected = state.userLevelFilter == lvl['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(lvl['label']!),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.35),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryLight : const Color(0xFF94A3B8),
                    ),
                    onSelected: (_) => controller.filterLearnersByLevel(lvl['id']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopUserTable(BuildContext context) {
    if (state.learners.isEmpty) {
      return _buildEmptyState();
    }

    final headerStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: const Color(0xFFCBD5E1),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
            columns: [
              DataColumn(label: Text('Học viên', style: headerStyle)),
              DataColumn(label: Text('Cấp độ', style: headerStyle)),
              DataColumn(label: Text('Mục tiêu', style: headerStyle)),
              DataColumn(label: Text('Số buổi học', style: headerStyle)),
              DataColumn(label: Text('Thời lượng nói', style: headerStyle)),
              DataColumn(label: Text('Streak', style: headerStyle)),
              DataColumn(label: Text('Trạng thái', style: headerStyle)),
              DataColumn(label: Text('Chi tiết', style: headerStyle)),
            ],
            rows: state.learners.map((u) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            u.name[0].toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primaryLight, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(u.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                            Text(u.email, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u.level.name.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primaryLight, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  DataCell(Text(u.goal.title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)))),
                  DataCell(Text('${u.totalSessions} buổi', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13))),
                  DataCell(Text('${u.voiceMinutes} phút', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFF97316)),
                        const SizedBox(width: 4),
                        Text('${u.streakDays} ngày', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: u.isActive,
                      activeColor: AppColors.accent,
                      onChanged: (_) => controller.toggleLearnerStatus(u.id),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
                      onPressed: () => _showUserDetail(context, u),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUserList(BuildContext context) {
    if (state.learners.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.learners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = state.learners[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      u.name[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                        Text(u.email, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u.level.name.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primaryLight, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF1E293B)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${u.totalSessions} buổi • ${u.voiceMinutes}p nói',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFF97316)),
                      Text(
                        '${u.streakDays} ngày',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: u.isActive,
                        activeColor: AppColors.accent,
                        onChanged: (_) => controller.toggleLearnerStatus(u.id),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_off_rounded, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            (state.userQuery.isNotEmpty || state.userLevelFilter != 'all')
                ? 'Không tìm thấy học viên'
                : 'Chưa có tài khoản học viên nào đăng ký',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            (state.userQuery.isNotEmpty || state.userLevelFilter != 'all')
                ? 'Thử tìm kiếm với từ khóa hoặc cấp độ khác'
                : 'Dữ liệu học viên sẽ tự động hiển thị tại đây khi người dùng đăng ký tài khoản trong ứng dụng.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context, AdminLearner u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1E293B))),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(u.name[0], style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
            ),
            const SizedBox(width: 10),
            Text(u.name, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${u.email}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Trình độ: ${u.level.name.toUpperCase()} • Mục tiêu: ${u.goal.title}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Tổng buổi luyện tập: ${u.totalSessions} buổi', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Thời lượng nói tích lũy: ${u.voiceMinutes} phút', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Chuỗi Streak: ${u.streakDays} ngày liên tiếp', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Trạng thái tài khoản: ${u.isActive ? "Hoạt động" : "Tạm khóa"}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
