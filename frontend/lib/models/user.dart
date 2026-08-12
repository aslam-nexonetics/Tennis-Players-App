class User {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final bool isActive;
  final bool isSuperuser;
  final bool isVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.isActive,
    required this.isSuperuser,
    required this.isVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? email,
    String? username,
    String? fullName,
    bool? isActive,
    bool? isSuperuser,
    bool? isVerified,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}

class AuthTokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final User? user;

  AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    this.user,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 1800,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
