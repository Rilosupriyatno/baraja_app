class PromoItem {
  final String id;
  final String type;
  final List<String> imageUrls;
  final String description;
  final String createdBy;
  final DateTime startDate;
  final DateTime endDate;

  PromoItem({
    required this.id,
    required this.type,
    required this.imageUrls,
    required this.description,
    required this.createdBy,
    required this.startDate,
    required this.endDate,
  });

  factory PromoItem.fromJson(Map<String, dynamic> json) {
    return PromoItem(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }
}
