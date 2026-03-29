import 'package:flutter/material.dart';
import 'package:onetap365app/core/constants/app_colors.dart';
import 'package:onetap365app/core/utils/image_utils.dart';
import 'package:onetap365app/data/models/category_model.dart';
import 'package:onetap365app/data/repositories/category_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_items_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _categoryRepository.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title:
            const Text('All Categories', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load categories',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchCategories,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse all categories',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return _buildCategoryCard(category);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    IconData iconData = _getIconForCategory(category);
    Color iconColor = _getColorForCategory(category);
    return GestureDetector(
      onTap: () {
        _openCategoryItemsScreen(category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.13),
              radius: 28,
              child: ImageUtils.buildCategoryImage(
                imageUrl: category.icon,
                fallbackIcon: iconData,
                iconColor: iconColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (category.description != null &&
                category.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  category.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(Category category) {
    // Use icon from model if available, else fallback to mapping
    if (category.icon != null && category.icon!.isNotEmpty) {
      // You can map string icon names to Material icons here if needed
      // For now, fallback to mapping by name
    }
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

  Color _getColorForCategory(Category category) {
    // Use color from model if available, else fallback
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        return Color(int.parse(category.color!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }
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

  void _openCategoryItemsScreen(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryItemsScreen(category: category),
      ),
    );
  }
}
