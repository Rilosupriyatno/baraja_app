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
  final List<String> selectedTableIds; // New field for selected table IDs

  ReservationData({
    required this.date,
    required this.time,
    required this.areaId,
    required this.areaCode,
    required this.personCount,
    required this.formattedDate,
    required this.formattedTime,
    this.selectedTableIds = const [], // Default to empty list
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
    };
  }

  @override
  String toString() {
    return 'ReservationData(date: $formattedDate, time: $formattedTime, '
        'areaCode: $areaCode, personCount: $personCount, '
        'selectedTables: ${selectedTableIds.join(", ")})';
  }
}