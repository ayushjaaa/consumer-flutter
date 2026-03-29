// lib/data/models/ad_model.dart
import '../../core/constants/api_constants.dart';

class Ad {
  final int? id;
  final String itemType; // "RENT" or "SELL"
  final int catId;
  final int? subcatId;
  final String? categoryName; // Category name from API
  final String? subcategoryName; // Subcategory name from API
  final String name;
  final String description;
  final String mrp;
  final String sellingPrice;
  final String? discount;
  final String? review;
  final String city;
  final String state;
  final String pincode;
  final List<String> photos;
  final String? address;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isTrending;
  final bool? isHotDeal;
  final bool? isVerified;

  Ad({
    this.id,
    required this.itemType,
    required this.catId,
    this.subcatId,
    this.categoryName,
    this.subcategoryName,
    required this.name,
    required this.description,
    required this.mrp,
    required this.sellingPrice,
    this.discount,
    this.review,
    required this.city,
    required this.state,
    required this.pincode,
    this.photos = const [],
    this.address,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.website,
    this.createdAt,
    this.updatedAt,
    this.isTrending,
    this.isHotDeal,
    this.isVerified,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      itemType: json['item_type'] ?? json['itemType'] ?? 'SELL',
      catId: json['cat_id'] ?? json['catId'] ?? json['category_id'] ?? 0,
      subcatId: json['subcat_id'] ?? json['subcatId'] ?? json['subcategory_id'],
      categoryName: json['category_name'] ?? json['categoryName'],
      subcategoryName: json['subcategory_name'] ?? json['subcategoryName'],
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      mrp: json['mrp']?.toString() ?? json['original_price']?.toString() ?? '0',
      sellingPrice:
          json['selling_price']?.toString() ?? json['price']?.toString() ?? '0',
      discount: json['discount']?.toString(),
      review: json['review']?.toString() ?? json['rating']?.toString(),
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode:
          json['pincode']?.toString() ?? json['pin_code']?.toString() ?? '',
      photos: _parsePhotos(json['photos'] ?? json['images']),
      address: json['address'],
      contactName: json['contact_name'] ?? json['contactName'],
      contactPhone:
          json['contact_phone'] ?? json['contactPhone'] ?? json['phone'],
      contactEmail:
          json['contact_email'] ?? json['contactEmail'] ?? json['email'],
      website: json['website'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isTrending: json['is_trending'] ?? json['trending'] ?? false,
      isHotDeal: json['is_hot_deal'] ?? json['hotDeal'] ?? false,
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
    );
  }

  static List<String> _parsePhotos(dynamic photos) {
    if (photos == null) return [];

    List<String> photoList = [];

    if (photos is List) {
      photoList = photos.map((p) => p.toString()).toList();
    } else if (photos is String) {
      // Handle comma-separated string
      photoList = photos
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }

    // Convert relative paths to full URLs
    return photoList.map((photo) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return photo; // Already a full URL
      } else {
        // Prepend base URL for relative paths
        return '${ApiConstants.baseUrl.replaceAll('/api', '')}/$photo';
      }
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'item_type': itemType,
      'cat_id': catId,
      if (subcatId != null) 'subcat_id': subcatId,
      'name': name,
      'description': description,
      'mrp': mrp,
      'selling_price': sellingPrice,
      if (discount != null) 'discount': discount,
      if (review != null) 'review': review,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (address != null) 'address': address,
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (website != null) 'website': website,
    };
  }

  @override
  String toString() {
    return 'Ad(id: $id, name: $name, type: $itemType, price: $sellingPrice)';
  }
}
