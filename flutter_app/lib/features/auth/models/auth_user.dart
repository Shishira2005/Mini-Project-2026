enum UserRole { faculty, representative, admin }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.faculty:
        return 'faculty';
      case UserRole.representative:
        return 'representative';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get title {
    switch (this) {
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.representative:
        return 'Representative';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get loginLabel {
    switch (this) {
      case UserRole.faculty:
        return 'Faculty ID Number';
      case UserRole.representative:
        return 'Admission Number';
      case UserRole.admin:
        return 'Admin ID';
    }
  }
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.role,
    required this.loginId,
    required this.name,
    required this.token,
    this.representativeType,
  });

  final String id;
  final UserRole role;
  final String loginId;
  final String name;
  final String token;
  final String? representativeType;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final role = UserRole.values.firstWhere(
      (entry) => entry.value == userJson['role'],
    );

    return AuthUser(
      id: userJson['id'] as String,
      role: role,
      loginId: userJson['loginId'] as String,
      name: userJson['name'] as String,
      token: json['token'] as String,
      representativeType: userJson['representativeType'] as String?,
    );
  }
}
