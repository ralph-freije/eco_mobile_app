class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.profile = const {},
  });

  final int id;
  final String name;
  final String email;
  final Map<String, dynamic> profile;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    return AuthUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'EcoTrack user',
      email: json['email']?.toString() ?? '',
      profile: rawProfile is Map
          ? Map<String, dynamic>.from(rawProfile)
          : const {},
    );
  }
}
