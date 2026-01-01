import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/client_history_page.dart';

class SoluFacilApp extends ConsumerWidget {
  const SoluFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'SoluFácil',
      debugShowCheckedModeBanner: false,

      // Premium Dark Theme
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Initial route based on auth state
      initialRoute: authState.isAuthenticated ? '/client-history' : '/login',

      // Route definitions
      routes: {
        '/login': (context) => const LoginPage(),
        '/client-history': (context) => const ClientHistoryPage(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}
