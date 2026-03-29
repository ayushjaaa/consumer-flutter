// lib/core/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Use mock mode if API_BASE_URL is not set or if MOCK_MODE is enabled
  static bool get useMockMode =>
      dotenv.env['MOCK_MODE'] == 'true' || dotenv.env['API_BASE_URL'] == null;

  static String get baseUrl {
    final envBase = dotenv.env['API_BASE_URL'];
    final defaultBase = 'https://onetap365-backend.onrender.com/api';
    final raw = (envBase == null || envBase.isEmpty) ? defaultBase : envBase;
    final trimmed = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    if (trimmed.endsWith('/api')) return trimmed;
    return '$trimmed/api';
  }

  // Auth Endpoints
  static const String sendOtp = '/send-otp';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';
  static const String register = '/register';
  static const String login = '/login';

  // Category Endpoints
  static const String allCategories = '/all-categories';
  static const String category =
      '/category'; // For subcategories: /category/?cat_id=1

  // Ad Endpoints
  static const String createItem = '/create-item';
  static const String getAds = '/ads';
  static const String getTrendingAds = '/trending-ads';
  static const String allItems = '/all-items';
  static const String myAds = '/my-ads'; // User-specific ads

  // Booking Endpoints
  static const String bookService = '/book-service';
  static const String myBookings = '/my-bookings';
}
