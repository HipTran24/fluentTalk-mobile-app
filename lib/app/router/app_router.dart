import '../../features/connected/presentation/connected_area_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_otp_screen.dart';
import '../../features/auth/presentation/learning_unavailable_screen.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/coach/presentation/coach_screen.dart';
import '../../features/coach/presentation/tom_learning_screen.dart';
import '../../features/coach/presentation/drill_player_screen.dart';
import '../../features/coach/presentation/weekly_plan_screen.dart';
import '../../features/conversation/presentation/guided_speaking_screen.dart';
import '../../features/conversation/presentation/realtime_call_screen.dart';
import '../../features/conversation/presentation/live_voice_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  final router = _createRouter(
    () => ref.read(authControllerProvider),
    refreshListenable: refresh,
  );
  ref.listen<AuthState>(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

GoRouter get appRouter => _createRouter(() => const AuthState());

/// GoRouter Configuration for FluentTalk Mobile App
/// Compliant with ESP-PLAN-001 Appendix B2 (Sitemap / 5-Tab Navigation)
/// Guaranteed role-based access for /admin and auth guards for protected screens
GoRouter _createRouter(AuthState Function() readAuth,
        {Listenable? refreshListenable}) =>
    GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
      refreshListenable: refreshListenable,
      initialLocation: '/splash',
      redirect: (context, state) {
        final authState = readAuth();
        final loc = state.matchedLocation;
        final status = authState.status;
        final isAuth = status == AuthStatus.authenticated;
        final needsOnboarding = status == AuthStatus.needsOnboarding;
        final isAdmin = authState.isAdmin;

        final isSplash = loc == '/splash';
        final isWelcome = loc == '/welcome';
        final isAuthScreen = loc == '/auth' || loc == '/auth/otp';
        final isOnboarding = loc.startsWith('/onboarding');
        final isAdminScreen = loc == '/admin';
        final isPublicCatalog = loc == '/practice/scenarios' ||
            RegExp(r'^/practice/scenario/[^/]+$').hasMatch(loc);

        // ADR-010: active catalog metadata is public. Its repository uses
        // unauthenticated HTTP; session/Tom routes below remain protected.
        if (isPublicCatalog) return null;

        // 1. Initial state -> go to splash
        if (status == AuthStatus.initial || status == AuthStatus.loading) {
          if (isSplash || isWelcome || isAuthScreen) return null;
          if (isOnboarding && authState.user != null) return null;
          return '/splash';
        }

        // Text chat has a remote adapter; keep the remaining simulated flows gated.
        if (!authState.isDemo && (isAuth || needsOnboarding)) {
          if (isSplash || isWelcome || isAuthScreen || isOnboarding) {
            return '/home';
          }
          final connected = {
            '/home',
            '/practice',
            '/progress',
            '/coach',
            '/profile',
            '/progress/history',
            '/unavailable',
            '/practice/text'
          };
          if (loc == '/practice/voice' ||
              RegExp(r'^/practice/realtime/[^/]+$').hasMatch(loc)) {
            return null;
          }
          if (connected.contains(loc) ||
              RegExp(r'^/practice/session/[^/]+/summary$').hasMatch(loc)) {
            return null;
          }
          return '/unavailable';
        }

        // 2. Unauthenticated, error, or unconfigured
        if (status == AuthStatus.unauthenticated ||
            status == AuthStatus.unconfigured ||
            status == AuthStatus.error) {
          if (isSplash || isWelcome || isAuthScreen) return null;
          return '/welcome';
        }

        // 3. Needs onboarding
        if (needsOnboarding) {
          if (isOnboarding) return null;
          return '/onboarding/goal';
        }

        // 4. Authenticated
        if (isAuth) {
          if (isAdminScreen) {
            if (!isAdmin) return '/home';
            return null;
          }
          if (isSplash || isWelcome || isAuthScreen) {
            return '/home';
          }
          return null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/unavailable',
          builder: (context, state) => const LearningUnavailableScreen(),
        ),
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
          path: '/auth/otp',
          builder: (context, state) => EmailOtpScreen(
            email: state.extra is String ? state.extra as String : null,
          ),
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
            path: '/practice/voice',
            builder: (context, state) => const LiveVoiceScreen()),
        GoRoute(
          path: '/practice/realtime/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return readAuth().isDemo
                ? RealtimeCallScreen(sessionId: id)
                : const LiveVoiceScreen();
          },
        ),
        GoRoute(
          path: '/practice/session/:id/summary',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return _accountSurface(SessionSummaryScreen(sessionId: id),
                ConnectedSessionScreen(sessionId: id));
          },
        ),
        GoRoute(
          path: '/progress/history',
          builder: (context, state) => _accountSurface(const HistoryScreen(),
              const ConnectedAreaScreen(section: 'history')),
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
                  builder: (context, state) => _accountSurface(
                      const HomeScreen(),
                      const ConnectedAreaScreen(section: 'home')),
                ),
              ],
            ),

            // Tab 2: Practice
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/practice',
                  builder: (context, state) => _accountSurface(
                      const PracticeHubScreen(),
                      const ConnectedAreaScreen(section: 'practice')),
                ),
              ],
            ),

            // Tab 3: Progress
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/progress',
                  builder: (context, state) => _accountSurface(
                      const ProgressScreen(),
                      const ConnectedAreaScreen(section: 'progress')),
                ),
              ],
            ),

            // Tab 4: Coach
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/coach',
                  builder: (context, state) => _accountSurface(
                      const CoachScreen(), const TomLearningScreen()),
                ),
              ],
            ),

            // Tab 5: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => _accountSurface(
                      const ProfileScreen(),
                      const ConnectedAreaScreen(section: 'profile')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

Widget _accountSurface(Widget demo, Widget connected) => Consumer(
      builder: (context, ref, child) =>
          ref.watch(appConfigProvider).demoMode ? demo : connected,
    );
