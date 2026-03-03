enum UserRole { admin, kasir}

class AppUser {
  final String id;
  String username;
  String password;
  UserRole role;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role
  });

  AppUser copyWith({
    String? id,
    String? username,
    String? password,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}