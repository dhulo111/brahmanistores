import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/main_layout.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/verification/screens/verification_screen.dart';
import '../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: _getInitialLocation(),
    redirect: (context, state) {
      final targetPath = state.uri.path;
      final isOnboarding = targetPath == '/onboarding';
      final isLogin = targetPath == '/login';
      final isRegister = targetPath == '/register';
      
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAdmin = authState.user?.role == 'ADMIN';

      // Unauthenticated flows
      if (!isLoggedIn) {
        if (!isOnboarding && !isLogin && !isRegister) {
          return '/onboarding';
        }
        return null;
      }

      // Authenticated flows
      if (isLoggedIn) {
        if (isLogin || isRegister || isOnboarding) {
          return '/';
        }
        
        if (targetPath == '/verification' && !isAdmin) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final googleData = state.extra as Map<String, dynamic>?;
          return RegisterScreen(googleData: googleData);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/verification',
                builder: (context, state) => const VerificationScreen(),
              ),
            ],
          ),
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

  ref.listen(
    authProvider.select((state) => state.isAuthenticated),
    (previous, next) {
      if (previous != next) {
        router.refresh();
      }
    },
  );

  return router;
});

String _getInitialLocation() {
  return '/onboarding';
}
