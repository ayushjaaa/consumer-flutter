// lib/providers/ads_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/ad_model.dart';
import '../data/repositories/ads_repository.dart';
import '../data/services/storage_service.dart';

class AdsProvider extends ChangeNotifier {
  final AdsRepository _adsRepository = AdsRepository();

  // Public getter to access the repository (for internal use only)
  AdsRepository get adsRepository => _adsRepository;

  List<Ad> _ads = [];
  List<Ad> _trendingAds = [];
  bool _isLoading = false;
  bool _isLoadingTrending = false;
  String? _error;
  String? _trendingError;

  List<Ad> get ads => _ads;
  List<Ad> get trendingAds => _trendingAds;
  bool get isLoading => _isLoading;
  bool get isLoadingTrending => _isLoadingTrending;
  String? get error => _error;
  String? get trendingError => _trendingError;

  // Post ad data
  Map<String, dynamic> _postAdData = {};
  List<File> _selectedPhotos = [];

  Map<String, dynamic> get postAdData => _postAdData;
  List<File> get selectedPhotos => _selectedPhotos;

  /// Update post ad data
  void updatePostAdData(Map<String, dynamic> data) {
    _postAdData = {..._postAdData, ...data};
    notifyListeners();
  }

  /// Add photos for posting
  void addPhotos(List<File> photos) {
    _selectedPhotos.addAll(photos);
    notifyListeners();
  }

  /// Remove photo
  void removePhoto(int index) {
    if (index >= 0 && index < _selectedPhotos.length) {
      _selectedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear post ad data
  void clearPostAdData() {
    _postAdData = {};
    _selectedPhotos = [];
    notifyListeners();
  }

  /// Post/Create an ad
  Future<bool> postAd() async {
    try {
      // Silently reject if data is completely empty (likely unintentional call)
      if (_postAdData.isEmpty) {
        print('⚠️ postAd called with empty data - ignoring');
        return false;
      }

      // Prevent posting ads with missing required fields
      if ((_postAdData['name'] ?? '').toString().trim().isEmpty ||
          (_postAdData['description'] ?? '').toString().trim().isEmpty) {
        _error = 'Cannot post ad: missing required fields (name, description)';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _adsRepository.createAd(
        itemType: _postAdData['item_type'] ?? 'SELL',
        catId: _postAdData['cat_id'] ?? 1,
        subcatId: _postAdData['subcat_id'],
        name: _postAdData['name'] ?? '',
        description: _postAdData['description'] ?? '',
        mrp: _postAdData['mrp']?.toString() ?? '0',
        sellingPrice: _postAdData['selling_price']?.toString() ?? '0',
        discount: _postAdData['discount']?.toString(),
        review: _postAdData['review']?.toString(),
        city: _postAdData['city'] ?? '',
        state: _postAdData['state'] ?? '',
        pincode: _postAdData['pincode']?.toString() ?? '',
        address: _postAdData['address'],
        contactName: _postAdData['contact_name'],
        contactPhone: _postAdData['contact_phone'],
        contactEmail: _postAdData['contact_email'],
        website: _postAdData['website'],
        photos: _selectedPhotos,
      );

      _isLoading = false;

      if (result['success'] == true) {
        clearPostAdData();
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to post ad';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch all ads
  Future<void> fetchAds({String? category, int limit = 10}) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _ads = [];
        _isLoading = false;
        _error = 'Login required to view ads';
        notifyListeners();
        return;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      _ads = await _adsRepository.getAds(category: category, limit: limit);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch trending ads
  Future<void> fetchTrendingAds({int limit = 10}) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _trendingAds = [];
        _isLoadingTrending = false;
        _trendingError = 'Login required to view trending ads';
        notifyListeners();
        return;
      }

      _isLoadingTrending = true;
      _trendingError = null;
      notifyListeners();

      _trendingAds = await _adsRepository.getTrendingAds(limit: limit);

      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _trendingError = e.toString();
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// Fetch all items
  Future<void> fetchAllItems() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _trendingAds = [];
        _isLoadingTrending = false;
        _trendingError = 'Login required to view items';
        notifyListeners();
        return;
      }

      _isLoadingTrending = true;
      _trendingError = null;
      notifyListeners();

      _trendingAds = await _adsRepository.getAllItems();

      _isLoadingTrending = false;
      notifyListeners();
    } catch (e) {
      _trendingError = e.toString();
      _isLoadingTrending = false;
      notifyListeners();
    }
  }
}
