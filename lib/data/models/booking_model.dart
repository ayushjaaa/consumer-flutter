// lib/data/models/booking_model.dart
import 'dart:convert';

class Booking {
  final int id;
  final String orderId;
  final int serviceCatId;
  final int serviceSubcatId;
  final String serviceName;
  final String? serviceSubcategoryName;
  final String serviceDate;
  final String serviceTime;
  final String address;
  final String pincode;
  final String status; // 'active', 'pending', 'completed', 'cancelled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.orderId,
    required this.serviceCatId,
    required this.serviceSubcatId,
    required this.serviceName,
    this.serviceSubcategoryName,
    required this.serviceDate,
    required this.serviceTime,
    required this.address,
    required this.pincode,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // From JSON (API Response)
  factory Booking.fromJson(Map<String, dynamic> json) {
    print('📄 Parsing booking JSON: $json');

    // Extract order ID - check multiple possible field names
    final orderId = json['booking_id']?.toString() ??
        json['order_id']?.toString() ??
        json['orderId']?.toString() ??
        json['id']?.toString() ??
        '';

    // Extract service category name
    final serviceCategoryName = json['service_category']?['name'] ??
        json['serviceCategory']?['name'] ??
        json['category_name'] ??
        json['categoryName'] ??
        json['service_name'] ??
        json['serviceName'] ??
        'Service';

    // Extract service subcategory name
    final serviceSubcategoryName = json['service_subcategory']?['name'] ??
        json['serviceSubcategory']?['name'] ??
        json['subcategory_name'] ??
        json['subcategoryName'] ??
        json['service_subcategory_name'] ??
        json['serviceSubcategoryName'];

    print(
        '✅ Parsed - Order ID: $orderId, Service: $serviceCategoryName, Subcategory: $serviceSubcategoryName');

    return Booking(
      id: json['id'] ?? json['booking_id'] ?? 0,
      orderId: orderId,
      serviceCatId: json['service_cat_id'] ?? json['serviceCatId'] ?? 0,
      serviceSubcatId:
          json['service_subcat_id'] ?? json['serviceSubcatId'] ?? 0,
      serviceName: serviceCategoryName,
      serviceSubcategoryName: serviceSubcategoryName,
      serviceDate: json['service_date'] ?? json['serviceDate'] ?? '',
      serviceTime: json['service_time'] ?? json['serviceTime'] ?? '',
      address: json['address'] ?? '',
      pincode:
          json['pincode']?.toString() ?? json['pin_code']?.toString() ?? '',
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'service_cat_id': serviceCatId,
      'service_subcat_id': serviceSubcatId,
      'service_name': serviceName,
      'service_subcategory_name': serviceSubcategoryName,
      'service_date': serviceDate,
      'service_time': serviceTime,
      'address': address,
      'pincode': pincode,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // To JSON String
  String toJsonString() => json.encode(toJson());

  // From JSON String
  factory Booking.fromJsonString(String jsonString) {
    return Booking.fromJson(json.decode(jsonString));
  }
}
