import 'package:flutter/material.dart';
import 'package:onetap365app/core/constants/app_colors.dart';
import 'package:onetap365app/data/models/category_model.dart';
import 'package:onetap365app/data/repositories/category_repository.dart';
import 'package:onetap365app/data/repositories/ads_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/data/models/ad_model.dart';

class CategoryDetailsSheet extends StatefulWidget {
  final Category category;
  const CategoryDetailsSheet({required this.category});

  @override
  State<CategoryDetailsSheet> createState() => _CategoryDetailsSheetState();
}

class _CategoryDetailsSheetState extends State<CategoryDetailsSheet> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AdsRepository _adsRepository = AdsRepository();
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;
  String? _error;
  Map<int, List<Ad>> _subcatItems = {};
  Map<int, bool> _subcatLoading = {};
  Map<int, String?> _subcatError = {};

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final subcats =
          await _categoryRepository.getSubCategories(widget.category.id);
      setState(() {
        _subCategories = subcats;
        _isLoading = false;
      });
      for (final subcat in subcats) {
        _fetchItemsForSubcat(subcat.id);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchItemsForSubcat(int subcatId) async {
    setState(() {
      _subcatLoading[subcatId] = true;
      _subcatError[subcatId] = null;
    });
    try {
      final items = await _adsRepository.getAds(category: null, limit: 10);
      // Filter items by subcatId
      final filtered = items.where((ad) => ad.subcatId == subcatId).toList();
      setState(() {
        _subcatItems[subcatId] = filtered;
        _subcatLoading[subcatId] = false;
      });
    } catch (e) {
      setState(() {
        _subcatError[subcatId] = e.toString();
        _subcatLoading[subcatId] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: _isLoading
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
                      Text('Failed to load subcategories',
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchSubCategories,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Text(
                      widget.category.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.category.description != null &&
                        widget.category.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          widget.category.description!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ..._subCategories
                        .map((subcat) => _buildSubCategorySection(subcat))
                        .toList(),
                  ],
                ),
    );
  }

  Widget _buildSubCategorySection(SubCategory subcat) {
    final items = _subcatItems[subcat.id] ?? [];
    final loading = _subcatLoading[subcat.id] ?? false;
    final error = _subcatError[subcat.id];
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subcat.name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            if (subcat.description != null && subcat.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  subcat.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2)),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Failed to load items',
                            style: TextStyle(color: Colors.white70))),
                  ],
                ),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No items found',
                    style: TextStyle(color: Colors.white54)),
              )
            else
              Column(
                children: items.take(3).map((ad) => _buildAdTile(ad)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTile(Ad ad) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ad.photos.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(ad.photos.first,
                  width: 48, height: 48, fit: BoxFit.cover),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Colors.white38),
            ),
      title: Text(
        ad.name,
        style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        ad.city,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: () {
        // TODO: Navigate to ad details
      },
    );
  }
}
