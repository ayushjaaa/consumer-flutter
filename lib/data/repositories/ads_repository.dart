// lib/data/repositories/ads_repository.dart
import 'dart:io';
import '../models/ad_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AdsRepository {
  final ApiService _apiService = ApiService();

  // Public getter for internal use only
  ApiService get apiService => _apiService;

  /// Delete an ad by ID
  Future<bool> deleteAd(int adId) async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }
      await _apiService.delete('/ads/$adId');
      // Assume success if no error thrown
      return true;
    } catch (e) {
      print('❌ Error deleting ad: $e');
      return false;
    }
  }

  /// Update an ad by ID
  Future<bool> updateAd(Ad ad) async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      // Prepare the update data
      final updateData = {
        'name': ad.name,
        'description': ad.description,
        'selling_price': ad.sellingPrice,
      };

      // Make API call to update ad
      await _apiService.put('/ads/${ad.id}', body: updateData);
      return true;
    } catch (e) {
      print('❌ Error updating ad: $e');
      return false;
    }
  }

  /// Create/Post an ad
  Future<Map<String, dynamic>> createAd({
    required String itemType,
    required int catId,
    int? subcatId,
    required String name,
    required String description,
    required String mrp,
    required String sellingPrice,
    String? discount,
    String? review,
    required String city,
    required String state,
    required String pincode,
    String? address,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? website,
    required List<File> photos,
  }) async {
    try {
      // Get token and set in API service
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      // Prepare form fields (matching backend API expectations)
      final fields = <String, String>{
        'item_type': itemType,
        'cat_id': catId.toString(),
        // Only send subcat_id if it's provided and valid
        if (subcatId != null && subcatId > 0) 'subcat_id': subcatId.toString(),
        'name': name,
        'description': description,
        // If mrp is 0 or empty, use selling_price as mrp (backend might require valid mrp)
        'mrp': (mrp == '0' || mrp.isEmpty) ? sellingPrice : mrp,
        'selling_price': sellingPrice,
        // Only send discount if it's not 0 or empty
        if (discount != null && discount.isNotEmpty && discount != '0')
          'discount': discount,
        if (review != null && review.isNotEmpty && review != '0')
          'review': review,
        'city': city,
        'state': state,
        'pincode': pincode,
        // Note: contact fields and address are not expected by backend API
      };

      // Get photo paths
      final photoPaths = photos.map((file) => file.path).toList();

      // Make API call
      final response = await _apiService.createAd(
        fields: fields,
        photoPaths: photoPaths,
      );

      return {
        'success': true,
        'message': response['message'] ?? 'Ad posted successfully',
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get all ads
  Future<List<Ad>> getAds({String? category, int limit = 10}) async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getAds(
        category: category,
        limit: limit,
      );

      if (response is List) {
        return response.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['ads'] is List) {
        final data = response['ads'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for ads');
      }
    } catch (e) {
      throw Exception('Failed to fetch ads: $e');
    }
  }

  /// Get trending ads
  Future<List<Ad>> getTrendingAds({int limit = 10}) async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getTrendingAds(limit: limit);

      if (response is List) {
        return response.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['ads'] is List) {
        final data = response['ads'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for trending ads');
      }
    } catch (e) {
      throw Exception('Failed to fetch trending ads: $e');
    }
  }

  /// Get all items
  Future<List<Ad>> getAllItems() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getAllItems();

      if (response is List) {
        return response.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['items'] is List) {
        final data = response['items'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for all items');
      }
    } catch (e) {
      throw Exception('Failed to fetch all items: $e');
    }
  }

  /// Get user's own ads
  Future<List<Ad>> getMyAds() async {
    try {
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getMyAds();

      if (response is List) {
        return response.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['items'] is List) {
        final data = response['items'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response is Map && response['ads'] is List) {
        final data = response['ads'] as List;
        return data.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for my ads');
      }
    } catch (e) {
      throw Exception('Failed to fetch my ads: $e');
    }
  }
}
