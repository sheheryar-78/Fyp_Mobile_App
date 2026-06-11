import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/agents_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/call_history_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexCallApp());
}

class NexCallApp extends StatelessWidget {
  const NexCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexCall Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Primary Blue
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF3B82F6),
          surface: Colors.white,
          error: const Color(0xFFEF4444),
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/agents': (context) => const AgentsScreen(),
        '/documents': (context) => const DocumentsScreen(),
        '/calls': (context) => const CallHistoryScreen(),
        '/billing': (context) => const BillingScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

// Global Drawer Navigation widget for NexCall screens
class AppNavigationDrawer extends StatelessWidget {
  final String currentRoute;

  const AppNavigationDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NexCall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI Voice Platform',
                      style: TextStyle(
                        color: Color(0xFFDBEAFE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          _buildItem(context, 'Dashboard', Icons.dashboard_outlined, '/dashboard'),
          _buildItem(context, 'AI Agents', Icons.smart_toy_outlined, '/agents'),
          _buildItem(context, 'Documents', Icons.description_outlined, '/documents'),
          _buildItem(context, 'Call History', Icons.phone_callback_outlined, '/calls'),
          _buildItem(context, 'Billing & Plans', Icons.credit_card_outlined, '/billing'),
          _buildItem(context, 'Settings', Icons.settings_outlined, '/settings'),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              // Sign out logic
              await SharedPreferencesHelper.clearToken();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String route) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context); // close drawer
        }
      },
    );
  }
}

// Temporary helper to avoid import loops
class SharedPreferencesHelper {
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}

