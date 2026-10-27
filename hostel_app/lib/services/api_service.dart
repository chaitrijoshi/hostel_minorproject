import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
class ApiService {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'role';
  static const _kUsername = 'username';
  static const _kUserId = 'user_id';

  static Future<void> _saveSession(
      Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _kAccess,
      data['access'].toString(),
    );

    await prefs.setString(
      _kRefresh,
      data['refresh'].toString(),
    );

    await prefs.setString(
      _kRole,
      data['role'].toString(),
    );

    await prefs.setString(
      _kUsername,
      data['username'].toString(),
    );

    if (data['user_id'] != null) {
      await prefs.setInt(
        _kUserId,
        data['user_id'],
      );
    }
  }


  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }


  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }


  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }


  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsername);
  }


  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();

    return token != null && token.isNotEmpty;
  }


  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/login/',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      await _saveSession(data);

      return data;
    }

    throw ApiException(
      _extractError(response),
    );
  }


  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  static Future<void> changePassword({
    String? newUsername,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final body = {
      if (newUsername != null && newUsername.isNotEmpty)
        'new_username': newUsername,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    };

    await post(
      '/api/auth/change-password/',
      body,
    );

    if (newUsername != null &&
        newUsername.isNotEmpty) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _kUsername,
        newUsername,
      );
    }
  }


  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  static Future<bool> _tryRefresh() async {
    final refresh = await getRefreshToken();

    if (refresh == null || refresh.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/token/refresh/',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh': refresh,
      }),
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _kAccess,
        data['access'].toString(),
      );

      if (data['refresh'] != null) {
        await prefs.setString(
          _kRefresh,
          data['refresh'].toString(),
        );
      }

      return true;
    }

    return false;
  }


  // ============================================================
  // COMMON REQUEST
  // ============================================================

  static Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final token = await getAccessToken();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    );

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    late http.Response response;

    if (method == 'GET') {
      response = await http.get(
        uri,
        headers: headers,
      );
    } else if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } else if (method == 'PATCH') {
      response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } else {
      throw ApiException(
        'Unsupported HTTP method.',
      );
    }


    // Refresh token if access token expired
    if (response.statusCode == 401 && retry) {
      final refreshed = await _tryRefresh();

      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          retry: false,
        );
      }

      await logout();

      throw ApiException(
        'Session expired. Please log in again.',
      );
    }

    return response;
  }


  // ============================================================
  // GET
  // ============================================================

  static Future<dynamic> get(String path) async {
    final response = await _request(
      'GET',
      path,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw ApiException(
      _extractError(response),
    );
  }


  // ============================================================
  // POST
  // ============================================================

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _request(
      'POST',
      path,
      body: body,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw ApiException(
      _extractError(response),
    );
  }


  // ============================================================
  // PATCH
  // ============================================================

  static Future<dynamic> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _request(
      'PATCH',
      path,
      body: body,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw ApiException(
      _extractError(response),
    );
  }


  // ============================================================
  // ERROR
  // ============================================================

  static String _extractError(
      http.Response response) {
    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        if (decoded.containsKey('detail')) {
          return decoded['detail'].toString();
        }

        final parts = <String>[];

        decoded.forEach((key, value) {
          if (value is List) {
            parts.add(
              '$key: ${value.join(', ')}',
            );
          } else {
            parts.add(
              '$key: $value',
            );
          }
        });

        if (parts.isNotEmpty) {
          return parts.join('\n');
        }
      }
    } catch (_) {}

    return 'Request failed (${response.statusCode})';
  }
}