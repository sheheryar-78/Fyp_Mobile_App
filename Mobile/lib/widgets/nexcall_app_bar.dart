import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/home_shell_key.dart';

// Imported from main.dart – avoids circular imports by referencing the global.
// The global themeNotifier is defined in main.dart.
import '../main.dart' show themeNotifier;

/// Shared [AppBar] for all main tab screens (Dashboard, Agents, Calls, Documents).
/// Provides the hamburger menu that opens the [HomeShell] drawer and a theme toggle.
class NexCallAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const NexCallAppBar({super.key, required this.title, this.extraActions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Menu',
        onPressed: () => homeShellScaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(title),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (ctx, mode, _) => IconButton(
            tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(mode),
              ),
            ),
            onPressed: () async {
              final newMode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              themeNotifier.value = newMode;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('themeMode', newMode == ThemeMode.dark ? 'dark' : 'light');
            },
          ),
        ),
        if (extraActions != null) ...extraActions!,
      ],
    );
  }
}
