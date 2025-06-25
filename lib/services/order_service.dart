import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';

class OrderService {
  // Change this to your actual API base URL
  final String? baseUrl = dotenv.env['BASE_URL'];

// Method to create a new order
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String userId,
    required String userName, // This won't be sent to backend but kept for local use
    required OrderType orderType,
    String? tableNumber,
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
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Convert TimeOfDay to string format if it exists
      String? pickupTimeString;
      if (pickupTime != null) {
        // Convert TimeOfDay to 24-hour format string (HH:mm)
        final hour = pickupTime.hour.toString().padLeft(2, '0');
        final minute = pickupTime.minute.toString().padLeft(2, '0');
        pickupTimeString = '$hour:$minute';
      }

      // Debug: Print values to verify they're being passed correctly
      print('Order Type: ${orderType.toString().split('.').last}');
      print('Delivery Address: "$deliveryAddress"');
      print('Delivery Address Length: ${deliveryAddress?.length ?? 0}');
      print('Table Number: "$tableNumber"');
      print('Pickup Time: "$pickupTimeString"');

      // Prepare order data - matching backend expectations exactly
      final orderData = <String, dynamic>{
        'userId': userId,
        'items': items,
        'orderType': orderType.toString().split('.').last,
        'paymentDetails': paymentDetails,
        'outlet': '67cbc9560f025d897d69f889', // Required by backend
      };

      // Add optional fields only if they have values
      if (voucherCode != null && voucherCode.isNotEmpty) {
        orderData['voucherCode'] = voucherCode;
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

      if (orderType.toString().split('.').last == 'reservation') {
        if (reservationData != null) {
          orderData['reservationData'] = {
            'reservationTime': reservationData.formattedTime,
            'guestCount': reservationData.personCount,
            'areaIds': reservationData.areaId,
            'tableIds': reservationData.selectedTableIds,
            'reservationDate': reservationData.formattedDate,
          };
        }
        // Table number is also required for reservations
        if (tableNumber != null && tableNumber.isNotEmpty) {
          orderData['tableNumber'] = tableNumber;
        }
      }

      print('Final orderData:');
      print(orderData);

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Make API request
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
        // Order created successfully
        return jsonDecode(response.body);
      } else {
        // Handle error
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to create order: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }

  // Fungsi untuk mendapatkan riwayat pesanan pengguna

  Future<List<Order>> getUserOrderHistory() async {
    try {
      // Ambil userId dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Updated token key to match createOrder method
          'Authorization': 'Bearer ${prefs.getString('authToken') ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Updated to match new API structure
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

  // Static configuration untuk tracking
  static const Duration requestTimeout = Duration(seconds: 10);
  /// Mengambil data order berdasarkan orderId untuk tracking
  ///
  /// Returns: Map<String, dynamic> dengan structure:
  /// - success: bool
  /// - data: Map<String, dynamic>? (orderData)
  /// - error: String? (error message)

  Future<Map<String, dynamic>> getOrderForTracking(String id) async {
    try {
      // Get auth token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      // Headers untuk request
      final headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print(id);

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/order/$id'),
            headers: headers,
          )
          .timeout(requestTimeout);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Response data: $jsonData');
        return {
          'success': true,
          'data': jsonData['orderData'] ??
              jsonData, // Fallback jika structure berbeda
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

  /// Mengambil status order dalam format yang mudah digunakan untuk tracking UI
  ///
  /// Returns: Map<String, dynamic> dengan structure:
  /// - status: String (order status text)
  /// - color: Color (status color)
  /// - icon: IconData (status icon)

  Map<String, dynamic> getOrderStatusInfo(Map<String, dynamic> orderData) {
    // Cek payment status terlebih dahulu
    final paymentStatus =
        orderData['paymentStatus']?.toString().toLowerCase() ?? '';
    print(paymentStatus);
    if (paymentStatus == 'settlement') {
      // Jika sudah lunas, cek order status
      final orderStatus = orderData['orderStatus']?.toString() ?? '';
      switch (orderStatus) {
        case 'Pending':
          // return {
          //   'status': 'Pesanan dikonfirmasi',
          //   'color': const Color(0xFF3B82F6),
          //   'icon': Icons.check_circle,
          // };
          return {
            'status': 'Menunggu konfirmasi',
            'color': const Color(0xFFF68F3B),
            'icon': Icons.alarm_outlined,
          };
        case 'OnProcess':
          return {
            'status': 'Pesananmu sedang dibuat',
            'color': const Color(0xFFF59E0B),
            'icon': Icons.coffee_maker,
          };
        case 'Completed':
          return {
            'status': 'Selamat Menikmati',
            'color': const Color(0xFF10B981),
            'icon': Icons.done_all,
          };

        // case 'on the way':
        //   return {
        //     'status': 'Pesanan dalam perjalanan',
        //     'color': const Color(0xFF8B5CF6),
        //     'icon': Icons.local_shipping,
        //   };
        // case 'completed':
        //   return {
        //     'status': 'Pesanan selesai',
        //     'color': const Color(0xFF059669),
        //     'icon': Icons.celebration,
        //   };

        case 'Canceled':
          return {
            'status': 'Pesanan dibatalkan',
            'color': const Color(0xFFEF4444),
            'icon': Icons.cancel,
          };
        default:
          return {
            'status': 'Pesananmu sedang dibuat',
            'color': const Color(0xFFF59E0B),
            'icon': Icons.coffee_maker,
          };
      }
    } else if (paymentStatus == 'pending') {
      return {
        'status': 'Menunggu pembayaran',
        'color': const Color(0xFFEF4444),
        'icon': Icons.payment,
      };
    } else {
      return {
        'status': 'Status tidak diketahui',
        'color': const Color(0xFF6B7280),
        'icon': Icons.help_outline,
      };
    }
  }

  // Updated mapping function to match new API structure and include notes

  Order _mapToOrder(Map<String, dynamic> orderData) {
    // Mengonversi status dari string ke enum OrderStatus

    OrderStatus getOrderStatus(String statusString) {
      switch (statusString.toLowerCase()) {
        case 'pending':
          return OrderStatus.pending;
        case 'processing':
          return OrderStatus.processing;
        case 'on the way':
          return OrderStatus.onTheWay;
        case 'ready':
          return OrderStatus.ready;
        case 'completed':
          return OrderStatus.completed;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    // Mengonversi orderType dari string ke enum OrderType (default to dineIn if not provided)

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
        default:
          return OrderType.dineIn;
      }
    }

    // Membuat list CartItem dari items pada orderData

    List<CartItem> cartItems = [];
    if (orderData['items'] != null) {
      for (var item in orderData['items']) {
        // Mendapatkan informasi menuItem
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
          notes: item['notes'], // Added notes field from API response
        ));
      }
    }

    // Menghitung total dan subtotal

    int subtotal = 0;
    for (var item in cartItems) {
      subtotal += item.totalprice;
    }
    // Menghitung diskon jika ada voucher (default 0 for new structure)
    int discount = 0;
    // Add discount calculation logic here if needed
    // Total setelah diskon
    int total = subtotal - discount;
    // Membuat objek Order dengan data baru

    return Order(
      id: orderData['_id'] ?? '',
      orderId: orderData['orderId'] ?? '',
      items: cartItems,
      orderType: getOrderType(orderData['orderType']),
      tableNumber: orderData['tableNumber'] ?? '',
      deliveryAddress: orderData['deliveryAddress'] ?? '',
      pickupTime: null, // Add if available in API
      paymentDetails: {
        'method': orderData['paymentMethod'] ?? 'Cash',
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
