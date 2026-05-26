import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/select_role_screen.dart';
import '../features/auth/screens/complete_profile_screen.dart';
import '../features/passenger/screens/passenger_home_screen.dart';
import '../features/driver/screens/driver_home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = auth.firebaseUser != null;
    final hasProfile = auth.userModel != null;

    if (!isLoggedIn) return '/login';
    if (isLoggedIn && !hasProfile) return '/select-role';
    if (auth.userModel?.role == 'passenger') return '/passenger';
    if (auth.userModel?.role == 'driver') return '/driver';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/select-role', builder: (_, __) => const SelectRoleScreen()),
    GoRoute(path: '/complete-profile', builder: (_, __) => const CompleteProfileScreen()),
    GoRoute(path: '/passenger', builder: (_, __) => const PassengerHomeScreen()),
    GoRoute(path: '/driver', builder: (_, __) => const DriverHomeScreen()),
  ],
);