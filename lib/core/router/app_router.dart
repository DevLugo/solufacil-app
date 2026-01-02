import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../ui/pages/onboarding_page.dart';
import '../../ui/pages/login_page.dart';
import '../../ui/pages/dashboard_page.dart';
import '../../ui/pages/client_history_page.dart';
import '../../ui/pages/critical_clients_page.dart';
import '../../ui/pages/collection/select_location_page.dart';
import '../../ui/pages/collection/client_list_page.dart';
import '../../ui/pages/collection/register_payment_page.dart';

/// Route paths
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String clientHistory = '/client-history';

  // Collection flow
  static const String selectLocation = '/collect/location';
  static const String clientList = '/collect/clients';
  static const String registerPayment = '/collect/payment';

  // Create credit wizard
  static const String createCredit = '/create-credit';

  // Critical clients (week 4+ without paying)
  static const String criticalClients = '/critical-clients';

  // Other
  static const String clients = '/clients';
  static const String reports = '/reports';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated
        ? AppRoutes.dashboard
        : AppRoutes.onboarding,
    debugLogDiagnostics: true,

    // Redirect logic
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isLogin = state.matchedLocation == AppRoutes.login;

      // If not authenticated, allow onboarding and login
      if (!isAuthenticated) {
        if (isOnboarding || isLogin) {
          return null;
        }
        return AppRoutes.login;
      }

      // If authenticated and trying to access onboarding/login, redirect to dashboard
      if (isAuthenticated && (isOnboarding || isLogin)) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // Dashboard (main screen with bottom nav)
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),

      // Client History (search clients)
      GoRoute(
        path: AppRoutes.clientHistory,
        builder: (context, state) => const ClientHistoryPage(),
      ),

      // Collection flow
      GoRoute(
        path: AppRoutes.selectLocation,
        builder: (context, state) => const SelectLocationPage(),
      ),
      GoRoute(
        path: AppRoutes.clientList,
        builder: (context, state) {
          final locationId = state.uri.queryParameters['locationId'];
          return ClientListPage(locationId: locationId);
        },
      ),
      GoRoute(
        path: AppRoutes.registerPayment,
        builder: (context, state) {
          final loanId = state.uri.queryParameters['loanId'];
          return RegisterPaymentPage(loanId: loanId);
        },
      ),

      // Critical clients page
      GoRoute(
        path: AppRoutes.criticalClients,
        builder: (context, state) => const CriticalClientsPage(),
      ),

      // Clients page (redirects to client history for now)
      GoRoute(
        path: AppRoutes.clients,
        builder: (context, state) => const ClientHistoryPage(),
      ),

      // Reports (placeholder)
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Reportes - Coming soon')),
        ),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
