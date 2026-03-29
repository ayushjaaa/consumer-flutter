import 'package:flutter/material.dart';
import '../../../data/models/category_model.dart';
import '../../../core/utils/image_utils.dart';
import '../screens/category_browse_screen.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({required this.category});

  /// Convert icon name from API to Material IconData
  IconData _stringToIconData(String iconName) {
    final iconMap = {
      'phone_iphone': Icons.phone_iphone,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'work': Icons.work,
      'chair': Icons.chair,
      'checkroom': Icons.checkroom,
      'computer': Icons.computer,
      'sports_soccer': Icons.sports_soccer,
      'book': Icons.book,
      'pets': Icons.pets,
      'electric_bolt': Icons.electric_bolt,
      'plumbing': Icons.plumbing,
      'ac_unit': Icons.ac_unit,
      'cleaning_services': Icons.cleaning_services,
      'handyman': Icons.handyman,
      'format_paint': Icons.format_paint,
      'build': Icons.build,
      'home_repair_service': Icons.home_repair_service,
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'category': Icons.category,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  /// Get icon from API data, fallback to category name mapping
  IconData _getIconForCategory(Category category) {
    // First, try to use icon from backend API
    if (category.icon != null && category.icon!.isNotEmpty) {
      return _stringToIconData(category.icon!);
    }

    // Fallback: map category names to appropriate icons
    final lowerName = category.name.toLowerCase();
    if (lowerName.contains('mobile') || lowerName.contains('phone')) {
      return Icons.phone_iphone;
    } else if (lowerName.contains('vehicle') || lowerName.contains('car')) {
      return Icons.directions_car;
    } else if (lowerName.contains('property') ||
        lowerName.contains('home') ||
        lowerName.contains('real estate')) {
      return Icons.home;
    } else if (lowerName.contains('job') || lowerName.contains('employment')) {
      return Icons.work;
    } else if (lowerName.contains('furniture')) {
      return Icons.chair;
    } else if (lowerName.contains('fashion') ||
        lowerName.contains('clothing')) {
      return Icons.checkroom;
    } else if (lowerName.contains('electronics') ||
        lowerName.contains('computer')) {
      return Icons.computer;
    } else if (lowerName.contains('sports') || lowerName.contains('fitness')) {
      return Icons.sports_soccer;
    } else if (lowerName.contains('books') || lowerName.contains('education')) {
      return Icons.book;
    } else if (lowerName.contains('pets') || lowerName.contains('animals')) {
      return Icons.pets;
    } else {
      return Icons.category;
    }
  }

  /// Get color from API data, fallback to category name mapping
  Color _getColorForCategory(Category category) {
    // First, try to use color from backend API
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        // Handle both #RRGGBB and #FFRRGGBB formats
        String colorString = category.color!.replaceFirst('#', '0xFF');
        return Color(int.parse(colorString));
      } catch (_) {
        // If parsing fails, fall through to name-based mapping
      }
    }

    // Fallback: map category names to appropriate colors
    final lowerName = category.name.toLowerCase();
    if (lowerName.contains('mobile') || lowerName.contains('phone')) {
      return Colors.blue;
    } else if (lowerName.contains('vehicle') || lowerName.contains('car')) {
      return Colors.orange;
    } else if (lowerName.contains('property') || lowerName.contains('home')) {
      return Colors.teal;
    } else if (lowerName.contains('job')) {
      return Colors.purple;
    } else if (lowerName.contains('furniture')) {
      return Colors.amber;
    } else if (lowerName.contains('fashion')) {
      return Colors.pink;
    } else if (lowerName.contains('electronics')) {
      return Colors.cyan;
    } else if (lowerName.contains('sports')) {
      return Colors.green;
    } else if (lowerName.contains('books')) {
      return Colors.indigo;
    } else if (lowerName.contains('pets')) {
      return Colors.brown;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryBrowseScreen(category: category),
          ),
        );
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Display category image from API, fallback to icon
            ImageUtils.buildCategoryImage(
              imageUrl: category.icon,
              fallbackIcon: _getIconForCategory(category),
              iconColor: _getColorForCategory(category),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
