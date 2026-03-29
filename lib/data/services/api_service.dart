import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:onetap365app/core/constants/api_constants.dart';

class ApiService {
  /// Get active subscriptions
  Future<dynamic> getActiveSubscription() async {
    return get('/active-subcription');
  }

  static String get baseUrl => ApiConstants.baseUrl;
  static const Duration timeoutDuration = Duration(seconds: 30);
  static const Duration warmupTimeout = Duration(seconds: 8);
  static const int maxRetries = 1;
  static const Duration retryDelay = Duration(seconds: 2);
  static bool _didWarmup = false;

  final http.Client httpClient;
  String? _authToken;

  ApiService({http.Client? client}) : httpClient = client ?? http.Client();

  // ==================== Token Management ====================

  /// Set the authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear the authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get the current auth token
  String? getAuthToken() {
    return _authToken;
  }

  // ==================== Helper Methods ====================

  /// Build headers with authentication
  Map<String, String> _buildHeaders({bool multipart = false}) {
    final headers = {
      'Content-Type': multipart ? 'multipart/form-data' : 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Build headers for form-urlencoded requests
  Map<String, String> _buildFormHeaders() {
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Safely parse JSON response body
  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      // If it's not JSON, return the raw body for error messages
      return {'message': body, 'raw_response': body};
    }
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _safeJsonDecode(response.body);
      } else if (response.statusCode == 400) {
        final errorData = _safeJsonDecode(response.body);
        throw BadRequestException(
            'Bad Request: ${errorData['message'] ?? 'Unknown error'}');
      } else if (response.statusCode == 401) {
        final errorData = _safeJsonDecode(response.body);
        throw UnauthorizedException(
            errorData['message'] ?? 'Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        // Extract actual message from backend for 403 errors (e.g., subscription required)
        final errorData = _safeJsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Forbidden - Access denied';
        throw ForbiddenException(errorMessage);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Resource not found');
      } else if (response.statusCode == 422) {
        final errorData = _safeJsonDecode(response.body);
        throw BadRequestException(
            'Validation Error: ${errorData['message'] ?? 'Invalid data provided'}');
      } else if (response.statusCode == 500) {
        throw ServerException('Server error - Please try again later');
      } else if (response.statusCode == 503) {
        throw ServerException(
            'Server is unavailable (503) - Backend may be down or not responding. Please check that your server is running at the configured base URL.');
      } else {
        // For any other status codes, try to parse as JSON, but provide fallback
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['message'] ??
            'Unexpected error - Status code: ${response.statusCode}. Response: ${response.body.isEmpty ? 'No response body' : response.body}';
        throw ServerException(errorMessage);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('Error parsing response: $e');
    }
  }

  Future<void> _warmUpIfNeeded() async {
    if (_didWarmup) return;
    _didWarmup = true;
    try {
      final url = Uri.parse(baseUrl);
      await httpClient.get(url).timeout(warmupTimeout);
    } catch (_) {
      // Best-effort warmup; ignore failures.
    }
  }

  Future<T> _withRetry<T>(Future<T> Function() request) async {
    var attempt = 0;
    while (true) {
      try {
        return await request();
      } on TimeoutException {
        if (attempt >= maxRetries) rethrow;
      } on SocketException {
        if (attempt >= maxRetries) rethrow;
      }
      attempt += 1;
      await Future.delayed(retryDelay);
    }
  }

  // ==================== GET Request ====================

  /// Perform a GET request
  Future<dynamic> get(String endpoint) async {
    try {
      await _warmUpIfNeeded();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _withRetry(() => httpClient
          .get(url, headers: _buildHeaders())
          .timeout(timeoutDuration));

      return _handleResponse(response);
    } on TimeoutException {
      throw ServerException(
          'Request timed out. The server may be waking up. Please retry.');
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('GET request failed: $e');
    }
  }

  // ==================== POST Request ====================

  /// Perform a POST request
  Future<dynamic> post(String endpoint,
      {required Map<String, dynamic> body}) async {
    try {
      await _warmUpIfNeeded();
      final url = Uri.parse('$baseUrl$endpoint');
      print('🔗 POST URL: $url');
      print('📤 Request Body: $body');
      final response = await _withRetry(() => httpClient
          .post(
            url,
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration));

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      throw ServerException(
          'Request timed out. The server may be waking up. Please retry.');
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('POST request failed: $e');
    }
  }

  /// Perform a POST request with application/x-www-form-urlencoded
  Future<dynamic> postForm(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      await _warmUpIfNeeded();
      final url = Uri.parse('$baseUrl$endpoint');
      // remove nulls and stringify values
      final formBody = <String, String>{};
      body.forEach((key, value) {
        if (value == null) return;
        formBody[key] = value.toString();
      });

      print('🔗 POST(FORM) URL: $url');
      print('📤 Form Body: $formBody');

      final response = await _withRetry(() => httpClient
          .post(
            url,
            headers: _buildFormHeaders(),
            body: formBody,
          )
          .timeout(timeoutDuration));

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      throw ServerException(
          'Request timed out. The server may be waking up. Please retry.');
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('POST(FORM) request failed: $e');
    }
  }

  // ==================== PUT Request ====================

  /// Perform a PUT request
  Future<dynamic> put(String endpoint,
      {required Map<String, dynamic> body}) async {
    try {
      await _warmUpIfNeeded();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _withRetry(() => httpClient
          .put(
            url,
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration));

      return _handleResponse(response);
    } on TimeoutException {
      throw ServerException(
          'Request timed out. The server may be waking up. Please retry.');
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('PUT request failed: $e');
    }
  }

  // ==================== DELETE Request ====================

  /// Perform a DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      await _warmUpIfNeeded();
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _withRetry(() => httpClient
          .delete(url, headers: _buildHeaders())
          .timeout(timeoutDuration));

      return _handleResponse(response);
    } on TimeoutException {
      throw ServerException(
          'Request timed out. The server may be waking up. Please retry.');
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('DELETE request failed: $e');
    }
  }

  // ==================== Multipart Request (for file uploads) ====================

  /// Upload file(s) with multipart request
  Future<dynamic> uploadFile(
    String endpoint, {
    required String fileParamName,
    required File file,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll(_buildHeaders(multipart: true));

      // Add authentication
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          fileParamName,
          file.path,
        ),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final response = await request.send().timeout(timeoutDuration);
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decodedResponse;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized - Please login again');
      } else if (response.statusCode == 400) {
        throw BadRequestException(
            'Upload failed: ${decodedResponse['message']}');
      } else {
        throw ServerException(
            'Upload failed - Status code: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('File upload failed: $e');
    }
  }

  /// Perform a multipart/form-data POST with only fields (no files)
  Future<dynamic> postMultipartFields(
    String endpoint, {
    required Map<String, dynamic> fields,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Headers
      request.headers.addAll(_buildHeaders(multipart: true));
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Fields (stringify, skip null)
      fields.forEach((key, value) {
        if (value == null) return;
        request.fields[key] = value.toString();
      });

      print('🔗 POST(MULTIPART) URL: $url');
      print('📤 Multipart Fields: ${request.fields}');

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode,
          request: request);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('POST(MULTIPART) request failed: $e');
    }
  }

  // ==================== Authentication APIs ====================

  /// Sign up user
  Future<dynamic> signUp({
    required String fullName,
    required String phoneNumber,
    required String username,
    required String email,
    required String password,
  }) async {
    return post('/auth/signup', body: {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'username': username,
      'email': email,
      'password': password,
    });
  }

  /// Sign in user
  Future<dynamic> signIn({
    required String email,
    required String password,
  }) async {
    return post('/auth/signin', body: {
      'email': email,
      'password': password,
    });
  }

  /// Verify OTP
  Future<dynamic> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    return post('/auth/verify-otp', body: {
      'phone': phone,
      'otp': otp,
    });
  }

  /// Refresh token
  Future<dynamic> refreshToken({required String refreshToken}) async {
    return post('/auth/refresh', body: {
      'refresh_token': refreshToken,
    });
  }

  /// Logout
  Future<dynamic> logout() async {
    return post('/auth/logout', body: {});
  }

  /// Register user with files (profile image and Aadhaar documents)
  Future<dynamic> registerWithFiles({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String addarNo,
    required String profileImagePath,
    required String addarFrontPath,
    required String addarBackPath,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.register}');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add fields
      request.fields.addAll({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'addar_no': addarNo,
      });

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          profileImagePath,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'addar_front',
          addarFrontPath,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'addar_back',
          addarBackPath,
        ),
      );

      print('🔗 POST(REGISTER) URL: $url');
      print('📤 Fields: ${request.fields}');
      print('📤 Files: 3 files (profile_image, addar_front, addar_back)');
      print('📤 Headers: ${request.headers}');

      // Use extended timeout for file uploads
      const uploadTimeout = Duration(minutes: 5);

      try {
        final streamedResponse = await request.send().timeout(
          uploadTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Registration timed out after ${uploadTimeout.inSeconds} seconds. '
              'Please check your internet connection and try again.',
            );
          },
        );

        final responseBody = await streamedResponse.stream.bytesToString();
        final response = http.Response(
            responseBody, streamedResponse.statusCode,
            request: request);

        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body Length: ${response.body.length}');
        print(
            '📥 Response Body Preview: ${response.body.substring(0, min(200, response.body.length))}');

        // Check if response is HTML (server error page)
        if (response.body.trim().startsWith('<!DOCTYPE html>') ||
            response.body.trim().startsWith('<html>')) {
          throw ServerException(
              'Server returned HTML instead of JSON. This usually means:\n'
              '• The API endpoint "${ApiConstants.register}" does not exist\n'
              '• The server is returning an error page\n'
              '• Check if the server is running at: $baseUrl\n'
              '• Status Code: ${response.statusCode}\n'
              '• Response starts with: ${response.body.substring(0, 100)}...');
        }

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw ServerException(e.message ?? 'Registration timed out');
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('Registration failed: $e');
    }
  }

  // ==================== KYC APIs ====================

  /// Upload Aadhar front image
  Future<dynamic> uploadAadharFront({
    required File imageFile,
    required String aadharNumber,
  }) async {
    return uploadFile(
      '/kyc/upload-aadhar-front',
      fileParamName: 'aadhar_front',
      file: imageFile,
      additionalFields: {
        'aadhar_number': aadharNumber,
      },
    );
  }

  /// Upload Aadhar back image
  Future<dynamic> uploadAadharBack({
    required File imageFile,
  }) async {
    return uploadFile(
      '/kyc/upload-aadhar-back',
      fileParamName: 'aadhar_back',
      file: imageFile,
    );
  }

  /// Upload profile image
  Future<dynamic> uploadProfileImage({
    required File imageFile,
  }) async {
    return uploadFile(
      '/user/upload-profile-image',
      fileParamName: 'profile_image',
      file: imageFile,
    );
  }

  /// Get KYC status
  Future<dynamic> getKYCStatus() async {
    return get('/kyc/status');
  }

  // ==================== User Profile APIs ====================

  /// Get user profile
  Future<dynamic> getUserProfile() async {
    return get('/user/profile');
  }

  /// Update user profile
  Future<dynamic> updateUserProfile({
    required Map<String, dynamic> data,
  }) async {
    return put('/user/profile', body: data);
  }

  /// Get user balance
  Future<dynamic> getUserBalance() async {
    return get('/user/balance');
  }

  // ==================== Transaction APIs ====================

  /// Get transaction history
  Future<dynamic> getTransactionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return get('/transactions?limit=$limit&offset=$offset');
  }

  /// Get transaction details
  Future<dynamic> getTransactionDetails(String transactionId) async {
    return get('/transactions/$transactionId');
  }

  // ==================== Investment APIs ====================

  /// Get available investments
  Future<dynamic> getInvestments({
    String? category,
    int limit = 20,
  }) async {
    String endpoint = '/investments?limit=$limit';
    if (category != null) {
      endpoint += '&category=$category';
    }
    return get(endpoint);
  }

  /// Get investment details
  Future<dynamic> getInvestmentDetails(String investmentId) async {
    return get('/investments/$investmentId');
  }

  /// Create investment order
  Future<dynamic> createInvestmentOrder({
    required String investmentId,
    required double amount,
  }) async {
    return post('/investments/order', body: {
      'investment_id': investmentId,
      'amount': amount,
    });
  }

  // ==================== Category APIs ====================

  /// Get all categories
  Future<dynamic> getCategories() async {
    return get(ApiConstants.allCategories);
  }

  // ==================== Advertisement APIs ====================

  /// Create ad/item with multiple photos
  Future<dynamic> createAd({
    required Map<String, String> fields,
    required List<String> photoPaths,
  }) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.createItem}');
      final request = http.MultipartRequest('POST', url);

      // Add headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.headers['Accept'] = 'application/json';

      // Add fields
      request.fields.addAll(fields);

      // Add photos
      for (String photoPath in photoPaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            photoPath,
          ),
        );
      }

      print('🔗 POST(CREATE AD) URL: $url');
      print('📤 Fields: ${request.fields}');
      print('📤 Photos: ${photoPaths.length} files');

      // Use extended timeout for file uploads (5 minutes for slow connections/backends)
      const uploadTimeout = Duration(minutes: 5);

      try {
        final streamedResponse = await request.send().timeout(
          uploadTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Upload timed out after ${uploadTimeout.inSeconds} seconds. '
              'The backend may be slow or the file may be too large. '
              'Please try with a smaller photo or check your internet connection.',
            );
          },
        );

        final responseBody = await streamedResponse.stream.bytesToString();
        final response = http.Response(
            responseBody, streamedResponse.statusCode,
            request: request);

        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');

        // For 500 errors, try to extract more error details
        if (response.statusCode == 500) {
          try {
            final errorData = jsonDecode(response.body);
            final errorMsg = errorData['message'] ?? 'Internal Server Error';
            final errorDetail = errorData['error'] ?? errorData['detail'] ?? '';
            throw ServerException(
                'Server error (500): $errorMsg${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
          } catch (e) {
            if (e is ServerException) rethrow;
            throw ServerException('Server error (500): ${response.body}');
          }
        }

        return _handleResponse(response);
      } on TimeoutException catch (e) {
        throw ServerException(e.message ?? 'Upload timed out');
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ServerException('Create ad failed: $e');
    }
  }

  /// Get advertisements
  Future<dynamic> getAds({
    String? category,
    int limit = 10,
  }) async {
    String endpoint = ApiConstants.getAds + '?limit=$limit';
    if (category != null) {
      endpoint += '&category=$category';
    }
    return get(endpoint);
  }

  /// Get trending ads
  Future<dynamic> getTrendingAds({int limit = 10}) async {
    return get('${ApiConstants.getTrendingAds}?limit=$limit');
  }

  /// Get all items
  Future<dynamic> getAllItems() async {
    return get(ApiConstants.allItems);
  }

  /// Get user's own ads
  Future<dynamic> getMyAds() async {
    return get(ApiConstants.myAds);
  }

  /// Get user's service bookings
  Future<dynamic> getMyBookings() async {
    return get(ApiConstants.myBookings);
  }

  /// Track ad impression
  Future<dynamic> trackAdImpression(String adId) async {
    return post('/ads/$adId/impression', body: {});
  }

  /// Track ad click
  Future<dynamic> trackAdClick(String adId) async {
    return post('/ads/$adId/click', body: {});
  }

  // ==================== Cash2Keys APIs ====================

  /// Get cash2keys offers
  Future<dynamic> getCash2KeysOffers() async {
    return get('/cash2keys/offers');
  }

  /// Apply for cash2keys
  Future<dynamic> applyCash2Keys({
    required String offerId,
    required Map<String, dynamic> details,
  }) async {
    return post('/cash2keys/apply', body: {
      'offer_id': offerId,
      ...details,
    });
  }

  // ==================== Support/Help APIs ====================

  /// Submit support ticket
  Future<dynamic> submitSupportTicket({
    required String subject,
    required String description,
    required String category,
  }) async {
    return post('/support/ticket', body: {
      'subject': subject,
      'description': description,
      'category': category,
    });
  }

  /// Get FAQ
  Future<dynamic> getFAQ({String? category}) async {
    String endpoint = '/support/faq';
    if (category != null) {
      endpoint += '?category=$category';
    }
    return get(endpoint);
  }
}

// ==================== Custom Exceptions ====================

abstract class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}
