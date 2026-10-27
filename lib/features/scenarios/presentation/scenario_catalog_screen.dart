import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/scenario.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/widgets/level_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'controllers/scenario_controller.dart';

/// Screen 08 — Topic & Scenario Catalog
/// Compliant with ESP-PLAN-001 Appendix B10
class ScenarioCatalogScreen extends ConsumerStatefulWidget {
  const ScenarioCatalogScreen({super.key});

  @override
  ConsumerState<ScenarioCatalogScreen> createState() =>
      _ScenarioCatalogScreenState();
}

class _ScenarioCatalogScreenState extends ConsumerState<ScenarioCatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<Map<String, String>> _catalogTabs = [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'popular', 'label': 'Phổ biến'},
    {'id': 'recommended', 'label': 'Gợi ý cho bạn'},
    {'id': 'bookmarked', 'label': 'Đã lưu ⭐'},
  ];

  @override
  void initState() {
    super.initState();
    if (!ref.read(scenarioRepositoryProvider).supportsCuratedTabs) {
      _catalogTabs.removeWhere((tab) => tab['id'] != 'all');
    }
    _tabController = TabController(length: _catalogTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedTopicIdProvider.notifier).state = 'all';
    ref.read(selectedLevelProvider.notifier).state = null;
    ref.read(selectedCatalogTabProvider.notifier).state = 'all';
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final scenariosAsync = ref.watch(catalogPageProvider);
    final selectedTopicId = ref.watch(selectedTopicIdProvider);
    final selectedLevel = ref.watch(selectedLevelProvider);
    final bookmarkController = ref.read(bookmarkControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text('Kho kịch bản luyện nói'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar with Live Clear
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sm,
                AppSpacing.pageHorizontal,
                AppSpacing.xs,
              ),
              child: TextField(
                controller: _searchController,
                maxLength: 100,
                onChanged: (val) {
                  setState(() {});
                  _searchDebounce?.cancel();
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    }
                  });
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Tìm theo tên kịch bản, vai trò, từ khóa...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            // 2. Tabs Switcher: Tất cả / Phổ biến / Gợi ý / Đã lưu
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal),
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              onTap: (idx) {
                ref.read(selectedCatalogTabProvider.notifier).state =
                    _catalogTabs[idx]['id']!;
              },
              tabs: _catalogTabs.map((t) => Tab(text: t['label'])).toList(),
            ),

            const SizedBox(height: AppSpacing.xs),

            // 3. Topic Category Filter Chips
            topicsAsync.when(
              data: (topics) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal, vertical: 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả chủ đề'),
                        selected: selectedTopicId == 'all',
                        selectedColor: const Color(0xFFDDE8FF),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedTopicId == 'all'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selectedTopicId == 'all'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) {
                          ref.read(selectedTopicIdProvider.notifier).state =
                              'all';
                        },
                      ),
                      ...topics.map((tp) {
                        final isSelected = selectedTopicId == tp.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text('${tp.icon} ${tp.title}'),
                            selected: isSelected,
                            selectedColor: const Color(0xFFDDE8FF),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (_) {
                              ref.read(selectedTopicIdProvider.notifier).state =
                                  tp.id;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 40),
              error: (_, __) => TextButton.icon(
                onPressed: () => ref.invalidate(topicsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Chưa tải được chủ đề. Thử lại'),
              ),
            ),

            // 4. Level Filter Chips (A0 - C2)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Mọi Level'),
                    selected: selectedLevel == null,
                    selectedColor: const Color(0xFFD8F1EA),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: selectedLevel == null
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selectedLevel == null
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    onSelected: (_) {
                      ref.read(selectedLevelProvider.notifier).state = null;
                    },
                  ),
                  ...UserLevel.values.map((lvl) {
                    final isSelected = selectedLevel == lvl;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(lvl.code),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD8F1EA),
                        checkmarkColor: const Color(0xFF146957),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        onSelected: (val) {
                          ref.read(selectedLevelProvider.notifier).state =
                              val ? lvl : null;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const Divider(height: 12),

            // 5. Scenarios List or Empty State
            Expanded(
              child: scenariosAsync.when(
                data: (page) {
                  final scenarios = page.items;
                  if (scenarios.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'Không tìm thấy kịch bản phù hợp',
                      description:
                          'Thử thay đổi từ khóa tìm kiếm hoặc chọn lại chủ đề / cấp độ khác.',
                      actionText: 'Xóa toàn bộ bộ lọc',
                      onAction: _clearAllFilters,
                    );
                  }

                  return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(catalogPageProvider);
                        try {
                          await ref.read(catalogPageProvider.future);
                        } catch (_) {
                          // The provider renders the safe error and retry UI.
                        }
                      },
                      child: ListView.builder(
                        scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.all(AppSpacing.pageHorizontal),
                        itemCount: scenarios.length,
                        itemBuilder: (ctx, idx) {
                          final scenario = scenarios[idx];
                          return _buildScenarioCard(
                              scenario, bookmarkController);
                        },
                      ));
                },
                loading: () => ListView.builder(
                  scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                  padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                  itemCount: 4,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerLoading.card(height: 130),
                  ),
                ),
                error: (err, _) => SingleChildScrollView(
                  child: ErrorStateWidget(
                    message: err is ApiFailure
                        ? err.message
                        : 'Không thể tải danh mục. Hãy thử lại.',
                    onRetry: () => ref.invalidate(catalogPageProvider),
                  ),
                ),
              ),
            ),
            scenariosAsync.maybeWhen(
              data: (page) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Trang trước',
                      onPressed: page.page > 0
                          ? () => ref
                              .read(catalogPageIndexProvider.notifier)
                              .state--
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Flexible(
                      child: Text(
                        'Trang ${page.page + 1}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Trang sau',
                      onPressed: page.hasMore
                          ? () => ref
                              .read(catalogPageIndexProvider.notifier)
                              .state++
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
      Scenario scenario, BookmarkController bookmarkController) {
    const levelColors = [
      Color(0xFF315BB5),
      Color(0xFF147563),
      Color(0xFF7B4FA3),
      Color(0xFFB05A28),
      Color(0xFF9E426A),
      Color(0xFF395D99),
      Color(0xFF39796A)
    ];
    final levelColor = levelColors[scenario.level.index % levelColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: levelColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/practice/scenario/${scenario.id}'),
          borderRadius: AppRadius.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta row: Level, Duration, Bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        LevelChip(level: scenario.level),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.09),
                            borderRadius:
                                BorderRadius.circular(AppRadius.round),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${scenario.estimatedMinutes} phút',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                    if (ref.read(scenarioRepositoryProvider).supportsBookmarks)
                      IconButton(
                        icon: Icon(
                          scenario.isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: scenario.isBookmarked
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => bookmarkController.toggle(scenario.id),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                // Scenario Title
                Text(
                  scenario.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                // Roles Preview
                Text(
                  'Tom: ${scenario.roleAi} • Bạn: ${scenario.roleUser}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  scenario.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                if (scenario.samplePhrases.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '"${scenario.samplePhrases.first}"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
