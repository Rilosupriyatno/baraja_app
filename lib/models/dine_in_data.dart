// models/dine_in_data.dart
class DineInData {
  final String tableNumber;
  final int personCount;
  final int floor;
  final String? customerName;
  final DateTime? orderTime;
  final String? notes;

  DineInData({
    required this.tableNumber,
    required this.personCount,
    required this.floor,
    this.customerName,
    this.orderTime,
    this.notes,
  });

  // Getter untuk formatted order time
  String get formattedOrderTime {
    if (orderTime == null) return '';
    return '${orderTime!.hour.toString().padLeft(2, '0')}:${orderTime!.minute.toString().padLeft(2, '0')}';
  }

  // Getter untuk formatted date
  String get formattedDate {
    if (orderTime == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${orderTime!.day} ${months[orderTime!.month - 1]} ${orderTime!.year}';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'tableNumber': tableNumber,
      'personCount': personCount,
      'floor': floor,
      'customerName': customerName,
      'orderTime': orderTime?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from JSON
  factory DineInData.fromJson(Map<String, dynamic> json) {
    return DineInData(
      tableNumber: json['tableNumber'] as String,
      personCount: json['personCount'] as int,
      floor: json['floor'] as int,
      customerName: json['customerName'] as String?,
      orderTime: json['orderTime'] != null
          ? DateTime.parse(json['orderTime'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  // Copy with method for creating modified copies
  DineInData copyWith({
    String? tableNumber,
    int? personCount,
    int? floor,
    String? customerName,
    DateTime? orderTime,
    String? notes,
  }) {
    return DineInData(
      tableNumber: tableNumber ?? this.tableNumber,
      personCount: personCount ?? this.personCount,
      floor: floor ?? this.floor,
      customerName: customerName ?? this.customerName,
      orderTime: orderTime ?? this.orderTime,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'DineInData(tableNumber: $tableNumber, personCount: $personCount, floor: $floor, customerName: $customerName, orderTime: $orderTime, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DineInData &&
        other.tableNumber == tableNumber &&
        other.personCount == personCount &&
        other.floor == floor &&
        other.customerName == customerName &&
        other.orderTime == orderTime &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return tableNumber.hashCode ^
    personCount.hashCode ^
    floor.hashCode ^
    customerName.hashCode ^
    orderTime.hashCode ^
    notes.hashCode;
  }
}