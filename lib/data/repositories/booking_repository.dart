import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> bookService({
    required int serviceCatId,
    required int serviceSubcatId,
    required String serviceDate,
    required String serviceTime,
    required String address,
    required String pincode,
  }) async {
    try {
      // Get the access token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/book-service');

      final body = {
        'service_cat_id': serviceCatId,
        'service_subcat_id': serviceSubcatId,
        'service_date': serviceDate,
        'service_time': serviceTime,
        'address': address,
        'pincode': pincode,
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorMessage = responseData['message'] ??
            responseData['error'] ??
            'Failed to book service';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error booking service: $e');
      rethrow;
    }
  }

  /// Get user's service bookings
  Future<List<Booking>> getMyBookings() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getMyBookings();

      if (response is List) {
        return response.map((json) => Booking.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        return data.map((json) => Booking.fromJson(json)).toList();
      } else if (response is Map && response['bookings'] is List) {
        final data = response['bookings'] as List;
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for bookings');
      }
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
}
