// models/reservation_data.dart
import 'package:flutter/material.dart';

class ReservationData {
  final DateTime date;
  final TimeOfDay time;
  final String areaId;
  final String areaCode;
  final int personCount;
  final String formattedDate;
  final String formattedTime;
  final List<String> selectedTableIds;

  // ✅ FIELD BARU
  final String? servingType; // 'ala carte' or 'buffet'
  final List<String> equipment; // Array equipment yang dipilih

  ReservationData({
    required this.date,
    required this.time,
    required this.areaId,
    required this.areaCode,
    required this.personCount,
    required this.formattedDate,
    required this.formattedTime,
    this.selectedTableIds = const [],
    this.servingType, // Default null (opsional)
    this.equipment = const [], // Default empty list
  });

  // Create a copy with updated values
  ReservationData copyWith({
    DateTime? date,
    TimeOfDay? time,
    String? areaId,
    String? areaCode,
    int? personCount,
    String? formattedDate,
    String? formattedTime,
    List<String>? selectedTableIds,
    String? servingType,
    List<String>? equipment,
  }) {
    return ReservationData(
      date: date ?? this.date,
      time: time ?? this.time,
      areaId: areaId ?? this.areaId,
      areaCode: areaCode ?? this.areaCode,
      personCount: personCount ?? this.personCount,
      formattedDate: formattedDate ?? this.formattedDate,
      formattedTime: formattedTime ?? this.formattedTime,
      selectedTableIds: selectedTableIds ?? this.selectedTableIds,
      servingType: servingType ?? this.servingType,
      equipment: equipment ?? this.equipment,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'date': formattedDate,
      'time': formattedTime,
      'area_id': areaId,
      'area_code': areaCode,
      'person_count': personCount,
      'selected_table_ids': selectedTableIds,
      if (servingType != null) 'serving_type': servingType,
      if (equipment.isNotEmpty) 'equipment': equipment,
    };
  }

  @override
  String toString() {
    return 'ReservationData(date: $formattedDate, time: $formattedTime, '
        'areaCode: $areaCode, personCount: $personCount, '
        'selectedTables: ${selectedTableIds.join(", ")}, '
        'servingType: $servingType, equipment: ${equipment.join(", ")})';
  }
}

/// Model lebih ringkas khusus untuk Open Bill
class OpenBillData {
  final String reservationId;
  final DateTime date;
  final TimeOfDay time;
  final String areaId;
  final String areaCode;
  final String tableId;
  final String tableNumbers;

  OpenBillData({
    required this.reservationId,
    required this.date,
    required this.time,
    required this.areaId,
    required this.areaCode,
    required this.tableId,
    required this.tableNumbers,
  });

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'area_id': areaId,
      'area_code': areaCode,
      'tableId': tableId,
      'table_numbers': tableNumbers,
    };
  }

  @override
  String toString() {
    return 'OpenBillData(reservationId: $reservationId, date: $date, time: $time, areaId: $areaId, areaCode: $areaCode, tableId: $tableId, tableNumbers: $tableNumbers)';
  }
}