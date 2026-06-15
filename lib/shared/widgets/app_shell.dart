import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/theme_controller.dart';
import '../../core/theme/app_theme.dart';
import 'ecotrack_logo.dart';
import 'theme_mode_selector.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _mainRoutes = [
    '/dashboard',
    '/track',
    '/activity',
    '/messages',
  ];

  static const _menuRoutes = {
    '/history',
    '/communities',
    '/people',
    '/notifications',
    '/settings',
  };

  int _unreadCount = 0;
  Timer? _badgeTimer;

  int get _selectedIndex {
    final mainIndex = _mainRoutes.indexWhere(
      (route) => widget.currentLocation == route ||
          widget.currentLocation.startsWith('$route/'),
    );
    if (mainIndex >= 0) return mainIndex;
    if (_menuRoutes.any(
      (route) => widget.currentLocation == route ||
          widget.currentLocation.startsWith('$route/'),
    )) {
      return 4;
    }
    return 0;
  }

  String get _title {
    if (widget.currentLocation.startsWith('/messages/')) return 'Conversation';
    if (widget.currentLocation.startsWith('/communities/')) {
      return 'Community';
    }
    return switch (widget.currentLocation) {
        '/dashboard' => 'Dashboard',
        '/track' => 'Impact Tracking',
        '/activity' => 'Activities',
        '/messages' => 'Messages',
        '/settings' => 'Settings',
        '/history' => 'History',
        '/communities' => 'Communities',
        '/people' => 'People',
        '/notifications' => 'Notifications',
      _ => 'EcoTrack',
    };
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadUnreadCount(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final body = await ApiClient.instance.get(
        ApiConstants.notificationUnreadCount,
      );
      final count = body is Map
          ? int.tryParse(body['unread_count']?.toString() ?? '') ?? 0
          : 0;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // A badge failure should not block navigation or page content.
    }
  }

  void _selectDestination(int index) {
    if (index == 4) {
      _showMenu();
      return;
    }
    context.go(_mainRoutes[index]);
  }

  Future<void> _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AppMenu(
        currentLocation: widget.currentLocation,
        unreadCount: _unreadCount,
        onNavigate: (route) {
          Navigator.pop(sheetContext);
          context.go(route);
        },
        onLogout: () async {
          Navigator.pop(sheetContext);
          await context.read<AuthController>().logout();
        },
      ),
    );
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        title: widget.currentLocation == '/dashboard'
            ? const EcoTrackLogo(compact: true)
            : Text(_title),
        actions: [
          IconButton(
            tooltip: isDark ? 'Use light theme' : 'Use dark theme',
            onPressed: () =>
                context.read<ThemeController>().toggleBrightness(context),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          _NotificationButton(
            count: _unreadCount,
            onPressed: () => context.go('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: widget.child,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: isDark ? 0.9 : 0.88),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 66,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard_rounded),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined),
                    selectedIcon: Icon(Icons.route_rounded),
                    label: 'Track',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add_circle_outline_rounded),
                    selectedIcon: Icon(Icons.add_circle_rounded),
                    label: 'Activity',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Menu',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class _AppMenu extends StatelessWidget {
  const _AppMenu({
    required this.currentLocation,
    required this.unreadCount,
    required this.onNavigate,
    required this.onLogout,
  });

  final String currentLocation;
  final int unreadCount;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = [
      const _MenuItem('/history', 'History', Icons.history_rounded),
      const _MenuItem('/communities', 'Communities', Icons.groups_rounded),
      const _MenuItem('/people', 'People', Icons.people_alt_rounded),
      _MenuItem(
        '/notifications',
        'Notifications',
        Icons.notifications_rounded,
        badge: unreadCount,
      ),
      const _MenuItem('/settings', 'Settings', Icons.settings_rounded),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const EcoTrackLogo(compact: true),
                const Spacer(),
                Text(
                  'Explore',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = currentLocation == item.route;
                return Material(
                  color: selected
                      ? colors.primaryContainer
                      : colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onNavigate(item.route),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Badge(
                            isLabelVisible: item.badge > 0,
                            label: Text('${item.badge}'),
                            child: Icon(
                              item.icon,
                              color: selected
                                  ? colors.onPrimaryContainer
                                  : colors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              width: double.infinity,
              child: ThemeModeSelector(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.route, this.label, this.icon, {this.badge = 0});

  final String route;
  final String label;
  final IconData icon;
  final int badge;
}
