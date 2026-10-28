import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_logo.dart';

/// Practice hub used by the demo version of the app.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: AppLogoWordmark(logoSize: 30, fontSize: 18)),
                      IconButton(
                        tooltip: 'Kho tình huống',
                        onPressed: () => context.push('/practice/scenarios'),
                        icon: const Icon(Icons.grid_view_rounded),
                        color: const Color(0xFF164D48),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    const Text('Góc luyện tập',
                        style: TextStyle(
                            color: Color(0xFF172D2B),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6)),
                    const SizedBox(height: 8),
                    const Text('Mỗi cuộc trò chuyện là một bước tiến nhỏ.',
                        style: TextStyle(
                            color: Color(0xFF61726E),
                            fontSize: 14,
                            height: 1.5)),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF202B73), Color(0xFF395EB8)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const AppLogo(
                                      size: 58,
                                      inverted: true,
                                      withShadow: false),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        const Text('FLUENTTALK',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1)),
                                        const SizedBox(height: 3),
                                        Text('Luyện tiếng Anh cùng Tom',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.82),
                                                fontSize: 12)),
                                      ])),
                                ]),
                            const SizedBox(height: 16),
                            const Text('Bắt đầu từ một\ncuộc trò chuyện',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(
                                'Chọn một tình huống quen thuộc và luyện tiếng Anh theo cách của bạn.',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    height: 1.5)),
                          ]),
                    ),
                    const SizedBox(height: 30),
                    const Text('Chọn cách luyện tập',
                        style: TextStyle(
                            color: Color(0xFF172D2B),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    const Text('Lựa chọn phù hợp với bạn hôm nay',
                        style:
                            TextStyle(color: Color(0xFF61726E), fontSize: 13)),
                    const SizedBox(height: 16),
                    _PracticeCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF335AB8),
                        label: 'HỎI & NGHE',
                        title: 'Trò chuyện cùng Tom',
                        description: 'Nhập câu hỏi và nghe phản hồi từ Tom.',
                        duration: '1–3 phút',
                        onTap: () => context.push('/practice/text')),
                    const SizedBox(height: 12),
                    _PracticeCard(
                        icon: Icons.record_voice_over_outlined,
                        color: const Color(0xFF19816E),
                        label: 'THEO TÌNH HUỐNG',
                        title: 'Luyện nói theo lượt',
                        description:
                            'Luyện hội thoại qua các tình huống nhập vai.',
                        duration: '5–10 phút',
                        onTap: () => context.push('/practice/scenarios')),
                    const SizedBox(height: 12),
                    _PracticeCard(
                        icon: Icons.phone_in_talk_outlined,
                        color: const Color(0xFF7955B9),
                        label: 'GIỌNG NÓI',
                        title: 'Gọi thoại trực tiếp',
                        description:
                            'Luyện phản xạ qua hội thoại bằng giọng nói.',
                        duration: '5–15 phút',
                        onTap: () =>
                            context.push('/practice/realtime/quick_call')),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE9EEFC),
                          borderRadius: BorderRadius.circular(18)),
                      child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tips_and_updates_outlined,
                                color: Color(0xFF267561)),
                            SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                    'Hãy chọn một chủ đề gần gũi và dành vài phút luyện tập mỗi ngày.',
                                    style: TextStyle(
                                        color: Color(0xFF355C50),
                                        fontSize: 13,
                                        height: 1.5))),
                          ]),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.title,
      required this.description,
      required this.duration,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String label, title, description, duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2EAE6))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(title,
                        style: const TextStyle(
                            color: Color(0xFF172D2B),
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ])),
              const Icon(Icons.arrow_outward_rounded,
                  size: 20, color: Color(0xFF8B9B95)),
            ]),
            const SizedBox(height: 14),
            Text(description,
                style: const TextStyle(
                    color: Color(0xFF61726E), fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded,
                      color: Color(0xFF7B8C86), size: 16),
                  const SizedBox(width: 5),
                  Text(duration,
                      style: const TextStyle(
                          color: Color(0xFF61726E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                Text('Bắt đầu',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
