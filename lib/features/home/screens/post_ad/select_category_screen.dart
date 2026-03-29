import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/models/category_model.dart';
import 'add_details_screen.dart';
import '../../widgets/continue_button.dart';

class SelectCategoryScreen extends StatefulWidget {
  final String type;
  const SelectCategoryScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<SelectCategoryScreen> createState() => _SelectCategoryScreenState();
}

class _SelectCategoryScreenState extends State<SelectCategoryScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _categories = [];
  Category? selectedCategory;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

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
      backgroundColor: const Color(0xFF0E221A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post an Ad',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(2, 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the right category (${widget.type})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Failed to load categories',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchCategories,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _categories.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No categories available',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.1,
                                    ),
                                    itemCount: _categories.length,
                                    itemBuilder: (context, index) {
                                      final category = _categories[index];
                                      final isSelected =
                                          selectedCategory?.id == category.id;
                                      return _buildCategoryCard(
                                        category,
                                        isSelected,
                                        () {
                                          setState(() {
                                            selectedCategory = category;
                                          });
                                        },
                                      );
                                    },
                                  ),
                  ),
                  const SizedBox(height: 20),
                  ContinueButton(
                    onPressed: () {
                      if (selectedCategory != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDetailsScreen(
                              type: widget.type,
                              categoryId: selectedCategory!.id,
                              categoryName: selectedCategory!.name,
                            ),
                          ),
                        );
                      }
                    },
                    text: 'Continue',
                    isEnabled: selectedCategory != null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index < currentStep
                    ? AppColors.primary
                    : const Color(0xFF1a2e2e),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    // Map category names to icons
    final iconMap = {
      'electronics': Icons.phone_iphone,
      'vehicles': Icons.directions_car,
      'property': Icons.home,
      'jobs': Icons.work,
      'furniture': Icons.chair,
      'fashion': Icons.checkroom,
      'services': Icons.build,
      'pets': Icons.pets,
      'books': Icons.menu_book,
      'sports': Icons.sports_soccer,
    };

    final lowerName = categoryName.toLowerCase();
    for (var entry in iconMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.category; // Default icon
  }

  Color _getCategoryColor(String categoryName) {
    // Map category names to fallback colors
    final colorMap = {
      'electronics': Colors.cyan,
      'vehicles': Colors.orange,
      'property': Colors.teal,
      'jobs': Colors.purple,
      'furniture': Colors.amber,
      'fashion': Colors.pink,
      'services': Colors.lightBlue,
      'pets': Colors.brown,
      'books': Colors.indigo,
      'sports': Colors.green,
    };

    final lowerName = categoryName.toLowerCase();
    for (var entry in colorMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Colors.grey; // Default color
  }

  Widget _buildCategoryCard(
      Category category, bool isSelected, VoidCallback onTap) {
    // Get fallback icon and color
    final fallbackIcon = _getCategoryIcon(category.name);
    final fallbackColor = _getCategoryColor(category.name);

    // Use color from backend if available
    Color displayColor = fallbackColor;
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        displayColor =
            Color(int.parse(category.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? displayColor : const Color(0xFF1a2e2e),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display category image from API with fallback
            ImageUtils.buildCategoryImage(
              imageUrl: category.icon,
              fallbackIcon: fallbackIcon,
              iconColor: displayColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
