// lib/data/models/category_model.dart
class Category {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int? parentId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.parentId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? json['category_id'] ?? 0,
      name: json['name'] ?? json['category_name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? json['active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, isActive: $isActive)';
  }
}

class SubCategory {
  final int id;
  final String name;
  final String? description;
  final int categoryId;

  SubCategory({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['category_id'] ?? json['cat_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
    };
  }

  @override
  String toString() {
    return 'SubCategory(id: $id, name: $name, categoryId: $categoryId)';
  }
}
