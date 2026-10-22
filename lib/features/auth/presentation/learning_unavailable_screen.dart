import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'controllers/auth_controller.dart';

/// Fail closed while production learning adapters are not implemented.
/// ESP-S4..S7: remove this route gate only after real adapters pass acceptance.
class LearningUnavailableScreen extends ConsumerWidget {
  const LearningUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text('Khu vực luyện tập',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                  'Chat văn bản kết nối máy chủ và lưu hội thoại theo tài khoản. '
                  'Các chế độ luyện nói và coach đang được hoàn thiện.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/practice/text'),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Luyện chat với Tom'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/practice/scenarios'),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Khám phá tình huống'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
