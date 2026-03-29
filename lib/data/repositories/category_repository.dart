// lib/data/repositories/category_repository.dart
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  /// Fetch all categories from backend
  Future<List<Category>> getAllCategories() async {
    try {
      // Get token from storage and set it in API service
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.getCategories();

      if (response is List) {
        return response.map((json) => Category.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        // Handle nested data structure
        final data = response['data'] as List;
        return data.map((json) => Category.fromJson(json)).toList();
      } else if (response is Map && response['categories'] is List) {
        // Handle categories key
        final data = response['categories'] as List;
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for categories');
      }
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final categories = await getAllCategories();
      return categories.where((category) => category.id == id).firstOrNull;
    } catch (e) {
      throw Exception('Failed to get category by ID: $e');
    }
  }

  /// Get active categories only
  Future<List<Category>> getActiveCategories() async {
    try {
      final categories = await getAllCategories();
      return categories.where((category) => category.isActive).toList();
    } catch (e) {
      throw Exception('Failed to get active categories: $e');
    }
  }

  /// Fetch subcategories for a category
  Future<List<SubCategory>> getSubCategories(int categoryId) async {
    try {
      // Get token from storage and set it in API service
      final token = await StorageService.getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      final response = await _apiService.get(
        '${ApiConstants.category}/?cat_id=$categoryId',
      );

      if (response is List) {
        return response.map((json) => SubCategory.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        // Handle nested data structure
        final data = response['data'] as List;
        return data.map((json) => SubCategory.fromJson(json)).toList();
      } else if (response is Map && response['subcategories'] is List) {
        // Handle subcategories key
        final data = response['subcategories'] as List;
        return data.map((json) => SubCategory.fromJson(json)).toList();
      } else {
        // Return empty list if no subcategories
        return [];
      }
    } catch (e) {
      throw Exception('Failed to fetch subcategories: $e');
    }
  }
}
