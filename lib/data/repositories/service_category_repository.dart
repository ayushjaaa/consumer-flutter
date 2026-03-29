import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/service_category_model.dart';
import '../models/service_subcategory_model.dart';
import '../services/storage_service.dart';

class ServiceCategoryRepository {
  Future<List<ServiceCategory>> getAllServiceCategories() async {
    try {
      // Get the access token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/all-serviceCategory');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Handle different response structures
        if (data is List) {
          return data.map((json) => ServiceCategory.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('data')) {
          final List<dynamic> categoriesJson = data['data'];
          return categoriesJson
              .map((json) => ServiceCategory.fromJson(json))
              .toList();
        } else if (data is Map && data.containsKey('categories')) {
          final List<dynamic> categoriesJson = data['categories'];
          return categoriesJson
              .map((json) => ServiceCategory.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
            'Failed to load service categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching service categories: $e');
      rethrow;
    }
  }

  Future<List<ServiceSubcategory>> getServiceSubcategories(
      int categoryId) async {
    try {
      // Get the access token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}/serviceCategory?category_id=$categoryId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Handle different response structures
        if (data is List) {
          return data.map((json) => ServiceSubcategory.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('data')) {
          final List<dynamic> subcategoriesJson = data['data'];
          return subcategoriesJson
              .map((json) => ServiceSubcategory.fromJson(json))
              .toList();
        } else if (data is Map && data.containsKey('subcategories')) {
          final List<dynamic> subcategoriesJson = data['subcategories'];
          return subcategoriesJson
              .map((json) => ServiceSubcategory.fromJson(json))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
            'Failed to load service subcategories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching service subcategories: $e');
      rethrow;
    }
  }
}
