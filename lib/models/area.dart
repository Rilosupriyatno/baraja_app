// models/area.dart - Updated Area model
class Area {
  final String id;
  final String areaCode;
  final String areaName;
  final int capacity;
  final String description;
  final bool isActive;
  final int totalTables;
  final int availableTables;
  final int reservedTables;
  final int availableCapacity;
  final int totalReservedGuests;
  final bool isFullyBooked;

  Area({
    required this.id,
    required this.areaCode,
    required this.areaName,
    required this.capacity,
    this.description = '',
    this.isActive = true,
    this.totalTables = 0,
    this.availableTables = 0,
    this.reservedTables = 0,
    this.availableCapacity = 0,
    this.totalReservedGuests = 0,
    this.isFullyBooked = false,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['_id'] ?? '',
      areaCode: json['area_code'] ?? '',
      areaName: json['area_name'] ?? '',
      capacity: json['capacity'] ?? 0,
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      totalTables: json['totalTables'] ?? 0,
      availableTables: json['availableTables'] ?? 0,
      reservedTables: json['reservedTables'] ?? 0,
      availableCapacity: json['availableCapacity'] ?? json['capacity'] ?? 0,
      totalReservedGuests: json['totalReservedGuests'] ?? 0,
      isFullyBooked: json['isFullyBooked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'area_code': areaCode,
      'area_name': areaName,
      'capacity': capacity,
      'description': description,
      'is_active': isActive,
      'totalTables': totalTables,
      'availableTables': availableTables,
      'reservedTables': reservedTables,
      'availableCapacity': availableCapacity,
      'totalReservedGuests': totalReservedGuests,
      'isFullyBooked': isFullyBooked,
    };
  }

  // Helper getters
  bool get hasAvailability => availableTables > 0 && availableCapacity > 0 && !isFullyBooked;
  double get occupancyRate => totalTables > 0 ? (reservedTables / totalTables) : 0.0;
  double get capacityUsage => capacity > 0 ? (totalReservedGuests / capacity) : 0.0;
}