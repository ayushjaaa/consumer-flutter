import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/data/services/storage_service.dart';
import 'package:onetap365app/features/auth/screens/signin_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/ad_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/ads_repository.dart';
import '../widgets/listing_card.dart';
// import 'listing_detail_screen.dart';
import 'category_items_screen.dart';

class CategoryBrowseScreen extends StatefulWidget {
  final Category category;

  const CategoryBrowseScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends State<CategoryBrowseScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AdsRepository _adsRepository = AdsRepository();

  List<SubCategory> _subcategories = [];
  List<Ad> _allAds = [];
  List<Ad> _filteredAds = [];
  // bool _isLoadingSubcategories = true;
  bool _isLoadingAds = true;
  String? _error;
  bool _isAuthenticated = false;
  bool _authChecked = false;

  String? _selectedSubcategoryName;
  String _sortBy = 'recent'; // recent, price_low, price_high
  // String? _selectedCondition; // new, used
  String? _selectedType; // SELL, RENT
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _initAuthAndLoad();
  }

  Future<void> _initAuthAndLoad() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = isLoggedIn;
      _authChecked = true;
      if (!isLoggedIn) {
        _isLoadingAds = false;
        _subcategories = [];
        _allAds = [];
        _filteredAds = [];
        _error = 'Please sign in to view items';
      }
    });

    if (isLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubcategories(),
      _loadAds(),
    ]);
  }

  Future<void> _loadSubcategories() async {
    try {
      setState(() {});

      final subcategories =
          await _categoryRepository.getSubCategories(widget.category.id);

      if (mounted) {
        setState(() {
          _subcategories = subcategories;
          // _isLoadingSubcategories = false;
        });
      }
    } catch (e) {
      print('❌ Error loading subcategories: $e');
      if (mounted) {
        setState(() {
          // _isLoadingSubcategories = false;
        });
      }
    }
  }

  Future<void> _loadAds() async {
    try {
      setState(() {
        _isLoadingAds = true;
        _error = null;
      });

      final ads = await _adsRepository.getAllItems();

      // Filter by category NAME (since API returns category_name, not cat_id)
      final categoryAds = ads
          .where((ad) =>
              ad.categoryName?.toLowerCase() ==
              widget.category.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _allAds = categoryAds;
          _filteredAds = categoryAds;
          _isLoadingAds = false;
        });
        _applyFilters();
      }
    } catch (e) {
      print('❌ Error loading ads: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoadingAds = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAds = _allAds;

      // Filter by subcategory NAME (since API returns subcategory_name)
      if (_selectedSubcategoryName != null) {
        _filteredAds = _filteredAds
            .where((ad) =>
                ad.subcategoryName?.toLowerCase() ==
                _selectedSubcategoryName?.toLowerCase())
            .toList();
      }

      // Filter by type (SELL/RENT)
      if (_selectedType != null) {
        _filteredAds =
            _filteredAds.where((ad) => ad.itemType == _selectedType).toList();
      }

      // Sort
      switch (_sortBy) {
        case 'price_low':
          _filteredAds.sort((a, b) {
            final priceA = double.tryParse(a.sellingPrice) ?? 0;
            final priceB = double.tryParse(b.sellingPrice) ?? 0;
            return priceA.compareTo(priceB);
          });
          break;
        case 'price_high':
          _filteredAds.sort((a, b) {
            final priceA = double.tryParse(a.sellingPrice) ?? 0;
            final priceB = double.tryParse(b.sellingPrice) ?? 0;
            return priceB.compareTo(priceA);
          });
          break;
        case 'recent':
        default:
          _filteredAds.sort((a, b) {
            final dateA = a.createdAt ?? DateTime.now();
            final dateB = b.createdAt ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedType = null;
                        _sortBy = 'recent';
                      });
                      setState(() {
                        _selectedType = null;
                        _sortBy = 'recent';
                      });
                      _applyFilters();
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Type Filter
              Text(
                'Type',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    'All',
                    _selectedType == null,
                    () {
                      setModalState(() => _selectedType = null);
                    },
                  ),
                  _buildFilterChip(
                    'For Sale',
                    _selectedType == 'SELL',
                    () {
                      setModalState(() => _selectedType = 'SELL');
                    },
                  ),
                  _buildFilterChip(
                    'For Rent',
                    _selectedType == 'RENT',
                    () {
                      setModalState(() => _selectedType = 'RENT');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sort By
              Text(
                'Sort By',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    'Recent',
                    _sortBy == 'recent',
                    () {
                      setModalState(() => _sortBy = 'recent');
                    },
                  ),
                  _buildFilterChip(
                    'Price: Low to High',
                    _sortBy == 'price_low',
                    () {
                      setModalState(() => _sortBy = 'price_low');
                    },
                  ),
                  _buildFilterChip(
                    'Price: High to Low',
                    _sortBy == 'price_high',
                    () {
                      setModalState(() => _sortBy = 'price_high');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Apply Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = _selectedType;
                      _sortBy = _sortBy;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : const Color(0xFF0F2419),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : Colors.white70,
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return 'Over a month ago';
  }

  /// Get fallback icon for category
  IconData _getCategoryFallbackIcon(Category category) {
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

  /// Get fallback color for category
  Color _getCategoryFallbackColor(Category category) {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        String colorString = category.color!.replaceFirst('#', '0xFF');
        return Color(int.parse(colorString));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Display category image with fallback
            SizedBox(
              width: 40,
              height: 40,
              child: ImageUtils.buildCategoryImage(
                imageUrl: widget.category.icon,
                fallbackIcon: _getCategoryFallbackIcon(widget.category),
                iconColor: _getCategoryFallbackColor(widget.category),
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            // Category name
            Expanded(
              child: Text(
                widget.category.name,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: !_authChecked
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : !_isAuthenticated
              ? _buildGuestPrompt()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Subcategories
                      if (_subcategories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _subcategories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _buildSubcategoryChip(
                                      'All',
                                      _selectedSubcategoryName == null,
                                      () {
                                        setState(() {
                                          _selectedSubcategoryName = null;
                                        });
                                        _applyFilters();
                                      },
                                    ),
                                  );
                                }
                                final subcategory = _subcategories[index - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildSubcategoryChip(
                                    subcategory.name,
                                    _selectedSubcategoryName ==
                                        subcategory.name,
                                    () {
                                      setState(() {
                                        _selectedSubcategoryName =
                                            subcategory.name;
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Results Count
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Text(
                            '${_filteredAds.length} ${_filteredAds.length == 1 ? 'item' : 'items'} found',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ),

                      // Loading or Error State
                      if (_isLoadingAds)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (_error != null)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load items',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _loadAds,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Retry',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (_filteredAds.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items found',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        // Items Grid/List
                        _isGridView
                            ? SliverPadding(
                                padding: const EdgeInsets.all(20),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final ad = _filteredAds[index];
                                      return _buildGridItem(ad);
                                    },
                                    childCount: _filteredAds.length,
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final ad = _filteredAds[index];
                                      return ListingCard(
                                        ad: ad,
                                        image: ad.photos.isNotEmpty
                                            ? ad.photos.first
                                            : 'https://via.placeholder.com/400',
                                        badge: ad.itemType == 'RENT'
                                            ? 'FOR RENT'
                                            : '',
                                        badgeColor: Colors.orange,
                                        title: ad.name,
                                        price:
                                            '₹ ${ad.sellingPrice}${ad.itemType == 'RENT' ? ' / mo' : ''}',
                                        location: '${ad.city}, ${ad.state}',
                                        time: _getTimeAgo(ad.createdAt),
                                      );
                                    },
                                    childCount: _filteredAds.length,
                                  ),
                                ),
                              ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSubcategoryChip(
      String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFF0F2419),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(Ad ad) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryItemsScreen(category: widget.category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: ad.photos.isNotEmpty
                  ? Image.network(
                      ad.photos.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey.shade800,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '₹ ${ad.sellingPrice}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.city}, ${ad.state}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in required',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to view items in this category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign In',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
