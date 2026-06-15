import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/state/auth_controller.dart';
import 'core/state/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/activity/screens/activity_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/communities/screens/communities_screen.dart';
import 'features/communities/screens/community_detail_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/messages/screens/messages_screen.dart';
import 'features/messages/screens/private_chat_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/people/screens/people_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/track/screens/track_screen.dart';
import 'shared/widgets/app_shell.dart';

class EcoTrackApp extends StatefulWidget {
  const EcoTrackApp({
    required this.authController,
    required this.themeController,
    super.key,
  });

  final AuthController authController;
  final ThemeController themeController;

  @override
  State<EcoTrackApp> createState() => _EcoTrackAppState();
}

class _EcoTrackAppState extends State<EcoTrackApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: widget.authController,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      if (!widget.authController.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }
      return isAuthRoute ? '/dashboard' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
          GoRoute(path: '/activity', builder: (context, state) => const ActivityScreen()),
          GoRoute(path: '/messages', builder: (context, state) => const MessagesScreen()),
          GoRoute(
            path: '/messages/:conversationId',
            builder: (context, state) => PrivateChatScreen(
              conversationId: state.pathParameters['conversationId']!,
              title: state.uri.queryParameters['name'] ?? 'Conversation',
            ),
          ),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/communities', builder: (context, state) => const CommunitiesScreen()),
          GoRoute(
            path: '/communities/:communityId',
            builder: (context, state) => CommunityDetailScreen(
              communityId: state.pathParameters['communityId']!,
            ),
          ),
          GoRoute(path: '/people', builder: (context, state) => const PeopleScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authController),
        ChangeNotifierProvider.value(value: widget.themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) => MaterialApp.router(
          title: 'EcoTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
