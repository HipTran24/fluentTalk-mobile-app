import 'package:flutter/material.dart';
import 'package:english_mobile_app/core/theme/app_colors.dart';
import 'package:english_mobile_app/core/theme/app_radius.dart';
import 'package:english_mobile_app/core/theme/app_spacing.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_controller.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_state.dart';
import '../widgets/scenario_editor_dialog.dart';

class AdminScenariosView extends StatelessWidget {
  final AdminState state;
  final AdminController controller;

  const AdminScenariosView({
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
          // Header & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMobile
                          ? 'Scenario CMS'
                          : 'Quản lý Danh mục Kịch bản (Scenario CMS)',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đang có ${state.scenarios.length} kịch bản trong kho dữ liệu',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ScenarioEditorDialog.show(
                    context,
                    onSave: (scenario) => controller.saveScenario(scenario),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  isMobile ? 'Thêm' : 'Thêm Kịch bản mới',
                  style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search & Filter Bar
          _buildFilterBar(context),
          const SizedBox(height: AppSpacing.md),

          // Content List: Responsive Table (Desktop) or Card List (Mobile)
          if (isMobile)
            _buildMobileCardsList(context)
          else
            _buildDesktopDataTable(context),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final topics = [
      {'id': 'all', 'label': 'Tất cả chủ đề'},
      {'id': 'travel', 'label': 'Du lịch & Khách sạn'},
      {'id': 'daily', 'label': 'Đời sống thường nhật'},
      {'id': 'career', 'label': 'Công việc & Phỏng vấn'},
      {'id': 'exam', 'label': 'Luyện thi chứng chỉ'},
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
          // Search Input
          TextField(
            onChanged: (val) => controller.searchScenarios(val),
            style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.white,
                fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              hintText:
                  'Tìm kiếm theo tên tình huống, vai trò Tom hoặc người dùng...',
              hintStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: Color(0xFF64748B),
                  fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
              suffixIcon: state.scenarioQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Color(0xFF94A3B8)),
                      onPressed: () => controller.searchScenarios(''),
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Topic Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: topics.map((t) {
                final isSelected = state.scenarioTopicFilter == t['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t['label']!),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.35),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryLight
                          : const Color(0xFF94A3B8),
                    ),
                    onSelected: (_) =>
                        controller.filterScenariosByTopic(t['id']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable(BuildContext context) {
    if (state.scenarios.isEmpty) {
      return _buildEmptyState();
    }

    const headerStyle = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: Color(0xFFCBD5E1),
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
            columns: const [
              DataColumn(label: Text('Tiêu đề Kịch bản', style: headerStyle)),
              DataColumn(label: Text('Chủ đề', style: headerStyle)),
              DataColumn(label: Text('CEFR', style: headerStyle)),
              DataColumn(label: Text('Vai Tom / Học viên', style: headerStyle)),
              DataColumn(label: Text('Lượt học', style: headerStyle)),
              DataColumn(label: Text('Điểm TB', style: headerStyle)),
              DataColumn(label: Text('Trạng thái', style: headerStyle)),
              DataColumn(label: Text('Thao tác', style: headerStyle)),
            ],
            rows: state.scenarios.map((sc) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        sc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  DataCell(Text(sc.topicName,
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: Color(0xFF94A3B8)))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sc.level.name.toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        '${sc.aiRole} ↔ ${sc.userRole}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  DataCell(Text('${sc.usageCount}',
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${sc.avgScore}',
                          style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: sc.isActive,
                      activeThumbColor: AppColors.accent,
                      onChanged: (_) => controller.toggleScenarioStatus(sc.id),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              size: 18, color: AppColors.primaryLight),
                          onPressed: () {
                            ScenarioEditorDialog.show(
                              context,
                              initialScenario: sc,
                              onSave: (updated) =>
                                  controller.saveScenario(updated),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          onPressed: () =>
                              _confirmDelete(context, sc.id, sc.title),
                        ),
                      ],
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

  Widget _buildMobileCardsList(BuildContext context) {
    if (state.scenarios.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.scenarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sc = state.scenarios[index];
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sc.level.name.toUpperCase(),
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.primaryLight,
                          letterSpacing: 0.5),
                    ),
                  ),
                  Switch(
                    value: sc.isActive,
                    activeThumbColor: AppColors.accent,
                    onChanged: (_) => controller.toggleScenarioStatus(sc.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sc.title,
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${sc.topicName} • ${sc.estimatedMinutes} phút',
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 6),
              Text(
                'Tom: ${sc.aiRole} • Học viên: ${sc.userRole}',
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: Color(0xFFCBD5E1)),
              ),
              const Divider(height: 18, color: Color(0xFF1E293B)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('${sc.usageCount} lượt',
                          style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${sc.avgScore}',
                        style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            size: 18, color: AppColors.primaryLight),
                        onPressed: () {
                          ScenarioEditorDialog.show(
                            context,
                            initialScenario: sc,
                            onSave: (updated) =>
                                controller.saveScenario(updated),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        onPressed: () =>
                            _confirmDelete(context, sc.id, sc.title),
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
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy kịch bản phù hợp',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            'Thử tìm kiếm với từ khóa khác hoặc bỏ chọn bộ lọc',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Color(0xFF94A3B8),
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B))),
        title: const Text('Xác nhận xóa kịch bản',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.white,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc chắn muốn xóa kịch bản "$title" khỏi hệ thống? Thao tác này không thể hoàn tác.',
          style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: Color(0xFFCBD5E1),
              fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans', color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteScenario(id);
            },
            child: const Text('Xác nhận xóa',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
