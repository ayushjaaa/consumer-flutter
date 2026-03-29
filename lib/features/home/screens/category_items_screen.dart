import 'package:flutter/material.dart';
import 'package:onetap365app/core/constants/app_colors.dart';
import 'package:onetap365app/data/models/category_model.dart';
import 'package:onetap365app/data/repositories/category_repository.dart';
import 'package:onetap365app/data/repositories/ads_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/data/models/ad_model.dart';
import 'listing_detail_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final Category category;
  const CategoryItemsScreen({required this.category, Key? key})
      : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AdsRepository _adsRepository = AdsRepository();
  List<SubCategory> _subCategories = [];
  int? _selectedSubCategoryId;
  List<Ad> _items = [];
  bool _isLoadingSubcats = true;
  bool _isLoadingItems = true;
  String? _errorSubcats;
  String? _errorItems;

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
    _fetchItems();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoadingSubcats = true;
      _errorSubcats = null;
    });
    try {
      final subcats =
          await _categoryRepository.getSubCategories(widget.category.id);
      setState(() {
        _subCategories = subcats;
        _isLoadingSubcats = false;
        if (subcats.isNotEmpty) {
          _selectedSubCategoryId = subcats.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _errorSubcats = e.toString();
        _isLoadingSubcats = false;
      });
    }
  }

  Future<void> _fetchItems({int? subcatId}) async {
    setState(() {
      _isLoadingItems = true;
      _errorItems = null;
    });
    try {
      // Fetch all items from the API (matching the curl endpoint)
      final allItems = await _adsRepository.getAllItems();
      // Filter items by category name (case-insensitive)
      List<Ad> filtered = allItems
          .where((ad) =>
              ad.categoryName?.toLowerCase() ==
              widget.category.name.toLowerCase())
          .toList();
      if (subcatId != null) {
        filtered = filtered.where((ad) => ad.subcatId == subcatId).toList();
      }
      setState(() {
        _items = filtered;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _errorItems = e.toString();
        _isLoadingItems = false;
      });
    }
  }

  void _onSubCategoryTap(int subcatId) {
    setState(() {
      _selectedSubCategoryId = subcatId;
    });
    _fetchItems(subcatId: subcatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.category.name,
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subcategories horizontal scroll
          _isLoadingSubcats
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                  ),
                )
              : _errorSubcats != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load subcategories',
                          style: const TextStyle(color: Colors.white)),
                    )
                  : SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final subcat = _subCategories[index];
                          final selected = subcat.id == _selectedSubCategoryId;
                          return GestureDetector(
                            onTap: () => _onSubCategoryTap(subcat.id),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.white24),
                              ),
                              child: Center(
                                child: Text(
                                  subcat.name,
                                  style: GoogleFonts.inter(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          const SizedBox(height: 12),
          // Items grid
          Expanded(
            child: _isLoadingItems
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorItems != null
                    ? Center(
                        child: Text('Failed to load items',
                            style: const TextStyle(color: Colors.white)))
                    : _items.isEmpty
                        ? Center(
                            child: Text('No items found',
                                style: const TextStyle(color: Colors.white54)))
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final ad = _items[index];
                              return _buildAdTile(ad);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdTile(Ad ad) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(ad: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ad.photos.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        ad.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary.withOpacity(0.13),
                          child: const Icon(Icons.image,
                              color: Colors.white38, size: 48),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.13),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Icon(Icons.image,
                          color: Colors.white38, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.name,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.city,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
