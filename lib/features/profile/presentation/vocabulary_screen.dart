import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/vocabulary_item.dart';
import '../../../core/widgets/app_logo.dart';
import 'controllers/profile_controller.dart';

const _ink = Color(0xFF202B48);
const _muted = Color(0xFF637087);
const _blue = Color(0xFF344DA1);
const _green = Color(0xFF16745E);
const _orange = Color(0xFF99551E);

class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vocabularyFilterProvider);
    final wordsAsync = ref.watch(vocabularyListProvider);
    final notifier = ref.read(vocabularyListProvider.notifier);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sổ tay của bạn',
            style: TextStyle(
                color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: wordsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _blue)),
          error: (error, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: _muted, size: 36),
                    const SizedBox(height: 12),
                    const Text('Chưa tải được sổ tay',
                        style: TextStyle(
                            color: _ink, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('$error', textAlign: TextAlign.center),
                    TextButton.icon(
                        onPressed: () => ref.invalidate(vocabularyListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại')),
                  ]))),
          data: (words) {
            final mastered = words.where((w) => w.isMastered).length;
            final filtered = words
                .where((w) => filter == 'learning'
                    ? !w.isMastered
                    : filter == 'mastered'
                        ? w.isMastered
                        : true)
                .toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                      child: _widthLimit(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        _overview(words.length, mastered),
                        const SizedBox(height: 26),
                        const Text('Bộ sưu tập của bạn',
                            style: TextStyle(
                                color: _ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 6),
                        const Text('Ghi nhớ từng từ, tự tin trong từng câu.',
                            style: TextStyle(
                                color: _muted, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _filter(ref, 'Tất cả', 'all', filter, words.length,
                              _blue),
                          _filter(ref, 'Cần ôn', 'learning', filter,
                              words.length - mastered, _orange),
                          _filter(ref, 'Đã thuộc', 'mastered', filter, mastered,
                              _green),
                        ]),
                        const SizedBox(height: 18),
                      ]))),
                ),
                if (filtered.isEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                          child: _widthLimit(_empty(ref, words.isEmpty))))
                else
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) => _widthLimit(Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _wordCard(
                                      context, filtered[index], notifier))),
                              childCount: filtered.length))),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _widthLimit(Widget child) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SizedBox(width: double.infinity, child: child)));

  Widget _overview(int total, int mastered) {
    final progress = total == 0 ? 0.0 : mastered / total;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF202B73), Color(0xFF395EB8)]),
          borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          AppLogo(size: 44, inverted: true, withShadow: false),
          SizedBox(width: 12),
          Expanded(
              child: Text('FLUENTTALK · SỔ TAY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8))),
        ]),
        const SizedBox(height: 20),
        const Text('Tích lũy mỗi ngày.\nSử dụng thật tự nhiên.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: 1.25,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text('$mastered / $total mục đã thành thạo',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Semantics(
            label: 'Tỉ lệ thành thạo',
            value: '${(progress * 100).round()} phần trăm',
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF91E2D0))))),
        const SizedBox(height: 12),
        Text('${total - mastered} mục cần ôn · Từ vựng và mẫu câu đã lưu',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                height: 1.5)),
      ]),
    );
  }

  Widget _filter(WidgetRef ref, String label, String value, String selected,
          int count, Color color) =>
      ChoiceChip(
        label: Text('$label · $count'),
        selected: selected == value,
        showCheckmark: false,
        selectedColor: color.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected == value ? color : const Color(0xFFDFE5F0)),
        labelStyle: TextStyle(
            color: selected == value ? color : _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (_) =>
            ref.read(vocabularyFilterProvider.notifier).state = value,
      );

  Widget _empty(WidgetRef ref, bool noWords) => Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Icon(Icons.auto_stories_outlined, color: _blue, size: 40),
        const SizedBox(height: 14),
        Text(
            noWords
                ? 'Sổ tay đang chờ bạn khám phá'
                : 'Chưa có mục trong nhóm này',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Từ vựng và mẫu câu đã lưu sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.5)),
        if (!noWords)
          TextButton(
              onPressed: () =>
                  ref.read(vocabularyFilterProvider.notifier).state = 'all',
              child: const Text('Xem tất cả')),
      ]));

  Widget _wordCard(
      BuildContext context, VocabularyItem item, VocabularyNotifier notifier) {
    final color = item.isMastered ? _green : _orange;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E6F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(7)),
                    child: Text(
                        item.isMastered ? 'ĐÃ THÀNH THẠO' : 'ĐANG ÔN LUYỆN',
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                Text(item.phrase,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.3)),
              ])),
          IconButton(
              tooltip: item.isMastered
                  ? 'Chuyển về cần ôn luyện'
                  : 'Đánh dấu đã thuộc',
              onPressed: () => notifier.toggleMastered(item.id),
              icon: Icon(
                  item.isMastered
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: item.isMastered ? _green : const Color(0xFF91A0B7))),
        ]),
        if (item.ipa != null && item.ipa!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(item.ipa!,
              style: const TextStyle(color: _blue, fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 10),
        Text(item.meaningVi,
            style: const TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600)),
        if (item.exampleSentence.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FC),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VÍ DỤ SỬ DỤNG',
                        style: TextStyle(
                            color: _blue,
                            fontSize: 9,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('“${item.exampleSentence}”',
                        style: const TextStyle(
                            color: Color(0xFF435473),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                  ])),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFEDF0F6)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.bookmark_border_rounded, size: 15, color: _muted),
          const SizedBox(width: 5),
          Expanded(
              child: Text(
                  'Nguồn: ${item.sourceScenarioTitle ?? "Phiên luyện nói"}',
                  style: const TextStyle(
                      color: _muted, fontSize: 11, height: 1.4))),
        ]),
        const SizedBox(height: 4),
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Chế độ minh họa: chưa phát âm thanh.'))),
              icon: const Icon(Icons.volume_up_outlined, size: 18),
              label: const Text('Nghe phát âm · Demo'),
              style: TextButton.styleFrom(foregroundColor: _blue),
            )),
      ]),
    );
  }
}
