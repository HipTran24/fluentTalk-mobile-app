import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/coach/presentation/coach_screen.dart';
import '../../features/coach/presentation/drill_player_screen.dart';
import '../../features/coach/presentation/weekly_plan_screen.dart';
import '../../features/conversation/presentation/guided_speaking_screen.dart';
import '../../features/conversation/presentation/realtime_call_screen.dart';
import '../../features/conversation/presentation/text_chat_screen.dart';
import '../../features/feedback/presentation/session_summary_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/goal_onboarding_screen.dart';
import '../../features/onboarding/presentation/placement_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/vocabulary_screen.dart';
import '../../features/progress/presentation/history_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/scenarios/presentation/practice_hub_screen.dart';
import '../../features/scenarios/presentation/scenario_catalog_screen.dart';
import '../../features/scenarios/presentation/scenario_detail_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// GoRouter Configuration for FluentTalk Mobile App
/// Compliant with ESP-PLAN-001 Appendix B2 (Sitemap / 5-Tab Navigation)
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Auth & Onboarding Flow (Top-Level)
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return AuthScreen(initialMode: mode);
      },
    ),
    GoRoute(
      path: '/onboarding/goal',
      builder: (context, state) => const GoalOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/placement',
      builder: (context, state) => const PlacementScreen(),
    ),

    // Executive Admin Console (Responsive for Web & Mobile)
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),

    // Immersive Session & Practice Screens (Full-screen overlay)
    GoRoute(
      path: '/practice/scenarios',
      builder: (context, state) => const ScenarioCatalogScreen(),
    ),
    GoRoute(
      path: '/practice/scenario/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ScenarioDetailScreen(scenarioId: id);
      },
    ),
    GoRoute(
      path: '/practice/text',
      builder: (context, state) => const TextChatScreen(),
    ),
    GoRoute(
      path: '/practice/guided/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return GuidedSpeakingScreen(scenarioId: id);
      },
    ),
    GoRoute(
      path: '/practice/realtime/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RealtimeCallScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/practice/session/:id/summary',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SessionSummaryScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/progress/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/coach/drill/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DrillPlayerScreen(drillId: id);
      },
    ),
    GoRoute(
      path: '/coach/plan',
      builder: (context, state) => const WeeklyPlanScreen(),
    ),
    GoRoute(
      path: '/profile/vocabulary',
      builder: (context, state) => const VocabularyScreen(),
    ),

    // Stateful 5-Tab Persistent Navigation Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 2: Practice
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/practice',
              builder: (context, state) => const PracticeHubScreen(),
            ),
          ],
        ),

        // Tab 3: Progress
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),

        // Tab 4: Coach
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/coach',
              builder: (context, state) => const CoachScreen(),
            ),
          ],
        ),

        // Tab 5: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
