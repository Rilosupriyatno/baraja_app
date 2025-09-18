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
    OpenBillData? openBillData, // Add this parameter
  }) async {
    try {
      // Convert TimeOfDay to string format if it exists
      String? pickupTimeString;
      if (pickupTime != null) {
        final hour = pickupTime.hour.toString().padLeft(2, '0');
        final minute = pickupTime.minute.toString().padLeft(2, '0');
        pickupTimeString = '$hour:$minute';
      }

      // Debug prints
      print('Order Type: ${orderType.toString().split('.').last}');
      print('Reservation Type: ${reservationType?.toString().split('.').last}');
      print('Open Bill Data: $openBillData');
      print('Delivery Address: "$deliveryAddress"');
      print('Table Number: "$tableNumber"');
      print('Pickup Time: "$pickupTimeString"');

      // Prepare order data
      final orderData = <String, dynamic>{
        'userId': userId,
        'items': items,
        'orderType': orderType.toString().split('.').last,
        'paymentDetails': paymentDetails,
        'outlet': outletId ?? '67cbc9560f025d897d69f889',
      };

      // Add optional fields
      if (voucherCode != null && voucherCode.isNotEmpty) {
        orderData['voucherCode'] = voucherCode;
      }

      // Handle Open Bill scenario
      if (openBillData != null) {
        orderData['isOpenBill'] = true;
        orderData['openBillData'] = {
          'reservationId': openBillData.reservationId,
          'tableNumbers': openBillData.tableNumbers,
        };
      }

      // Add conditional fields based on order type
      if (orderType.toString().split('.').last == 'dineIn' &&
          tableNumber != null && tableNumber.isNotEmpty) {
        orderData['tableNumber'] = tableNumber;
      }

      if (orderType.toString().split('.').last == 'delivery' &&
          deliveryAddress != null && deliveryAddress.isNotEmpty) {
        orderData['deliveryAddress'] = deliveryAddress;
      }

      if (orderType.toString().split('.').last == 'pickup' && pickupTimeString != null) {
        orderData['pickupTime'] = pickupTimeString;
      }

      // Handle reservation with reservationType
      if (orderType.toString().split('.').last == 'reservation') {
        if (reservationData != null) {
          // Data reservasi dasar
          orderData['reservationData'] = {
            'reservationTime': reservationData.formattedTime,
            'guestCount': reservationData.personCount,
            'areaIds': reservationData.areaId,
            'tableIds': reservationData.selectedTableIds,
            'reservationDate': reservationData.formattedDate,
          };

          // Send reservationType to backend if exists
          if (reservationType != null) {
            orderData['reservationData']['reservationType'] =
                reservationType.toString().split('.').last;
            orderData['reservationType'] = reservationType.toString().split('.').last;
          }
        }

        // Table number for reservations (if needed)
        if (tableNumber != null && tableNumber.isNotEmpty) {
          orderData['tableNumber'] = tableNumber;
        }
      }

      print('Final orderData:');
      print(orderData);

      // Get auth token and send request
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to create order: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }

  // ... rest of your existing methods remain the same
  Future<List<Order>> getUserOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }
      print("ini adalah authToken = ${prefs.getString('authToken')}");

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
      print('Error fetching order history: $e');
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

        return {
          'success': true,
          'data': orderData,
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load order: ${response.statusCode}',
        };
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else {
        errorMessage = 'Gagal memuat data pesanan. Silakan coba lagi.';
      }

      return {
        'success': false,
        'data': null,
        'error': errorMessage,
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

        print("Data dari getPaymentStatus: $jsonData");
        return {
          'success': true,
          'data': jsonData,
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': 'Failed to load payment status: ${response.statusCode}',
        };
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else {
        errorMessage = 'Gagal memuat status pembayaran. Silakan coba lagi.';
      }

      return {
        'success': false,
        'data': null,
        'error': errorMessage,
      };
    }
  }

  Map<String, dynamic> getOrderStatusInfo(Map<String, dynamic> orderData) {
    print('=== getOrderStatusInfo Debug ===');
    print('Input orderData: $orderData');

    String paymentStatus = '';

    if (orderData['paymentStatus'] != null) {
      paymentStatus = orderData['paymentStatus'].toString();
    } else if (orderData['paymentDetails'] != null &&
        orderData['paymentDetails']['status'] != null) {
      paymentStatus = orderData['paymentDetails']['status'].toString();
    }

    String orderStatus = '';

    if (orderData['orderStatus'] != null) {
      orderStatus = orderData['orderStatus'].toString();
    } else if (orderData['status'] != null) {
      orderStatus = orderData['status'].toString();
    }

    print('Payment Status: "$paymentStatus"');
    print('Order Status: "$orderStatus"');

    // ✅ Handle status Reserved khusus untuk reservasi
    if (orderStatus == 'Reserved') {
      if (paymentStatus.toLowerCase() == 'settlement' ||
          paymentStatus.toLowerCase() == 'paid' ||
          paymentStatus.toLowerCase() == 'capture') {
        return {
          'status': 'Reservasi Berhasil - Silakan datang ke restoran',
          'color': const Color(0xFF10B981),
          'icon': Icons.event_seat,
        };
      } else if (paymentStatus.toLowerCase() == 'pending') {
        return {
          'status': 'Reservasi - Menunggu pembayaran',
          'color': const Color(0xFFEF4444),
          'icon': Icons.payment,
        };
      } else {
        return {
          'status': 'Reservasi - Status tidak diketahui',
          'color': const Color(0xFFF68F3B),
          'icon': Icons.event_seat,
        };
      }
    }

    if (paymentStatus.toLowerCase() == 'settlement' ||
        paymentStatus.toLowerCase() == 'paid' ||
        paymentStatus.toLowerCase() == 'capture') {

      print('Payment is successful, checking order status...');

      switch (orderStatus) {
        case 'Pending':
          print('Returning Pending status');
          return {
            'status': 'Menunggu konfirmasi kasir',
            'color': const Color(0xFFF68F3B),
            'icon': Icons.alarm_outlined,
          };
        case 'Waiting':
          print('Returning Waiting status');
          return {
            'status': 'Menunggu konfirmasi kitchen',
            'color': const Color(0xFF3B82F6),
            'icon': Icons.restaurant_menu,
          };
        case 'OnProcess':
          print('Returning OnProcess status');
          return {
            'status': 'Pesananmu sedang dibuat',
            'color': const Color(0xFFF59E0B),
            'icon': Icons.coffee_maker,
          };
        case 'Completed':
          print('Returning Completed status');
          return {
            'status': 'Selamat Menikmati',
            'color': const Color(0xFF10B981),
            'icon': Icons.done_all,
          };
        case 'OnTheWay':
          print('Returning OnTheWay status');
          return {
            'status': 'Pesanan dalam perjalanan',
            'color': const Color(0xFF8B5CF6),
            'icon': Icons.local_shipping,
          };
        case 'Ready':
          print('Returning Ready status');
          return {
            'status': 'Pesanan siap diambil',
            'color': const Color(0xFF10B981),
            'icon': Icons.check_circle,
          };
        case 'Canceled':
        case 'Cancelled':
          print('Returning Cancelled status');
          return {
            'status': 'Pesanan dibatalkan',
            'color': const Color(0xFFEF4444),
            'icon': Icons.cancel,
          };
        default:
          print('Unknown order status, returning default');
          return {
            'status': 'Status: $orderStatus',
            'color': const Color(0xFFF68F3B),
            'icon': Icons.info_outline,
          };
      }
    } else if (paymentStatus.toLowerCase() == 'pending') {
      print('Returning pending payment status');
      return {
        'status': 'Menunggu pembayaran',
        'color': const Color(0xFFEF4444),
        'icon': Icons.payment,
      };
    } else if (paymentStatus.toLowerCase() == 'partial') {
      print('Returning pending payment status');
      return {
        'status': 'Menunggu Pelunasan',
        'color': const Color(0xFFFF5722),
        'icon': Icons.payment,
      };
    } else if (['expire', 'Unpaid'].contains(paymentStatus.toLowerCase())) {
      print('Returning expired payment status');
      return {
        'status': 'Pembayaran kadaluarsa',
        'color': const Color(0xFFEF4444),
        'icon': Icons.timer_off,
      };
    } else if (paymentStatus.toLowerCase() == 'cancel') {
      print('Returning cancelled payment status');
      return {
        'status': 'Pembayaran dibatalkan',
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel,
      };
    } else {
      print('Unknown payment status, returning unknown status');
      return {
        'status': paymentStatus.isNotEmpty
            ? 'Status pembayaran: $paymentStatus'
            : 'Status tidak diketahui',
        'color': const Color(0xFF6B7280),
        'icon': Icons.help_outline,
      };
    }
  }

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
        case 'reserved': // ✅ Tambah status untuk reservasi
          return OrderStatus.pending; // atau buat enum baru untuk reserved
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
        case 'reservation': // ✅ Tambah case untuk reservation
          return OrderType.reservation;
        default:
          return OrderType.dineIn;
      }
    }

    List<CartItem> cartItems = [];

    // ✅ Handle jika items ada dan tidak kosong
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

    // ✅ Gunakan grandTotal untuk semua jenis order
    int subtotal = 0;
    int discount = 0;
    int total = 0;

    // Gunakan grandTotal dari backend untuk semua order
    total = orderData['grandTotal'] ?? orderData['totalPrice'] ?? orderData['total'] ?? 0;
    subtotal = total; // Set subtotal sama dengan total
    discount = orderData['discount'] ?? 0;

    // ✅ COMMENTED - Logic lama untuk perhitungan berbeda antara reservasi dan order biasa
    // bool isReservation = orderData['status']?.toLowerCase() == 'reserved' ||
    //                     orderData['orderType']?.toLowerCase() == 'reservation';
    //
    // if (isReservation) {
    //   // ✅ Untuk reservasi, gunakan grandTotal dari backend
    //   total = orderData['grandTotal'] ?? orderData['totalPrice'] ?? orderData['total'] ?? 0;
    //   subtotal = total; // Set subtotal sama dengan total untuk reservasi
    //   discount = 0; // Tidak ada discount untuk reservasi
    // } else {
    //   // ✅ Untuk order biasa, hitung dari items
    //   if (cartItems.isNotEmpty) {
    //     for (var item in cartItems) {
    //       subtotal += item.totalprice;
    //     }
    //   } else {
    //     subtotal = orderData['subtotal'] ?? 0;
    //   }
    //   discount = orderData['discount'] ?? 0;
    //   total = orderData['total'] ?? orderData['totalPrice'] ?? (subtotal - discount);
    // }

    // ✅ Untuk reservasi tanpa items, buat placeholder CartItem
    bool isReservation = orderData['status']?.toLowerCase() == 'reserved' ||
        orderData['orderType']?.toLowerCase() == 'reservation';

    if (cartItems.isEmpty && isReservation) {
      cartItems.add(CartItem(
        id: 'reservation-placeholder',
        name: 'Reservasi Meja',
        imageUrl: '',
        price: 0,
        totalprice: 0,
        quantity: 1,
        addons: [],
        toppings: [],
        notes: 'Reservasi - Total biaya dari sistem',
      ));
    }

    return Order(
      id: orderData['_id'] ?? '',
      orderId: orderData['order_id'] ?? orderData['orderId'] ?? '', // ✅ Gunakan order_id dari response
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