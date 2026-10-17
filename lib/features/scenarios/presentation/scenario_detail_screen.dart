import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/scenario.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheets/permission_rationale_sheet.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'controllers/scenario_controller.dart';

/// Screen 09 — Scenario Detail / Session Setup
/// Compliant with ESP-PLAN-001 Appendix B11
class ScenarioDetailScreen extends ConsumerStatefulWidget {
  final String scenarioId;

  const ScenarioDetailScreen({
    super.key,
    required this.scenarioId,
  });

  @override
  ConsumerState<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends ConsumerState<ScenarioDetailScreen> {
  SessionMode _selectedMode = SessionMode.guided;
  double _speakingSpeed = 1.0;
  bool _liveCaptions = true;
  String _selectedVoice = 'en-US-Journey-F';

  Future<void> _startSession(String scenarioId) async {
    // Microphone permission check
    final granted = await PermissionRationaleSheet.show(context);
    if (!mounted || granted != true) return;

    // Navigate to appropriate mode
    switch (_selectedMode) {
      case SessionMode.guided:
        context.push('/practice/guided/$scenarioId');
        break;
      case SessionMode.realtime:
        context.push('/practice/realtime/$scenarioId');
        break;
      case SessionMode.text:
        context.push('/practice/text');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarioAsync = ref.watch(scenarioDetailProvider(widget.scenarioId));
    final bookmarkController = ref.read(bookmarkControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết tình huống'),
        actions: [
          scenarioAsync.when(
            data: (scenario) => scenario != null
                ? IconButton(
                    icon: Icon(
                      scenario.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: scenario.isBookmarked ? AppColors.primary : AppColors.textPrimary,
                    ),
                    onPressed: () => bookmarkController.toggle(scenario.id),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: scenarioAsync.when(
          data: (scenario) {
            if (scenario == null) {
              return ErrorStateWidget(
                title: 'Không tìm thấy tình huống',
                message: 'Kịch bản luyện nói này không tồn tại hoặc đã bị ẩn.',
                onRetry: () => ref.invalidate(scenarioDetailProvider(widget.scenarioId)),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.pageVertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Meta Badges Row: Level & Duration
                        Row(
                          children: [
                            LevelChip(level: scenario.level),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.round),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${scenario.estimatedMinutes} phút',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Title
                        Text(
                          scenario.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Context Description
                        Text(
                          scenario.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // 2. Roles Mapping Card
                        _buildRolesCard(scenario),

                        const SizedBox(height: AppSpacing.lg),

                        // 3. Learning Outcomes (Mục tiêu cần đạt)
                        _buildOutcomesSection(scenario),

                        const SizedBox(height: AppSpacing.lg),

                        // 4. Vocabulary Preview (Từ vựng & Mẫu câu gợi ý)
                        if (scenario.vocabularyPreview.isNotEmpty) ...[
                          _buildVocabularyPreview(scenario),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // 5. Session Setup Controls
                        _buildSessionSetup(),

                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Start Button
                Container(
                  padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: PrimaryButton(
                    text: 'Bắt đầu hội thoại ngay',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _startSession(scenario.id),
                  ),
                ),
              ],
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              children: [
                ShimmerLoading.card(height: 120),
                const SizedBox(height: AppSpacing.md),
                ShimmerLoading.card(height: 160),
                const SizedBox(height: AppSpacing.md),
                ShimmerLoading.card(height: 140),
              ],
            ),
          ),
          error: (err, _) => ErrorStateWidget(
            message: 'Không thể tải chi tiết kịch bản: $err',
            onRetry: () => ref.invalidate(scenarioDetailProvider(widget.scenarioId)),
          ),
        ),
      ),
    );
  }

  Widget _buildRolesCard(Scenario scenario) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân vai giao tiếp:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gia sư AI đóng vai:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      scenario.roleAi,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.accentBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bạn đóng vai:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      scenario.roleUser,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomesSection(Scenario scenario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Mục tiêu đầu ra sau bài học:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...scenario.learningObjectives.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVocabularyPreview(Scenario scenario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.translate_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Từ vựng & Mẫu câu gợi ý:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...scenario.vocabularyPreview.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.phrase,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          item.ipa,
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.meaningVi,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accent),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionSetup() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Thiết lập phiên hội thoại:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 1. Practice Mode Selection
          const Text('Chế độ luyện tập:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Nói theo lượt (Khuyên dùng)', style: TextStyle(fontSize: 11)),
                  selected: _selectedMode == SessionMode.guided,
                  selectedColor: AppColors.secondaryLight,
                  labelStyle: TextStyle(
                    fontWeight: _selectedMode == SessionMode.guided ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedMode == SessionMode.guided ? AppColors.primary : AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMode = SessionMode.guided);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Gọi thoại 2 chiều', style: TextStyle(fontSize: 11)),
                  selected: _selectedMode == SessionMode.realtime,
                  selectedColor: AppColors.secondaryLight,
                  labelStyle: TextStyle(
                    fontWeight: _selectedMode == SessionMode.realtime ? FontWeight.w700 : FontWeight.w400,
                    color: _selectedMode == SessionMode.realtime ? AppColors.primary : AppColors.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMode = SessionMode.realtime);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // 2. AI Speaking Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tốc độ phát âm AI:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Row(
                children: [0.75, 1.0, 1.25].map((speed) {
                  final isSelected = _speakingSpeed == speed;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => setState(() => _speakingSpeed = speed),
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.round),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. Live Captions Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hiển thị phụ đề thời gian thực:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Switch(
                value: _liveCaptions,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _liveCaptions = val),
              ),
            ],
          ),

          // 4. Voice Choice
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Giọng AI:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              DropdownButton<String>(
                value: _selectedVoice,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'en-US-Journey-F', child: Text('🇺🇸 Emma (Anh-Mỹ)')),
                  DropdownMenuItem(value: 'en-GB-Journey-M', child: Text('🇬🇧 Arthur (Anh-Anh)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVoice = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
