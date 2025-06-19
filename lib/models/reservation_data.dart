// import 'package:flutter/material.dart';
//
// class ReservationData {
//   final DateTime date;
//   final TimeOfDay time;
//   final int floor;
//   final int personCount;
//   final String formattedDate;
//   final String formattedTime;
//
//   const ReservationData({
//     required this.date,
//     required this.time,
//     required this.floor,
//     required this.personCount,
//     required this.formattedDate,
//     required this.formattedTime,
//   });
//
//   @override
//   String toString() {
//     return 'ReservationData(date: $date, time: $time, floor: $floor, personCount: $personCount, formattedDate: $formattedDate, formattedTime: $formattedTime)';
//   }
// }

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

  ReservationData({
    required this.date,
    required this.time,
    required this.areaId,
    required this.areaCode,
    required this.personCount,
    required this.formattedDate,
    required this.formattedTime,
  });
}
