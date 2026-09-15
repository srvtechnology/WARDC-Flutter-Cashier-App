import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../utils/api_logger.dart';

enum UserType { assessmentOfficer, cashier }

class AuthService {
  AuthService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          contentType: ApiConfig.contentType,
          connectTimeout: ApiConfig.timeout,
          receiveTimeout: ApiConfig.timeout,
          sendTimeout: ApiConfig.timeout,
        ),
      ) {
    _dio.interceptors.add(ApiLoggerInterceptor());
  }

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  static const String _kTokenKey = 'auth_token';
  static const String _kUserTypeKey = 'user_type';
  static const String _kUserEmailKey = 'user_email';

  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Endpoints
  static const String _assessmentLoginPath = '/assesment-app-user-login';
  static const String _cashierLoginPath = '/payment-app-user-login';
  static const String _logoutPath = '/app-user-logout';
  static const String _getUserPath = '/user-get';
  static const String _updateProfilePath = '/update-profile-for-assement-app';
  static const String _changePasswordPath = '/change-password-for-assement-app';

  Future<String> login({
    required String email,
    required String password,
    required UserType type,
  }) async {
    final String path = type == UserType.assessmentOfficer
        ? _assessmentLoginPath
        : _cashierLoginPath;

    try {
      final Response<dynamic> response = await _dio.post(
        path,
        data: <String, dynamic>{'email': email, 'password': password},
        options: Options(
          headers: <String, String>{'Accept': 'application/json'},
        ),
      );

      final Map<String, dynamic> body = _asJson(response.data);
      final bool success = body['success'] == true;
      if (!success || body['token'] == null) {
        throw AuthException(_extractMessage(body));
      }

      final String token = body['token'] as String;
      await _storeAuth(token: token, type: type, email: email);
      return token;
    } on DioException catch (e) {
      throw AuthException(_mapDioError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await remoteLogout();
    } catch (_) {
      // Even if remote logout fails, proceed to clear local sensitive data
    } finally {
      await _secureStorage.delete(key: _kTokenKey);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserTypeKey);
      await prefs.remove(_kUserEmailKey);
      // Optionally clear local drafts when logging out
      try {
        // Lazily import Hive to avoid hard dependency here
        // ignore: avoid_dynamic_calls
      } catch (_) {}
    }
  }

  Future<void> remoteLogout() async {
    final String? token = await getToken();
    try {
      await _dio.post(
        _logoutPath,
        data: <String, dynamic>{},
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw AuthException(_mapDioError(e));
    }
  }

  Future<String?> getToken() => _secureStorage.read(key: _kTokenKey);

  Future<UserType?> getSavedUserType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_kUserTypeKey);
    switch (value) {
      case 'assessment_officer':
        return UserType.assessmentOfficer;
      case 'cashier':
        return UserType.cashier;
      default:
        return null;
    }
  }

  Future<String?> getSavedUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserEmailKey);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final String? token = await getToken();
    try {
      final Response<dynamic> response = await _dio.get(
        _getUserPath,
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      final Map<String, dynamic> body = _asJson(response.data);
      return body;
    } on DioException catch (e) {
      throw AuthException(_mapDioError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String gender,
  }) async {
    final String? token = await getToken();
    try {
      final Response<dynamic> response = await _dio.post(
        _updateProfilePath,
        data: <String, dynamic>{
          'name': name,
          'email': email,
          'gender': gender.toLowerCase(),
        },
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      final Map<String, dynamic> body = _asJson(response.data);
      
      // Update saved email if profile update is successful
      if (body['success'] == true && body['data'] != null) {
        final updatedData = _asJson(body['data']);
        final updatedEmail = updatedData['email']?.toString();
        if (updatedEmail != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kUserEmailKey, updatedEmail);
        }
      }
      
      return body;
    } on DioException catch (e) {
      throw AuthException(_mapDioError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final String? token = await getToken();
    try {
      final Response<dynamic> response = await _dio.post(
        _changePasswordPath,
        data: <String, dynamic>{
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      final Map<String, dynamic> body = _asJson(response.data);
      return body;
    } on DioException catch (e) {
      throw AuthException(_mapDioError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> _storeAuth({
    required String token,
    required UserType type,
    required String email,
  }) async {
    await _secureStorage.write(key: _kTokenKey, value: token);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kUserTypeKey,
      type == UserType.assessmentOfficer ? 'assessment_officer' : 'cashier',
    );
    await prefs.setString(_kUserEmailKey, email);
  }

  Map<String, dynamic> _asJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _extractMessage(Map<String, dynamic> body) {
    final dynamic message = body['message'];
    if (message is String) return message;
    return 'Unexpected response';
  }

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Check your network and try again.';
    }
    if (e.response != null) {
      try {
        final Map<String, dynamic> data = _asJson(e.response!.data);
        final String msg = _extractMessage(data);
        return msg.isNotEmpty ? msg : 'Invalid credentials';
      } catch (_) {
        return 'Something went wrong (${e.response!.statusCode}).';
      }
    }
    if (kDebugMode) {
      return 'Unexpected error: ${e.message}';
    }
    return 'Unexpected error occurred.';
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
