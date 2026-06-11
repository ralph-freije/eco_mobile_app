class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  // Override for Chrome or a physical phone with --dart-define=API_BASE_URL=...
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String dashboard = '/auth/dashboard';
  static const String activity = '/auth/activity';
  static const String notifications = '/auth/notifications';
  static const String notificationUnreadCount =
      '/auth/notifications/unread-count';
  static const String notificationReadAll = '/auth/notifications/read-all';
  static const String notificationDeleteAll =
      '/auth/notifications/delete-all';
  static const String profile = '/auth/profile';
  static const String communities = '/auth/communities';
  static const String usersSearch = '/auth/users/search';
  static const String privateConversations = '/auth/private-conversations';
  static const String mutualUsers = '/auth/private-chat/mutual-users';
  // TODO: Laravel must add this route before mobile Google auth can send
  // a Google ID token and exchange it for an EcoTrack Sanctum token.
  static const String googleMobile = '/auth/google/mobile';

  static String notificationRead(Object id) => '$notifications/$id/read';
  static String notification(Object id) => '$notifications/$id';
  static String followUser(Object id) => '/auth/users/$id/follow';
  static String unfollowUser(Object id) => '/auth/users/$id/unfollow';
  static String joinCommunity(Object id) => '$communities/$id/join';
  static String leaveCommunity(Object id) => '$communities/$id/leave';
  static String community(Object id) => '$communities/$id';
  static String communityImage(Object id) => '$communities/$id/image';
  static String communityGoals(Object id) => '$communities/$id/goals';
  static String communityMessages(Object id) => '$communities/$id/messages';
  static String communityMessagesRead(Object id) =>
      '$communities/$id/messages/mark-read';
  static String socialProfile(Object id) =>
      '/auth/users/$id/social-profile';
  static String startConversation(Object userId) =>
      '/auth/private-chat/users/$userId/start';
  static String privateMessages(Object conversationId) =>
      '$privateConversations/$conversationId/messages';
  static String privateMessagesRead(Object conversationId) =>
      '$privateConversations/$conversationId/mark-read';
  static const String profileAvatar = '/auth/profile/avatar';
}
