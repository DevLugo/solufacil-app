import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/collector_dashboard_provider.dart';
import '../../ui/pages/onboarding_page.dart';
import '../../ui/pages/login_page.dart';
import '../../ui/pages/dashboard_page.dart';
import '../../ui/pages/client_history_page.dart';
import '../../ui/pages/critical_clients_page.dart';
import '../../ui/pages/collection/select_location_page.dart';
import '../../ui/pages/collection/client_list_page.dart';
import '../../ui/pages/collection/register_payment_page.dart';
import '../../ui/pages/create_credit/create_credit_page.dart';
import '../../ui/pages/credits_page.dart';
import '../../ui/pages/jornada_page.dart';

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
  static const String creditsToday = '/credits-today';

  // Critical clients (week 4+ without paying)
  static const String criticalClients = '/critical-clients';

  // Jornada - daily summary
  static const String jornada = '/jornada';

  // Other
  static const String clients = '/clients';
  static const String reports = '/reports';
}

/// Auth state notifier for router refresh
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
    _ref.listen(selectedLeadProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

/// Router provider - stable instance that reacts to auth changes via refreshListenable
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,

    // Redirect logic
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final selectedLead = ref.read(selectedLeadProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final hasLocalitySelected = selectedLead != null;
      final currentPath = state.matchedLocation;

      // Public routes (no auth required)
      final isOnboarding = currentPath == AppRoutes.onboarding;
      final isLogin = currentPath == AppRoutes.login;

      // Routes that require a locality to be selected
      final isOperationRoute = currentPath == AppRoutes.createCredit ||
          currentPath == AppRoutes.selectLocation ||
          currentPath == AppRoutes.clientList ||
          currentPath == AppRoutes.registerPayment ||
          currentPath == AppRoutes.creditsToday;

      // During loading, don't redirect - stay on current page
      if (isLoading) {
        return null;
      }

      // If authenticated, redirect from onboarding/login to dashboard
      if (isAuthenticated) {
        if (isOnboarding || isLogin) {
          return AppRoutes.dashboard;
        }
        // Continue to other checks below
      } else {
        // Not authenticated - allow onboarding and login, redirect others to login
        if (isOnboarding || isLogin) {
          return null;
        }
        return AppRoutes.login;
      }

      // If trying to perform operations without a locality selected, redirect to dashboard
      // The dashboard will show the message to select a locality
      if (isAuthenticated && !hasLocalitySelected && isOperationRoute) {
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

      // Create credit wizard
      GoRoute(
        path: AppRoutes.createCredit,
        builder: (context, state) => const CreateCreditPage(),
      ),

      // Credits today page
      GoRoute(
        path: AppRoutes.creditsToday,
        builder: (context, state) => const CreditsPage(),
      ),

      // Jornada - daily summary
      GoRoute(
        path: AppRoutes.jornada,
        builder: (context, state) => const JornadaPage(),
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
