// lib/data/models/user_model.dart
import 'dart:convert';

class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? username;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isKycComplete;
  final String? profileImage;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.username,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isKycComplete = false,
    this.profileImage,
  });

  // From JSON (API Response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['name'] ?? json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber:
          json['phone_number'] ?? json['phoneNumber'] ?? json['phone'] ?? '',
      username: json['username'],
      isEmailVerified:
          json['is_email_verified'] ?? json['isEmailVerified'] ?? false,
      isPhoneVerified:
          json['is_phone_verified'] ?? json['isPhoneVerified'] ?? false,
      isKycComplete: json['is_kyc_complete'] ?? json['isKycComplete'] ?? false,
      profileImage: json['profile_image'] ?? json['profileImage'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'username': username,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'is_kyc_complete': isKycComplete,
      'profile_image': profileImage,
    };
  }

  // To JSON String
  String toJsonString() => json.encode(toJson());

  // From JSON String
  factory User.fromJsonString(String jsonString) {
    return User.fromJson(json.decode(jsonString));
  }

  // CopyWith method
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? username,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isKycComplete,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isKycComplete: isKycComplete ?? this.isKycComplete,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
