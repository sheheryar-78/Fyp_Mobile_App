import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/dashboard_screen.dart';
import '../screens/agents_screen.dart';
import '../screens/call_history_screen.dart';
import '../screens/documents_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/home_shell_key.dart';
import '../main.dart' show themeNotifier;

/// Main shell widget providing Bottom Navigation + Drawer for primary screens.
/// Secondary screens (Billing, Settings) are pushed as named routes on top.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // Using IndexedStack to preserve state across tab switches
  static const List<Widget> _screens = [
    DashboardScreen(),
    AgentsScreen(),
    CallHistoryScreen(),
    DocumentsScreen(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'AI Agents',
    'Call History',
    'Documents',
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: homeShellScaffoldKey,
      drawer: _buildDrawer(context, isDark),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: 'Agents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_callback_outlined),
              activeIcon: Icon(Icons.phone_callback_rounded),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'Documents',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Drawer ───────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: Column(
        children: [
          // Header with gradient
          _buildDrawerHeader(context),

          const SizedBox(height: 8),

          // Primary tab items (synced with bottom nav)
          _TabDrawerItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            tabIndex: 0,
            selectedIndex: _selectedIndex,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(0);
            },
          ),
          _TabDrawerItem(
            title: 'AI Agents',
            icon: Icons.smart_toy_outlined,
            activeIcon: Icons.smart_toy_rounded,
            tabIndex: 1,
            selectedIndex: _selectedIndex,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(1);
            },
          ),
          _TabDrawerItem(
            title: 'Call History',
            icon: Icons.phone_callback_outlined,
            activeIcon: Icons.phone_callback_rounded,
            tabIndex: 2,
            selectedIndex: _selectedIndex,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(2);
            },
          ),
          _TabDrawerItem(
            title: 'Documents',
            icon: Icons.description_outlined,
            activeIcon: Icons.description_rounded,
            tabIndex: 3,
            selectedIndex: _selectedIndex,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(3);
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),

          // Secondary routes
          _RouteDrawerItem(
            title: 'Billing & Plans',
            icon: Icons.credit_card_outlined,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/billing');
            },
          ),
          _RouteDrawerItem(
            title: 'Settings',
            icon: Icons.settings_outlined,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          // Dark mode toggle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (ctx, mode, _) => ListTile(
              leading: Icon(
                mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppTheme.textSecondary,
              ),
              title: Text(
                mode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Switch(
                value: mode == ThemeMode.dark,
                onChanged: (val) async {
                  final newMode = val ? ThemeMode.dark : ThemeMode.light;
                  themeNotifier.value = newMode;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('themeMode', val ? 'dark' : 'light');
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const Spacer(),
          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () async {
              Navigator.pop(context);
              await ApiService.clearAuth();
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

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'NexCall',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'AI Voice Agent Platform',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Item Widgets ──────────────────────────────────────────────────────

class _TabDrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final int tabIndex;
  final int selectedIndex;
  final VoidCallback onTap;

  const _TabDrawerItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.tabIndex,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == tabIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryBlue : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryBlueXLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}

class _RouteDrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _RouteDrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
