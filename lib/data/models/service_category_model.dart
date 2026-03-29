class ServiceCategory {
  final int id;
  final String name;
  final String icon;
  final String color;
  final int? listingCount;
  final bool isActive;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.listingCount,
    this.isActive = true,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#22C55E',
      listingCount: json['listing_count'] ?? json['listingCount'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'listing_count': listingCount,
      'is_active': isActive,
    };
  }
}
