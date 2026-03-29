// lib/data/repositories/auth_repository.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // Register User
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.register,
        body: {
          // Backend (per API/Postman) expects these keys:
          'name': fullName,
          'email': email,
          'phone': phoneNumber,
          'password': password,
          if (username != null) 'username': username,

          // Compatibility keys (in case backend uses different naming):
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      return {
        'success': true,
        'message': response['message'] ?? 'Registration successful',
        'data': response,
        'token': response['token'] ??
            response['data']?['token'] ??
            response['access_token'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Login User
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // Backend expects 'login' field (per API documentation)
      final loginFields = {
        'login': emailOrPhone,
        'password': password,
      };

      // Use standard POST with JSON body
      final response = await _apiService.post(
        ApiConstants.login,
        body: loginFields,
      );

      // Parse user from response
      // Backend returns user data directly in 'data' object
      final userData = response['data'] ?? response['user'] ?? {};
      final user = User.fromJson(userData);

      final token = response['token'] ??
          response['data']?['access_token'] ??
          response['access_token'] ??
          response['data']?['token'];

      if (token != null) {
        _apiService.setAuthToken(token);
      } else {
        return {
          'success': false,
          'message': 'Login failed: token missing in response',
        };
      }

      return {
        'success': true,
        'user': user,
        'token': token,
        'message': response['message'] ?? 'Login successful',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Get FCM token safely (may not be available on simulators)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print('📱 FCM Token: $fcmToken');
        }
      } catch (e) {
        print('⚠️ Could not retrieve FCM token: $e');
      }

      final response = await _apiService.post(
        ApiConstants.sendOtp,
        body: {
          'phone': phoneNumber,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
      );

      print('✅ OTP Send Successful: ${response.toString()}');
      return {
        'success': true,
        'message': response['message'] ?? 'OTP sent successfully',
        'data': response,
      };
    } catch (e) {
      // Show actual error instead of silently using mock mode
      print('❌ OTP Send Failed: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
        'error': e.toString(),
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Get FCM token safely (may not be available on simulators)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print('📱 FCM Token: $fcmToken');
        }
      } catch (e) {
        print('⚠️ Could not retrieve FCM token: $e');
      }

      final response = await _apiService.post(
        ApiConstants.verifyOtp,
        body: {
          'phone': phoneNumber,
          'otp': otp,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
      );

      final user =
          User.fromJson(response['user'] ?? response['data']?['user'] ?? {});
      final token = response['token'] ??
          response['data']?['token'] ??
          response['access_token'];

      if (token != null) {
        _apiService.setAuthToken(token);
      }

      print('✅ OTP Verification Successful');
      return {
        'success': true,
        'user': user,
        'token': token,
        'message': response['message'] ?? 'OTP verified successfully',
      };
    } catch (e) {
      // Show actual error instead of silently using mock mode
      print('❌ OTP Verification Failed: $e');
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
        'error': e.toString(),
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    try {
      // Get FCM token safely (may not be available on simulators)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print('📱 FCM Token: $fcmToken');
        }
      } catch (e) {
        print('⚠️ Could not retrieve FCM token: $e');
      }

      final response = await _apiService.post(
        ApiConstants.resendOtp,
        body: {
          'phone': phoneNumber,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
      );

      return {
        'success': true,
        'message': response['message'] ?? 'OTP resent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Upload Aadhaar front image with number
  Future<Map<String, dynamic>> uploadAadhaarFront({
    required File imageFile,
    required String aadhaarNumber,
  }) async {
    try {
      // TODO: Implement actual KYC upload when backend supports it
      // For now, simulate successful upload
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      return {
        'success': true,
        'message': 'Aadhaar front uploaded successfully (simulated)',
        'data': {
          'file_path': imageFile.path,
          'aadhar_number': aadhaarNumber,
          'status': 'uploaded'
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload failed: ${e.toString()}',
      };
    }
  }

  // Upload Aadhaar back image
  Future<Map<String, dynamic>> uploadAadhaarBack({
    required File imageFile,
  }) async {
    try {
      // TODO: Implement actual KYC upload when backend supports it
      // For now, simulate successful upload
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      return {
        'success': true,
        'message': 'Aadhaar back uploaded successfully (simulated)',
        'data': {'file_path': imageFile.path, 'status': 'uploaded'},
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Upload failed: ${e.toString()}',
      };
    }
  }
}
