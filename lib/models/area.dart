// models/area.dart
import 'package:baraja_app/models/table.dart';

class Area {
  final String id;
  final String areaCode;
  final String areaName;
  final int capacity;
  final String description;
  final bool isActive;
  final List<Table> tables;
  final int totalTables;
  final int availableTables;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Area({
    required this.id,
    required this.areaCode,
    required this.areaName,
    required this.capacity,
    this.description = '',
    this.isActive = true,
    this.tables = const [],
    this.totalTables = 0,
    this.availableTables = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] ?? '',
      areaCode: json['area_code'] ?? '',
      areaName: json['area_name'] ?? '',
      capacity: json['capacity'] ?? 0,
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      tables: json['tables'] != null
          ? (json['tables'] as List).map((table) => Table.fromJson(table)).toList()
          : [],
      totalTables: json['total_tables'] ?? 0,
      availableTables: json['available_tables'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'area_code': areaCode,
      'area_name': areaName,
      'capacity': capacity,
      'description': description,
      'is_active': isActive,
      'tables': tables.map((table) => table.toJson()).toList(),
      'total_tables': totalTables,
      'available_tables': availableTables,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}