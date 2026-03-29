import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class ImageUtils {
  /// Build a widget to display category image from API
  /// Handles both full URLs and relative paths
  /// Falls back to icon if image fails to load
  static Widget buildCategoryImage({
    required String? imageUrl,
    required IconData fallbackIcon,
    required Color iconColor,
    double size = 30,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(
        fallbackIcon,
        color: iconColor,
        size: size,
      );
    }

    final fullUrl = _buildFullImageUrl(imageUrl);

    return Image.network(
      fullUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return Icon(
          fallbackIcon,
          color: iconColor,
          size: size,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        // Show a small loading indicator
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        );
      },
    );
  }

  /// Build a widget for category image in larger contexts (like appBar)
  static Widget buildCategoryImageLarge({
    required String? imageUrl,
    required IconData fallbackIcon,
    required Color iconColor,
    double size = 48,
  }) {
    return buildCategoryImage(
      imageUrl: imageUrl,
      fallbackIcon: fallbackIcon,
      iconColor: iconColor,
      size: size,
    );
  }

  /// Construct full image URL from relative path or filename
  /// Handles different response formats from backend
  static String _buildFullImageUrl(String imagePath) {
    // If it's already a full URL (http/https), return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If it's a relative path, prepend base URL
    // Common backend patterns: /uploads/, /images/, /public/
    final baseUrl = ApiConstants.baseUrl;

    // Remove leading slash if present
    final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';

    // Construct full URL
    // Remove /api from base URL since files are usually served from root
    final rootUrl = baseUrl.replaceAll('/api', '');
    return '$rootUrl$cleanPath';
  }

  /// Check if a URL is valid for network image loading
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/');
  }
}
