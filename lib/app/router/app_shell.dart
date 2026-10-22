import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// AppShell — 5-Tab Persistent Bottom Navigation Bar
/// Compliant with Appendix B2 (Home | Practice | Progress | Coach | Profile)
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            _buildLayout(context, constraints.maxWidth),
      );

  Widget _buildLayout(BuildContext context, double availableWidth) {
    if (availableWidth >= 1080) {
      const destinations = [
        (Icons.space_dashboard_outlined, 'Trang chủ'),
        (Icons.mic_none_rounded, 'Luyện tập'),
        (Icons.insights_outlined, 'Tiến độ'),
        (Icons.psychology_outlined, 'Tom'),
        (Icons.person_outline_rounded, 'Cá nhân'),
      ];
      return Scaffold(
          body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            width: 244,
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE7EAF2)))),
            child: SafeArea(
                child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              const Row(children: [
                                CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.graphic_eq,
                                        color: Colors.white)),
                                SizedBox(width: 10),
                                Flexible(
                                    child: Text('FluentTalk',
                                        style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.7)))
                              ]),
                              const Padding(
                                  padding: EdgeInsets.only(left: 50, top: 5),
                                  child: Text('A C A D E M Y',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700))),
                              const SizedBox(height: 48),
                              const Padding(
                                  padding:
                                      EdgeInsets.only(left: 14, bottom: 16),
                                  child: Text('KHÔNG GIAN HỌC TẬP',
                                      style: TextStyle(
                                          fontSize: 9,
                                          letterSpacing: 1,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w700))),
                              for (var i = 0; i < destinations.length; i++)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                        color: navigationShell.currentIndex == i
                                            ? AppColors.secondaryLight
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        child: ListTile(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14)),
                                            selected:
                                                navigationShell.currentIndex ==
                                                    i,
                                            selectedColor: AppColors.primary,
                                            leading: Icon(destinations[i].$1,
                                                size: 22),
                                            title: Text(destinations[i].$2,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            onTap: () => _onTap(i)))),
                              const SizedBox(height: 32),
                              Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FB),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.school_outlined,
                                            color: AppColors.primary),
                                        SizedBox(height: 12),
                                        Text('Từng bước, tự tin hơn.',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12)),
                                        SizedBox(height: 6),
                                        Text(
                                            'Một chút thực hành mỗi ngày tạo nên thay đổi.',
                                            style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                height: 1.6))
                                      ])),
                              const SizedBox(height: 16),
                            ]))))),
        Expanded(child: navigationShell),
      ]));
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            backgroundColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 350),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon:
                    Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.mic_none_rounded),
                selectedIcon: Icon(Icons.mic_rounded, color: AppColors.primary),
                label: 'Luyện tập',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon:
                    Icon(Icons.insert_chart_rounded, color: AppColors.primary),
                label: 'Tiến độ',
              ),
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon:
                    Icon(Icons.psychology_rounded, color: AppColors.primary),
                label: 'Tom',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon:
                    Icon(Icons.person_rounded, color: AppColors.primary),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
