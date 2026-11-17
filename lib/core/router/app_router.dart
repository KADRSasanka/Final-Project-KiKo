import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activities/screens/activity_host_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/screens/create_profile_screen.dart';
import '../../features/profile/screens/profile_picker_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/tracks/screens/level_intro_screen.dart';
import '../../features/tracks/screens/track_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;

      final loggedIn = auth.valueOrNull != null;
      final location = state.matchedLocation;

      if (location == AppRoutes.splash) return null; // splash moves on itself
      if (!loggedIn && location != AppRoutes.signIn) return AppRoutes.signIn;
      if (loggedIn && location == AppRoutes.signIn) return AppRoutes.profiles;

      // Main screens and tracks need a chosen player.
      final hasPlayer = ref.read(activeChildIdProvider) != null;
      final needsPlayer = location == AppRoutes.home ||
          location == AppRoutes.rewards ||
          location == AppRoutes.shop ||
          location.startsWith('/track/');
      if (loggedIn && needsPlayer && !hasPlayer) return AppRoutes.profiles;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.profiles,
        builder: (context, state) => const ProfilePickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.createProfile,
        builder: (context, state) => const CreateProfileScreen(),
      ),
      // Tabs with a bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.rewards,
              builder: (context, state) => const RewardsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.shop,
              builder: (context, state) => const ShopScreen(),
            ),
          ]),
        ],
      ),
      // Full-screen routes (hide the bottom bar)
      GoRoute(
        path: AppRoutes.track,
        builder: (context, state) =>
            TrackScreen(trackId: state.pathParameters['trackId']!),
      ),
      GoRoute(
        path: AppRoutes.level,
        builder: (context, state) => LevelIntroScreen(
          trackId: state.pathParameters['trackId']!,
          levelId: state.pathParameters['levelId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.play,
        builder: (context, state) => ActivityHostScreen(
          trackId: state.pathParameters['trackId']!,
          levelId: state.pathParameters['levelId']!,
        ),
      ),
    ],
  );
});
