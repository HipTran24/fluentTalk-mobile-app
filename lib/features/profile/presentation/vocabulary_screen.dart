import '../../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vocabulary_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/profile_controller.dart';

/// Screen 19 — Vocabulary & Saved Expressions
/// Compliant with ESP-PLAN-001 Appendix B21
class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vocabularyFilterProvider);
    final wordsAsync = ref.watch(vocabularyListProvider);
    final notifier = ref.read(vocabularyListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sổ tay từ vựng & Mẫu câu'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Chips (Tất cả, Đang học, Đã thuộc)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: AdaptiveRow(
                children: [
                  _buildFilterChip(ref, 'Tất cả', 'all', filter),
                  const SizedBox(width: 8),
                  _buildFilterChip(ref, 'Cần ôn luyện', 'learning', filter),
                  const SizedBox(width: 8),
                  _buildFilterChip(ref, 'Đã thành thạo', 'mastered', filter),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // 2. Vocabulary List
            Expanded(
              child: wordsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) => Center(child: Text('Lỗi: $err')),
                data: (allWords) {
                  final filtered = allWords.where((w) {
                    if (filter == 'learning') return !w.isMastered;
                    if (filter == 'mastered') return w.isMastered;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        title: 'Chưa có từ vựng nào',
                        description:
                            'Các từ vựng và mẫu câu hay bạn bắt gặp trong các buổi luyện nói sẽ được lưu tại đây.',
                        icon: Icons.book_outlined,
                        actionText: 'Xem tất cả',
                        onAction: () => ref
                            .read(vocabularyFilterProvider.notifier)
                            .state = 'all',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildWordCard(context, item, notifier);
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

  Widget _buildFilterChip(
      WidgetRef ref, String label, String value, String activeFilter) {
    final isSelected = activeFilter == value;
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
      side:
          BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          ref.read(vocabularyFilterProvider.notifier).state = value;
        }
      },
    );
  }

  Widget _buildWordCard(
      BuildContext context, VocabularyItem item, VocabularyNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.phrase,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  item.isMastered
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color:
                      item.isMastered ? AppColors.success : AppColors.textMuted,
                  size: 22,
                ),
                tooltip:
                    item.isMastered ? 'Đã thành thạo' : 'Đánh dấu đã thuộc',
                onPressed: () => notifier.toggleMastered(item.id),
              ),
            ],
          ),
          if (item.ipa != null) ...[
            Text(
              item.ipa!,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.accent,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            item.meaningVi,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (item.exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ví dụ: "${item.exampleSentence}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          AdaptiveRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nguồn: ${item.sourceScenarioTitle ?? "Phiên luyện nói"}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Phát âm chuẩn: "${item.phrase}"'),
                        duration: const Duration(seconds: 1)),
                  );
                },
                icon: const Icon(Icons.volume_up_rounded, size: 16),
                label:
                    const Text('Nghe phát âm', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
