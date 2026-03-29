class ServiceSubcategory {
  final int id;
  final String name;
  final int categoryId;
  final bool isActive;

  ServiceSubcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isActive = true,
  });

  factory ServiceSubcategory.fromJson(Map<String, dynamic> json) {
    return ServiceSubcategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? json['categoryId'] ?? 0,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'is_active': isActive,
    };
  }
}
