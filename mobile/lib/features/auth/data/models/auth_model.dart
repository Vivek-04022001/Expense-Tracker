class UserModel {
  final String id;
  final String name;
  final String phone;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
      );
}

// POST /auth/login → { accessToken, refreshToken }
class LoginResponse {
  final String accessToken;
  final String refreshToken;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

// POST /auth/register → { message, userId }
class RegisterResponse {
  final String message;
  final String userId;

  const RegisterResponse({
    required this.message,
    required this.userId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        message: json['message'] as String,
        userId: json['userId'] as String,
      );
}
