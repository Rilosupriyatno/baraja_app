import 'dart:convert';
import 'package:baraja_app/screens/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';

class OrderService {
  final String? baseUrl = dotenv.env['BASE_URL'];

// Update the createOrder method in your order_service.dart

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String userId,
    required String userName,
    required OrderType orderType,
    String? tableNumber,
    String? outletId,
    String? deliveryAddress,
    TimeOfDay? pickupTime,
    String? paymentMethod,
    String? paymentMethodName,
    String? bankName,
    String? bankCode,
    required int subtotal,
    required int discount,
    String? voucherCode,
    ReservationData? reservationData,
    ReservationType? reservationType,
    required Map<String, dynamic> paymentDetails,
    OpenBillData? openBillData,
    // Add tax-related parameters
    List<Map<String, dynamic>>? taxDetails,
    int? totalTax,
  }) async {
    try {
      String? pickupTimeString;
      if (pickupTime != null) {
        final hour = pickupTime.hour.toString().padLeft(2, '0');
        final minute = pickupTime.minute.toString().padLeft(2, '0');
        pickupTimeString = '$hour:$minute';
      }

      final orderData = <String, dynamic>{
        'userId': userId,
        'items': items,
        'orderType': orderType.toString().split('.').last,
        'paymentDetails': paymentDetails,
        'outlet': outletId ?? '67cbc9560f025d897d69f889',
        // Add tax information
        'taxDetails': taxDetails ?? [],
        'totalTax': totalTax ?? 0,
        'subtotal': subtotal,
        'discount': discount,
      };

      if (voucherCode != null && voucherCode.isNotEmpty) {
        orderData['voucherCode'] = voucherCode;
      }

      if (openBillData != null) {
        orderData['isOpenBill'] = true;
        orderData['openBillData'] = {
          'reservationId': openBillData.reservationId,
          'tableNumbers': openBillData.tableNumbers,
        };
      }

      if (orderType.toString().split('.').last == 'dineIn' &&
          tableNumber != null &&
          tableNumber.isNotEmpty) {
        orderData['tableNumber'] = tableNumber;
      }

      if (orderType.toString().split('.').last == 'delivery' &&
          deliveryAddress != null &&
          deliveryAddress.isNotEmpty) {
        orderData['deliveryAddress'] = deliveryAddress;
      }

      if (orderType.toString().split('.').last == 'pickup' &&
          pickupTimeString != null) {
        orderData['pickupTime'] = pickupTimeString;
      }

      if (orderType.toString().split('.').last == 'reservation') {
        if (reservationData != null) {
          orderData['reservationData'] = {
            'reservationTime': reservationData.formattedTime,
            'guestCount': reservationData.personCount,
            'areaIds': reservationData.areaId,
            'tableIds': reservationData.selectedTableIds,
            'reservationDate': reservationData.formattedDate,
          };

          if (reservationType != null) {
            orderData['reservationData']['reservationType'] =
                reservationType.toString().split('.').last;
            orderData['reservationType'] =
                reservationType.toString().split('.').last;
          }
        }

        if (tableNumber != null && tableNumber.isNotEmpty) {
          orderData['tableNumber'] = tableNumber;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.post(
        Uri.parse('$baseUrl/api/orderApp'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to create order: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<List<Order>> getUserOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('User ID not found');

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('authToken') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['orderHistory'] ?? [];
        return ordersData.map((orderData) => _mapToOrder(orderData)).toList();
      } else {
        throw Exception('Failed to load order history: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  static const Duration requestTimeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> getOrderForTracking(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl/api/order/$id'), headers: headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final orderData = jsonData['orderData'] ?? jsonData;

        if (orderData['orderStatus'] == null && orderData['status'] != null) {
          orderData['orderStatus'] = orderData['status'];
        }

        return {'success': true, 'data': orderData, 'error': null};
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load order: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Gagal memuat data pesanan. Silakan coba lagi.',
      };
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse('$baseUrl/api/getPaymentStatus/$id'), headers: headers)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {'success': true, 'data': jsonData, 'error': null};
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load payment status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'error': 'Gagal memuat status pembayaran. Silakan coba lagi.',
      };
    }
  }

  /// ========================================================
  ///  Perubahan penting ada di sini
  /// ========================================================
  Order _mapToOrder(Map<String, dynamic> orderData) {
    OrderStatus getOrderStatus(String statusString) {
      switch (statusString.toLowerCase()) {
        case 'pending':
          return OrderStatus.pending;
        case 'waiting':
          return OrderStatus.waiting;
        case 'onprocess':
          return OrderStatus.processing;
        case 'on the way':
          return OrderStatus.onTheWay;
        case 'ready':
          return OrderStatus.ready;
        case 'completed':
          return OrderStatus.completed;
        case 'cancelled':
          return OrderStatus.cancelled;
        case 'reserved':
          return OrderStatus.pending;
        default:
          return OrderStatus.pending;
      }
    }

    OrderType getOrderType(String? typeString) {
      if (typeString == null) return OrderType.dineIn;
      switch (typeString.toLowerCase()) {
        case 'delivery':
          return OrderType.delivery;
        case 'pick-up':
        case 'pickup':
          return OrderType.pickup;
        case 'dine-in':
        case 'dinein':
          return OrderType.dineIn;
        case 'reservation':
          return OrderType.reservation;
        default:
          return OrderType.dineIn;
      }
    }

    List<CartItem> cartItems = [];

    if (orderData['items'] != null && orderData['items'].isNotEmpty) {
      for (var item in orderData['items']) {
        final menuItem = item['menuItem'];
        List<Map<String, dynamic>> addonsList = [];
        if (item['addons'] != null && item['addons'].isNotEmpty) {
          for (var addon in item['addons']) {
            addonsList.add({
              'name': addon['name'] ?? addon['label'] ?? '',
              'price': addon['price'] ?? 0,
            });
          }
        }
        List<Map<String, dynamic>> toppingsList = [];
        if (item['toppings'] != null && item['toppings'].isNotEmpty) {
          for (var topping in item['toppings']) {
            toppingsList.add({
              'name': topping['name'] ?? '',
              'price': topping['price'] ?? 0,
            });
          }
        }
        cartItems.add(CartItem(
          id: menuItem['_id'] ?? '',
          name: menuItem['name'] ?? 'Unknown Item',
          imageUrl: menuItem['imageURL'] ?? '',
          price: menuItem['price'] ?? 0,
          totalprice: item['subtotal'] ?? 0,
          quantity: item['quantity'] ?? 1,
          addons: addonsList,
          toppings: toppingsList,
          notes: item['notes'],
        ));
      }
    }

    int subtotal = 0;
    int discount = 0;
    int total = 0;

    total = orderData['grandTotal'] ??
        orderData['totalPrice'] ??
        orderData['total'] ??
        0;
    subtotal = total;
    discount = orderData['discount'] ?? 0;

    // ✅ PATCH: kalau cartItems kosong tapi order valid → buat placeholder
    if (cartItems.isEmpty) {
      cartItems.add(CartItem(
        id: 'placeholder',
        name: orderData['orderType']?.toLowerCase() == 'reservation'
            ? 'Reservasi Meja'
            : 'Reservasi Tanpa Menu',
        imageUrl: '',
        price: total,
        totalprice: total,
        quantity: 1,
        addons: [],
        toppings: [],
        notes: 'Auto-generated placeholder untuk order tanpa detail item',
      ));
    }

    return Order(
      id: orderData['_id'] ?? '',
      orderId: orderData['order_id'] ?? orderData['orderId'] ?? '',
      items: cartItems,
      orderType: getOrderType(orderData['orderType']),
      tableNumber: orderData['tableNumber'] ?? '',
      deliveryAddress: orderData['deliveryAddress'] ?? '',
      pickupTime: null,
      paymentDetails: {
        'method': orderData['paymentMethod'] ?? 'Unknown',
        'status': orderData['paymentStatus'] ?? 'pending'
      },
      subtotal: subtotal,
      discount: discount,
      total: total,
      voucherCode: orderData['voucherCode'],
      orderTime: orderData['createdAt'] != null
          ? DateTime.parse(orderData['createdAt'])
          : DateTime.now(),
      status: getOrderStatus(orderData['status'] ?? 'Pending'),
    );
  }
}
