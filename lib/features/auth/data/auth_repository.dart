import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> restoreSession();
  Future<UserProfile> signIn({required String email, required String password});
  Future<UserProfile> signUp({required String email, required String password, required String displayName});
  Future<void> sendPasswordReset(String email);
  Future<void> updateOnboardingPreferences({
    required List<String> goals,
    required int dailyMinutes,
    required List<String> topicInterests,
    required String preferredVoice,
    required String feedbackLanguage,
  });
  Future<void> signOut();
  Future<bool> isOnboarded();
}

class LocalAuthRepository implements AuthRepository {
  static const String _keyUser = 'fluent_user_session';
  static const String _keyToken = 'fluent_auth_token';
  static const String _keyOnboarded = 'fluent_is_onboarded';
  static const String keyRegisteredUsers = 'fluent_registered_users';

  /// Get list of all registered accounts from local persistence
  static Future<List<UserProfile>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyRegisteredUsers);
    final List<UserProfile> list = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final raw = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            list.add(UserProfile.fromJson(item));
          }
        }
      } catch (_) {}
    }
    // Also include active session user if not already present
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      try {
        final current = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        if (!list.any((u) => u.email.toLowerCase() == current.email.toLowerCase())) {
          list.insert(0, current);
        }
      } catch (_) {}
    }
    return list;
  }

  /// Save or update a registered account in local persistence
  static Future<void> saveRegisteredUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    final idx = users.indexWhere((u) => u.email.toLowerCase() == user.email.toLowerCase());
    if (idx != -1) {
      users[idx] = user;
    } else {
      users.insert(0, user);
    }
    final rawList = users.map((u) => u.toJson()).toList();
    await prefs.setString(keyRegisteredUsers, jsonEncode(rawList));
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    final token = prefs.getString(_keyToken);

    if (userJson != null && token != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return UserProfile.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    // Simulate network authentication delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Input validation checks
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Địa chỉ email không đúng định dạng.');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải chứa ít nhất 6 ký tự.');
    }

    final users = await getRegisteredUsers();
    final existingIndex = users.indexWhere((u) => u.email.toLowerCase() == email.toLowerCase());

    final user = existingIndex != -1
        ? users[existingIndex]
        : UserProfile(
            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            displayName: email.split('@').first,
            level: UserLevel.a2,
            dailyMinutes: 15,
            currentStreak: 1,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setString(_keyToken, 'mock_jwt_token_${user.id}');
    await prefs.setBool(_keyOnboarded, true);
    await saveRegisteredUser(user);

    return user;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Địa chỉ email không đúng định dạng.');
    }
    if (password.length < 8) {
      throw Exception('Mật khẩu tối thiểu phải từ 8 ký tự trở lên.');
    }

    final user = UserProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'Người học mới',
      level: UserLevel.a1,
      dailyMinutes: 15,
      currentStreak: 0,
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setString(_keyToken, 'mock_jwt_token_${user.id}');
    await prefs.setBool(_keyOnboarded, false);
    await saveRegisteredUser(user);

    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) {
      throw Exception('Vui lòng nhập địa chỉ email hợp lệ để nhận liên kết khôi phục.');
    }
  }

  @override
  Future<void> updateOnboardingPreferences({
    required List<String> goals,
    required int dailyMinutes,
    required List<String> topicInterests,
    required String preferredVoice,
    required String feedbackLanguage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);

    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserProfile.fromJson(map);
      final updatedUser = user.copyWith(
        dailyMinutes: dailyMinutes,
      );
      await prefs.setString(_keyUser, jsonEncode(updatedUser.toJson()));
      await saveRegisteredUser(updatedUser);
    }
  }

  @override
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyOnboarded);
  }
}
