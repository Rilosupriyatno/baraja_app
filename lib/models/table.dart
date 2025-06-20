// models/table.dart
class TableModel {
  final String id;
  final String tableNumber;
  final String areaId;
  final int seats;
  final String tableType;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.areaId,
    required this.seats,
    required this.tableType,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id']?.toString() ?? '',
      tableNumber: json['table_number']?.toString() ?? '',
      areaId: json['area_id']?.toString() ?? '',
      seats: json['seats']?.toInt() ?? 4,
      tableType: json['table_type']?.toString() ?? 'regular',
      isAvailable: json['is_available'] ?? true,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_number': tableNumber,
      'area_id': areaId,
      'seats': seats,
      'table_type': tableType,
      'is_available': isAvailable,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TableModel copyWith({
    String? id,
    String? tableNumber,
    String? areaId,
    int? seats,
    String? tableType,
    bool? isAvailable,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      areaId: areaId ?? this.areaId,
      seats: seats ?? this.seats,
      tableType: tableType ?? this.tableType,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Table(id: $id, tableNumber: $tableNumber, seats: $seats, tableType: $tableType, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}