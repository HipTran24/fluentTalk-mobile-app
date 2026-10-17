import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'controllers/admin_controller.dart';
import 'views/admin_ai_config_view.dart';
import 'views/admin_dashboard_view.dart';
import 'views/admin_scenarios_view.dart';
import 'views/admin_users_view.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final views = [
      AdminDashboardView(state: state, controller: controller),
      AdminScenariosView(state: state, controller: controller),
      AdminUsersView(state: state, controller: controller),
      AdminAiConfigView(state: state, controller: controller),
    ];

    final currentView = views[state.currentTabIndex];

    return Theme(
      data: AppTheme.darkTheme,
      child: isDesktop
          ? Scaffold(
              backgroundColor: const Color(0xFF0B0F19),
              body: Row(
                children: [
                  // Left Persistent Sidebar (260px)
                  _buildDesktopSidebar(context, state, controller),

                  // Main Content Area
                  Expanded(
                    child: Column(
                      children: [
                        _buildDesktopTopBar(context, state, controller),
                        Expanded(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : currentView,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: const Color(0xFF0B0F19),
              appBar: AppBar(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  _getTitleForTab(state.currentTabIndex),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Làm mới dữ liệu',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => controller.loadAll(),
                  ),
                  IconButton(
                    tooltip: 'Về ứng dụng học viên',
                    icon: const Icon(Icons.school_outlined),
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
              drawer: _buildMobileDrawer(context, state, controller),
              body: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentView,
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: NavigationBar(
                  backgroundColor: const Color(0xFF0F172A),
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: AppColors.primary.withOpacity(0.25),
                  selectedIndex: state.currentTabIndex,
                  onDestinationSelected: (idx) => controller.switchTab(idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined, color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryLight),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.movie_outlined, color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.movie_rounded, color: AppColors.primaryLight),
                      label: 'Kịch bản',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_alt_outlined, color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.primaryLight),
                      label: 'Học viên',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.psychology_outlined, color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.psychology_rounded, color: AppColors.primaryLight),
                      label: 'Cấu hình AI',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getTitleForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Quản trị FluentTalk';
      case 1:
        return 'Scenario CMS';
      case 2:
        return 'Quản lý Học viên';
      case 3:
        return 'Cấu hình AI';
      default:
        return 'Admin Portal';
    }
  }

  Widget _buildDesktopSidebar(BuildContext context, dynamic state, AdminController controller) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Studio Slate
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FluentTalk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'ADMIN CONSOLE v1.0',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          const SizedBox(height: AppSpacing.md),

          // Menu Section Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
            child: Text(
              'HỆ THỐNG ĐIỀU HÀNH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Navigation Links
          _buildSidebarNavItem(
            index: 0,
            icon: Icons.dashboard_rounded,
            title: 'Tổng quan & KPI',
            subtitle: 'Chỉ số thời gian thực',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(0),
          ),
          _buildSidebarNavItem(
            index: 1,
            icon: Icons.movie_edit,
            title: 'Quản lý Kịch bản',
            subtitle: 'Scenario CMS • ${state.scenarios.length} bài',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(1),
          ),
          _buildSidebarNavItem(
            index: 2,
            icon: Icons.people_alt_rounded,
            title: 'Học viên & Tiến độ',
            subtitle: 'User Directory',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(2),
          ),
          _buildSidebarNavItem(
            index: 3,
            icon: Icons.tune_rounded,
            title: 'Cấu hình Mô hình AI',
            subtitle: 'Gemini Live & Prompts',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(3),
          ),

          const Spacer(),

          // System Status Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Gateway Online (42 WS)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uptime 99.98% • Latency 420ms',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Back to Learner App Button
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Về App Học viên',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, dynamic state, AdminController controller) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'FluentTalk Admin',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const Text(' / ', style: TextStyle(color: Color(0xFF64748B))),
              Text(
                _getTitleForTab(state.currentTabIndex),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                onPressed: () => controller.loadAll(),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                width: 1,
                color: const Color(0xFF1E293B),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text('AD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Administrator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('admin@fluenttalk.ai', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, dynamic state, AdminController controller) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: const Color(0xFF131B2E),
              width: double.infinity,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 28),
                  SizedBox(height: 8),
                  Text('FluentTalk Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  Text('Bảng Điều hành Hệ thống', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard_rounded,
                color: state.currentTabIndex == 0 ? AppColors.primaryLight : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Tổng quan & KPI',
                style: TextStyle(
                  color: state.currentTabIndex == 0 ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: state.currentTabIndex == 0,
              selectedTileColor: AppColors.primary.withOpacity(0.15),
              onTap: () {
                controller.switchTab(0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.movie_edit,
                color: state.currentTabIndex == 1 ? AppColors.primaryLight : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Quản lý Kịch bản CMS',
                style: TextStyle(
                  color: state.currentTabIndex == 1 ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: state.currentTabIndex == 1,
              selectedTileColor: AppColors.primary.withOpacity(0.15),
              onTap: () {
                controller.switchTab(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people_alt_rounded,
                color: state.currentTabIndex == 2 ? AppColors.primaryLight : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Danh bạ Học viên',
                style: TextStyle(
                  color: state.currentTabIndex == 2 ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: state.currentTabIndex == 2,
              selectedTileColor: AppColors.primary.withOpacity(0.15),
              onTap: () {
                controller.switchTab(2);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.tune_rounded,
                color: state.currentTabIndex == 3 ? AppColors.primaryLight : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Cấu hình Mô hình AI',
                style: TextStyle(
                  color: state.currentTabIndex == 3 ? Colors.white : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 3 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: state.currentTabIndex == 3,
              selectedTileColor: AppColors.primary.withOpacity(0.15),
              onTap: () {
                controller.switchTab(3);
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFF1E293B)),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight),
              title: const Text('Về ứng dụng học viên', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
