import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
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
    final isDesktop = screenWidth >= 960;

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
                  // Left Persistent Sidebar (270px)
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
                centerTitle: false,
                title: Row(
                  children: [
                    const AppLogo(size: 28, withShadow: false),
                    const SizedBox(width: 10),
                    Text(
                      _getTitleForTab(state.currentTabIndex),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
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
                  indicatorColor: AppColors.primary.withValues(alpha: 0.22),
                  selectedIndex: state.currentTabIndex,
                  onDestinationSelected: (idx) => controller.switchTab(idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined,
                          color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.dashboard_rounded,
                          color: AppColors.primaryLight),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon:
                          Icon(Icons.movie_outlined, color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.movie_rounded,
                          color: AppColors.primaryLight),
                      label: 'Kịch bản',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_alt_outlined,
                          color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.people_alt_rounded,
                          color: AppColors.primaryLight),
                      label: 'Học viên',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.psychology_outlined,
                          color: Color(0xFF94A3B8)),
                      selectedIcon: Icon(Icons.psychology_rounded,
                          color: AppColors.primaryLight),
                      label: 'Cấu hình Tom',
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
        return 'Tổng quan & KPI';
      case 1:
        return 'Quản lý Kịch bản';
      case 2:
        return 'Danh bạ Học viên';
      case 3:
        return 'Cấu hình Tom Gateway';
      default:
        return 'Admin Studio';
    }
  }

  Widget _buildDesktopSidebar(
      BuildContext context, dynamic state, AdminController controller) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
            right: BorderSide(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                const AppLogo(size: 36, withShadow: false),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FluentTalk',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN PRO',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'v2.0',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          const SizedBox(height: AppSpacing.md),

          // Menu Section Label
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
            child: Text(
              'ĐIỀU HÀNH HỆ THỐNG',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 6),

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
            title: 'Danh bạ Học viên',
            subtitle: 'User Directory • ${state.learners.length} học viên',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(2),
          ),
          _buildSidebarNavItem(
            index: 3,
            icon: Icons.tune_rounded,
            title: 'Cấu hình Mô hình Tom',
            subtitle: 'Gemini Live & Prompts',
            currentIndex: state.currentTabIndex,
            onTap: () => controller.switchTab(3),
          ),

          const Spacer(),

          // System Status Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Gateway Online (42 WS)',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uptime 99.98% • Latency 420ms',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Back to Learner App Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/home'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        color: AppColors.primaryLight, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Về App Học viên',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(
      BuildContext context, dynamic state, AdminController controller) {
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
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right_rounded,
                    size: 16, color: Color(0xFF64748B)),
              ),
              Text(
                _getTitleForTab(state.currentTabIndex),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Gateway',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => controller.loadAll(),
              ),
              const SizedBox(width: 8),
              Container(
                height: 28,
                width: 1,
                color: const Color(0xFF1E293B),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF0F172A),
                  child: Text('AD',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Administrator',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  Text(
                    'admin@fluenttalk.ai',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(
      BuildContext context, dynamic state, AdminController controller) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: const Color(0xFF131B2E),
              width: double.infinity,
              child: const Row(
                children: [
                  AppLogo(size: 38, withShadow: false),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FluentTalk Admin',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17),
                      ),
                      Text(
                        'Bảng Điều hành Hệ thống',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            color: Color(0xFF94A3B8),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard_rounded,
                color: state.currentTabIndex == 0
                    ? AppColors.primaryLight
                    : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Tổng quan & KPI',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: state.currentTabIndex == 0
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 0
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: state.currentTabIndex == 0,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
              onTap: () {
                controller.switchTab(0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.movie_edit,
                color: state.currentTabIndex == 1
                    ? AppColors.primaryLight
                    : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Quản lý Kịch bản CMS',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: state.currentTabIndex == 1
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 1
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: state.currentTabIndex == 1,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
              onTap: () {
                controller.switchTab(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people_alt_rounded,
                color: state.currentTabIndex == 2
                    ? AppColors.primaryLight
                    : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Danh bạ Học viên',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: state.currentTabIndex == 2
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 2
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: state.currentTabIndex == 2,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
              onTap: () {
                controller.switchTab(2);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.tune_rounded,
                color: state.currentTabIndex == 3
                    ? AppColors.primaryLight
                    : const Color(0xFF94A3B8),
              ),
              title: Text(
                'Cấu hình Mô hình Tom',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: state.currentTabIndex == 3
                      ? Colors.white
                      : const Color(0xFFCBD5E1),
                  fontWeight: state.currentTabIndex == 3
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: state.currentTabIndex == 3,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
              onTap: () {
                controller.switchTab(3);
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFF1E293B)),
            ListTile(
              leading: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primaryLight),
              title: const Text('Về ứng dụng học viên',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                      fontSize: 14)),
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
