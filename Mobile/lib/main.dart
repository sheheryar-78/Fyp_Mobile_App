import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/settings_screen.dart';

// Global theme notifier — accessed by NexCallAppBar, HomeShell drawer, and SettingsScreen
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode');
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }

  runApp(const NexCallApp());
}

class NexCallApp extends StatelessWidget {
  const NexCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'NexCall',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: '/',
          routes: {
            '/':        (context) => const SplashScreen(),
            '/login':   (context) => const LoginScreen(),
            '/home':    (context) => const HomeShell(),
            '/billing': (context) => const BillingScreen(),
            '/settings':(context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
