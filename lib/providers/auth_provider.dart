import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _phoneNumber; // Store for OTP flow

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Check Auth Status on App Start
  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await StorageService.isLoggedIn();

      if (isLoggedIn) {
        final userData = await StorageService.getUserData();
        if (userData != null) {
          _user = User.fromJsonString(userData);
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? username,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        username: username,
      );

      if (result['success']) {
        _phoneNumber = phoneNumber; // Store for OTP verification
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      if (result['success'] == true) {
        final token = result['token'];
        if (token == null || token is! String || token.isEmpty) {
          _errorMessage = 'Login failed: missing token from server';
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        }

        _user = result['user'];
        await StorageService.saveToken(token);
        await StorageService.saveUserData(_user!.toJsonString());

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Send OTP
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _errorMessage = null;

      final result = await _authRepository.sendOtp(phoneNumber);

      if (result['success']) {
        _phoneNumber = phoneNumber;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.verifyOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (result['success']) {
        _user = result['user'];
        await StorageService.saveToken(result['token']);
        await StorageService.saveUserData(_user!.toJsonString());

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String phoneNumber) async {
    try {
      final result = await _authRepository.resendOtp(phoneNumber);

      if (!result['success']) {
        _errorMessage = result['message'];
        notifyListeners();
      }

      return result['success'];
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await StorageService.clearAll();
      _user = null;
      _phoneNumber = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear Error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
