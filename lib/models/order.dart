import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';

enum OrderStatus {
  pending,
  processing,
  onTheWay,
  ready,
  completed,
  cancelled
}

class Order {
  final String id;
  final List<CartItem> items;
  final OrderType orderType;
  final String tableNumber;
  final String deliveryAddress;
  final TimeOfDay? pickupTime;
  final Map<String, String?> paymentDetails;
  final int subtotal;
  final int discount;
  final int total;
  final String? voucherCode;
  final DateTime orderTime;
  OrderStatus status;

  Order({
    required this.id,
    required this.items,
    required this.orderType,
    this.tableNumber = '',
    this.deliveryAddress = '',
    this.pickupTime,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.voucherCode,
    required this.orderTime,
    this.status = OrderStatus.pending,
    required this.paymentDetails,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => {
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'totalprice': item.totalprice,
        'addons': item.addons,
        'toppings': item.toppings,
        'quantity': item.quantity,
      }).toList(),
      'orderType': orderType.toString(),
      'tableNumber': tableNumber,
      'deliveryAddress': deliveryAddress,
      'pickupTime': pickupTime != null
          ? '${pickupTime!.hour}:${pickupTime!.minute}'
          : null,
      'paymentDetails': paymentDetails,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'voucherCode': voucherCode,
      'orderTime': orderTime.toIso8601String(),
      'status': status.toString(),
    };
  }

  // Create from Map for retrieval
  factory Order.fromMap(Map<String, dynamic> map) {
    // Parse pickup time if available
    TimeOfDay? pickupTime;
    if (map['pickupTime'] != null) {
      final timeParts = map['pickupTime'].split(':');
      pickupTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    // Parse order type
    OrderType orderType = OrderType.dineIn;
    if (map['orderType'] == OrderType.delivery.toString()) {
      orderType = OrderType.delivery;
    } else if (map['orderType'] == OrderType.pickup.toString()) {
      orderType = OrderType.pickup;
    }

    // Parse order status
    OrderStatus status = OrderStatus.pending;
    final statusString = map['status'];
    for (var s in OrderStatus.values) {
      if (s.toString() == statusString) {
        status = s;
        break;
      }
    }

    return Order(
      id: map['id'],
      items: (map['items'] as List).map((itemMap) => CartItem(
        id: itemMap['id'],
        name: itemMap['name'],
        imageUrl: itemMap['imageUrl'],
        price: itemMap['price'],
        totalprice: itemMap['totalprice'],
        addons: itemMap['addons'],
        toppings: itemMap['toppings'],
        quantity: itemMap['quantity'],
      )).toList(),
      orderType: orderType,
      tableNumber: map['tableNumber'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      pickupTime: pickupTime,
      paymentDetails: map['paymentDetails'],
      subtotal: map['subtotal'],
      discount: map['discount'],
      total: map['total'],
      voucherCode: map['voucherCode'],
      orderTime: DateTime.parse(map['orderTime']),
      status: status,
    );
  }

  // Helper method to get status text
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.processing:
        return 'Sedang Diproses';
      case OrderStatus.onTheWay:
        return 'Dalam Perjalanan';
      case OrderStatus.ready:
        return 'Siap Diambil';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}