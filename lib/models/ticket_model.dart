
import 'package:flutter/material.dart';

import 'event_model.dart';

class Ticket {
  final String id;
  final Event event;
  final String user;
  final int quantity;
  final int totalPrice;
  final String status;
  final String paymentMethod;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.event,
    required this.user,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] ?? '',
      event: Event.fromJson(json['event'] ?? {}),
      user: json['user'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      status: json['status'] ?? 'unknown',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentId: json['payment_id'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'event': event.toJson(),
      'user': user,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'paymentMethod': paymentMethod,
      'payment_id': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get formatted status
  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'paid':
        return 'Lunas';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  // Helper method to get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format currency
  String get formattedPrice {
    return 'Rp ${totalPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  @override
  String toString() {
    return 'Ticket{id: $id, eventId: ${event.id}, quantity: $quantity, totalPrice: $totalPrice, status: $status}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Ticket &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}