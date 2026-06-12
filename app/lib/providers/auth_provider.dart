import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Authentication state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

/// Auth Provider for login, logout, and auto-login
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _pendingPhone;
  // ignore: unused_field
  String? _pendingRole;
  String? _error;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get pendingPhone => _pendingPhone;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isDriver => _user?.isDriver ?? false;
  bool get isShipper => _user?.isShipper ?? false;

  /// Initialize auth - check for existing session
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isAuth = await _storageService.isAuthenticated();

      if (isAuth) {
        // Try to get cached user
        _user = await _storageService.getUser();

        if (_user != null) {
          // Optionally refresh user profile from server
          await _refreshProfile();
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      if (kDebugMode) print('Auth init error: $e');
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Send OTP to phone number
  Future<bool> sendOtp(String phone, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {'phone': phone, 'role': role},
      );

      _isLoading = false;

      if (response.isSuccess) {
        _pendingPhone = phone;
        _pendingRole = role;
        _status = AuthStatus.otpSent;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and login
  Future<bool> verifyOtp(String otp, {String? role}) async {
    if (_pendingPhone == null) {
      _error = 'Phone number not set';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.verifyOtp,
        data: {
          'phone': _pendingPhone,
          'otp': otp,
          if (role != null) 'role': role,
        },
      );

      _isLoading = false;

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as Map<String, dynamic>;

        // Save token
        final token = data['token'] as String?;
        if (token != null) {
          await _storageService.saveToken(token);
        }

        // Parse and save user
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          await _storageService.saveUser(_user!);
        }

        _status = AuthStatus.authenticated;
        _pendingPhone = null;
        _pendingRole = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'OTP verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Refresh user profile from server
  Future<void> _refreshProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.profile);

      if (response.isSuccess && response.rawData != null) {
        _user = UserModel.fromJson(response.rawData as Map<String, dynamic>);
        await _storageService.saveUser(_user!);
      }
    } catch (e) {
      if (kDebugMode) print('Profile refresh error: $e');
    }
  }

  /// Refresh profile (public)
  Future<void> refreshProfile() async {
    await _refreshProfile();
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _storageService.clearAll();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    _isLoading = false;

    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Go back to login screen (from OTP screen)
  void goBackToLogin() {
    _pendingPhone = null;
    _pendingRole = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }
}
