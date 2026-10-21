import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/practice_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/level_chip.dart';
import 'controllers/progress_controller.dart';

/// Screen 15 — Session History / Detail
/// Compliant with ESP-PLAN-001 Appendix B17
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = ref.watch(historyFilterModeProvider);
    final historyAsync = ref.watch(practiceHistoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử các phiên luyện nói'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên tình huống...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(historySearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) {
                  ref.read(historySearchQueryProvider.notifier).state = val;
                  setState(() {});
                },
              ),
            ),

            // 2. Mode Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all', activeFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Luyện theo lượt (Guided)', 'guided', activeFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cuộc gọi Realtime', 'realtime', activeFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hỏi đáp văn bản (Text)', 'text', activeFilter),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 3. History List
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Text('Lỗi tải lịch sử: $err'),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        title: 'Không tìm thấy phiên luyện tập',
                        description: 'Không có phiên nói nào phù hợp với bộ lọc hiện tại của bạn.',
                        icon: Icons.history_toggle_off_rounded,
                        actionText: 'Đặt lại bộ lọc',
                        onAction: () {
                          _searchController.clear();
                          ref.read(historyFilterModeProvider.notifier).state = 'all';
                          ref.read(historySearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = sessions[index];
                      return _buildHistoryCard(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String modeValue, String activeFilter) {
    final isSelected = activeFilter == modeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          ref.read(historyFilterModeProvider.notifier).state = modeValue;
        }
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, PracticeSession session) {
    final durationMins = (session.durationSeconds ~/ 60);
    final durationSecs = (session.durationSeconds % 60);
    final durationText = '${durationMins}m ${durationSecs}s';

    Color modeColor;
    IconData modeIcon;
    switch (session.mode) {
      case SessionMode.guided:
        modeColor = AppColors.primary;
        modeIcon = Icons.record_voice_over_rounded;
        break;
      case SessionMode.realtime:
        modeColor = AppColors.accent;
        modeIcon = Icons.phone_in_talk_rounded;
        break;
      case SessionMode.text:
        modeColor = Colors.orange;
        modeIcon = Icons.chat_bubble_outline_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        onTap: () => context.push('/practice/session/${session.id}/summary'),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(modeIcon, size: 12, color: modeColor),
                  const SizedBox(width: 4),
                  Text(
                    session.mode.title,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: modeColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const LevelChip(level: UserLevel.a2),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.scenarioTitle ?? 'Phiên luyện nói tự do',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thời lượng: $durationText • ${session.turnsCount} lượt đối thoại',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    session.estimatedScore != null ? session.estimatedScore!.toStringAsFixed(1) : '6.0',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
