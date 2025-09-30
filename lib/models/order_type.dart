import 'package:flutter/material.dart';

enum OrderType {
  dineIn,
  delivery,
  pickup,
  takeAway,  // ✅ Tambahan baru
  reservation,
}

extension OrderTypeExtension on OrderType {
  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-in';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Pickup';
      case OrderType.takeAway:
        return 'Take Away';  // ✅ Tambahan baru
      case OrderType.reservation:
        return 'Reservation';
    }
  }

  String get description {
    switch (this) {
      case OrderType.dineIn:
        return 'Enjoy your meal at our restaurant';
      case OrderType.delivery:
        return 'We deliver to your location';
      case OrderType.pickup:
        return 'Pick up your order at our store';
      case OrderType.takeAway:
        return 'Buy and take your order home';  // ✅ Tambahan baru
      case OrderType.reservation:
        return 'Reserve a table for your visit';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.dineIn:
        return Icons.restaurant;
      case OrderType.delivery:
        return Icons.delivery_dining;
      case OrderType.pickup:
        return Icons.store;
      case OrderType.takeAway:
        return Icons.shopping_bag_outlined;  // ✅ Tambahan baru
      case OrderType.reservation:
        return Icons.event_seat;
    }
  }
}