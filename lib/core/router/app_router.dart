import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tajvid_yoli/core/responsive/adaptive_shell.dart';
import 'package:tajvid_yoli/features/onboarding/onboarding_screen.dart';
import 'package:tajvid_yoli/features/home/home_screen.dart';
import 'package:tajvid_yoli/features/quran/surah_list_screen.dart';
import 'package:tajvid_yoli/features/quran/quran_reader_screen.dart';
import 'package:tajvid_yoli/features/quran/book_reader_screen.dart';
import 'package:tajvid_yoli/features/recitation_finder/recitation_finder_screen.dart';
import 'package:tajvid_yoli/features/ai_check/ai_check_screen.dart';
import 'package:tajvid_yoli/features/profile/profile_screen.dart';
import 'package:tajvid_yoli/features/alphabet/alphabet_screen.dart';
import 'package:tajvid_yoli/features/alphabet/letter_connections_screen.dart';
import 'package:tajvid_yoli/features/quiz/quiz_screen.dart';
import 'package:tajvid_yoli/features/settings/settings_screen.dart';
import 'package:tajvid_yoli/features/bookmarks/bookmarks_screen.dart';
import 'package:tajvid_yoli/features/auth/login_screen.dart';
import 'package:tajvid_yoli/features/harakat/harakat_screen.dart';
import 'package:tajvid_yoli/features/harakat/syllable_practice_screen.dart';
import 'package:tajvid_yoli/features/harakat/word_reading_screen.dart';
import 'package:tajvid_yoli/features/tajwid_course/tajwid_course_screen.dart';
import 'package:tajvid_yoli/features/daily_plan/daily_plan_screen.dart';
import 'package:tajvid_yoli/features/certificate/certificate_screen.dart';
import 'package:tajvid_yoli/features/search/search_screen.dart';
import 'package:tajvid_yoli/features/auth/register_screen.dart';
import 'package:tajvid_yoli/core/utils/onboarding_store.dart';
import 'package:tajvid_yoli/core/widgets/permission_screen.dart';
import 'package:tajvid_yoli/features/settings/faq_screen.dart';
import 'package:tajvid_yoli/features/feedback/feedback_screen.dart';
import 'package:tajvid_yoli/features/auth/complete_profile_screen.dart';
import 'package:tajvid_yoli/features/auth/loading_screen.dart';
import 'package:tajvid_yoli/features/auth/email_verification_screen.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'router_refresh_stream.dart';

class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthBloc authBloc,
      {required GoRouterRefreshStream refresh}) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: refresh,
      redirect: (context, state) {
        final rawState = authBloc.state;
        final authState = rawState is AuthError && rawState.previous != null
            ? rawState.previous!
            : rawState;
        final location = state.matchedLocation;

        final isSplash = location == '/splash';
        final isVerification = location == '/verify-email';
        final isAuthPath = location == '/login' ||
            location == '/register' ||
            location == '/onboarding' ||
            location == '/permissions' ||
            isVerification;

        if (authState is AuthLoading && isAuthPath) return null;
        if (authState is AuthError) return isAuthPath ? null : '/login';
        if (authState is AuthInitial || authState is AuthLoading) {
          return isSplash ? null : '/splash';
        }

        if (authState is AuthAuthenticated) {
          return (isSplash || isAuthPath) ? '/home' : null;
        }

        if (authState is AuthNeedsEmailVerification) {
          return isVerification ? null : '/verify-email';
        }

        if (authState is AuthNeedsProfileCompletion) {
          return location == '/complete-profile' ? null : '/complete-profile';
        }

        if (authState is AuthUnauthenticated) {
          if (isVerification) return '/login';
          if (isAuthPath) return null;
          return OnboardingStore.completed ? '/login' : '/onboarding';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const LoadingScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          pageBuilder: (context, state) =>
              _slideTransition(state, const OnboardingScreen()),
        ),
        GoRoute(
          path: '/permissions',
          pageBuilder: (context, state) =>
              _slideTransition(state, const PermissionScreen()),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) =>
              _slideTransition(state, const LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) =>
              _slideTransition(state, const RegisterScreen()),
        ),
        GoRoute(
          path: '/complete-profile',
          pageBuilder: (context, state) =>
              _slideTransition(state, const CompleteProfileScreen()),
        ),
        GoRoute(
          path: '/verify-email',
          pageBuilder: (context, state) =>
              _slideTransition(state, const EmailVerificationScreen()),
        ),
        // MAIN TABS: bitta doimiy qobiq — tablar qayta qurilmaydi, holat saqlanadi
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AdaptiveShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/quran',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SurahListScreen()),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/ai-check',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: AiCheckScreen(
                      initialText: state.uri.queryParameters['text']),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ]),
          ],
        ),

        // SUB-PAGES
        GoRoute(
          path: '/quran/:surahNumber',
          pageBuilder: (context, state) {
            final number =
                int.tryParse(state.pathParameters['surahNumber'] ?? '1') ?? 1;
            final ayah = int.tryParse(state.uri.queryParameters['ayah'] ?? '');
            return _slideTransition(state,
                QuranReaderScreen(surahNumber: number, ayahNumber: ayah));
          },
        ),
        GoRoute(
          path: '/book/:surahNumber',
          pageBuilder: (context, state) {
            final number =
                int.tryParse(state.pathParameters['surahNumber'] ?? '1') ?? 1;
            return _slideTransition(
                state, BookReaderScreen(surahNumber: number));
          },
        ),
        GoRoute(
          path: '/recitation-finder',
          pageBuilder: (context, state) =>
              _slideTransition(state, const RecitationFinderScreen()),
        ),
        GoRoute(
          path: '/alphabet',
          pageBuilder: (context, state) =>
              _slideTransition(state, const AlphabetScreen()),
        ),
        GoRoute(
          path: '/letter-connections',
          pageBuilder: (context, state) =>
              _slideTransition(state, const LetterConnectionsScreen()),
        ),
        GoRoute(
          path: '/harakat',
          pageBuilder: (context, state) =>
              _slideTransition(state, const HarakatScreen()),
        ),
        GoRoute(
          path: '/syllable-practice',
          pageBuilder: (context, state) =>
              _slideTransition(state, const SyllablePracticeScreen()),
        ),
        GoRoute(
          path: '/word-reading',
          pageBuilder: (context, state) =>
              _slideTransition(state, const WordReadingScreen()),
        ),
        GoRoute(
          path: '/tajwid-course',
          pageBuilder: (context, state) =>
              _slideTransition(state, const TajwidCourseScreen()),
        ),
        GoRoute(
          path: '/daily-plan',
          pageBuilder: (context, state) =>
              _slideTransition(state, const DailyPlanScreen()),
        ),
        GoRoute(
          path: '/quiz',
          pageBuilder: (context, state) =>
              _slideTransition(state, const QuizScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              _slideTransition(state, const SettingsScreen()),
        ),
        GoRoute(
          path: '/feedback',
          pageBuilder: (context, state) =>
              _slideTransition(state, const FeedbackScreen()),
        ),
        GoRoute(
          path: '/faq',
          pageBuilder: (context, state) =>
              _slideTransition(state, const FaqScreen()),
        ),
        GoRoute(
          path: '/bookmarks',
          pageBuilder: (context, state) =>
              _slideTransition(state, const BookmarksScreen()),
        ),
        GoRoute(
          path: '/certificate',
          pageBuilder: (context, state) =>
              _slideTransition(state, const CertificateScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              _slideTransition(state, const SearchScreen()),
        ),
      ],
    );
  }

  static CustomTransitionPage _slideTransition(
      GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutQuart)),
          ),
          child: child,
        );
      },
    );
  }

}
