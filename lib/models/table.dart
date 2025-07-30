// models/table.dart - Updated Table model
class TableModel {
  final String id;
  final String tableNumber;
  final String areaId;
  final int seats;
  final String tableType;
  final bool isAvailable;
  final bool isActive;
  final bool isAvailableForTime;
  final bool isReserved;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.areaId,
    required this.seats,
    this.tableType = 'regular',
    this.isAvailable = true,
    this.isActive = true,
    this.isAvailableForTime = true,
    this.isReserved = false,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'] ?? '',
      tableNumber: json['table_number'] ?? '',
      areaId: json['area_id'] ?? '',
      seats: json['seats'] ?? 4,
      tableType: json['table_type'] ?? 'regular',
      isAvailable: json['is_available'] ?? true,
      isActive: json['is_active'] ?? true,
      isAvailableForTime: json['is_available_for_time'] ?? json['is_available'] ?? true,
      isReserved: json['is_reserved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'table_number': tableNumber,
      'area_id': areaId,
      'seats': seats,
      'table_type': tableType,
      'is_available': isAvailable,
      'is_active': isActive,
      'is_available_for_time': isAvailableForTime,
      'is_reserved': isReserved,
    };
  }

  // Helper getters
  bool get canBeSelected => isActive && isAvailable && isAvailableForTime && !isReserved;
  String get availabilityStatus {
    if (!isActive) return 'Tidak Aktif';
    if (!isAvailable) return 'Tidak Tersedia';
    if (isReserved) return 'Sudah Direservasi';
    if (!isAvailableForTime) return 'Tidak Tersedia untuk Waktu Ini';
    return 'Tersedia';
  }
}