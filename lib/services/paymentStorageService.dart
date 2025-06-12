// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';

class PaymentStorageService {
  static const String _paymentPrefix = 'payment_details_';

  /// Save payment details for an order with the new payment response format
  static Future<bool> savePaymentDetails({
    required String orderId,
    required Map<String, dynamic> paymentResponse,
    required Map<String, String?> paymentDetails,
    required int subtotal,
    required int discount,
    required int total,
    String? voucherCode,
    // New parameters for complete order data
    required List<CartItem> items,
    required OrderType orderType,
    required String tableNumber,
    required String deliveryAddress,
    TimeOfDay? pickupTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert CartItem list to JSON-serializable format
      final itemsJson = items.map((item) => {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'totalprice': item.totalprice,
          'quantity': item.quantity,
          'addons': item.addons,
          'toppings': item.toppings,
          'imageUrl': item.imageUrl,
          'notes': item.notes,
      }).toList();

      // Extract key information from payment response
      final paymentData = {
        // Order information
        'orderId': orderId,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'voucherCode': voucherCode,
        'savedAt': DateTime.now().toIso8601String(),

        // Order details
        'items': itemsJson,
        'orderType': orderType.toString(),
        'tableNumber': tableNumber,
        'deliveryAddress': deliveryAddress,
        'pickupTime': pickupTime != null ? {
          'hour': pickupTime.hour,
          'minute': pickupTime.minute,
        } : null,

        // Payment method details (from paymentDetails parameter)
        'paymentMethod': paymentDetails,

        // Payment response from Midtrans/Payment Gateway
        'paymentResponse': {
          'status_code': paymentResponse['status_code'],
          'status_message': paymentResponse['status_message'],
          'transaction_id': paymentResponse['transaction_id'],
          'order_id': paymentResponse['order_id'],
          'merchant_id': paymentResponse['merchant_id'],
          'gross_amount': paymentResponse['gross_amount'],
          'currency': paymentResponse['currency'],
          'payment_type': paymentResponse['payment_type'],
          'transaction_time': paymentResponse['transaction_time'],
          'transaction_status': paymentResponse['transaction_status'],
          'fraud_status': paymentResponse['fraud_status'],
          'expiry_time': paymentResponse['expiry_time'],

          // Handle VA numbers if exists
          if (paymentResponse.containsKey('va_numbers') && paymentResponse['va_numbers'] != null)
            'va_numbers': paymentResponse['va_numbers'],

          // Handle other payment specific data
          if (paymentResponse.containsKey('qr_string'))
            'qr_string': paymentResponse['qr_string'],
          if (paymentResponse.containsKey('deeplink_redirect_url'))
            'deeplink_redirect_url': paymentResponse['deeplink_redirect_url'],
          if (paymentResponse.containsKey('redirect_url'))
            'redirect_url': paymentResponse['redirect_url'],
        },
      };

      final jsonString = jsonEncode(paymentData);
      return await prefs.setString('$_paymentPrefix$orderId', jsonString);
    } catch (e) {
      print('Error saving payment details: $e');
      return false;
    }
  }

  /// Get payment details for an order
  static Future<Map<String, dynamic>?> getPaymentDetails(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_paymentPrefix$orderId');

      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting payment details: $e');
      return null;
    }
  }

  /// Get cart items from saved payment details
  static Future<List<CartItem>?> getCartItems(String orderId) async {
    try {
      final paymentDetails = await getPaymentDetails(orderId);
      if (paymentDetails != null && paymentDetails.containsKey('items')) {
        final itemsJson = paymentDetails['items'] as List<dynamic>;
        return itemsJson.map((item) => CartItem(
          id: item['id'],
          name: item['name'],
          price: item['price'],
          totalprice: item['totalprice'],
          quantity: item['quantity'],
          addons: item['addons'] ?? [],
          toppings: item['toppings'],
          imageUrl: item['imageUrl'],
          notes: item['notes'],
        )).toList();
      }
      return null;
    } catch (e) {
      print('Error getting cart items: $e');
      return null;
    }
  }

  /// Get order type from saved payment details
  static Future<OrderType?> getOrderType(String orderId) async {
    try {
      final paymentDetails = await getPaymentDetails(orderId);
      if (paymentDetails != null && paymentDetails.containsKey('orderType')) {
        final orderTypeString = paymentDetails['orderType'] as String;
        return OrderType.values.firstWhere(
              (type) => type.toString() == orderTypeString,
          orElse: () => OrderType.dineIn,
        );
      }
      return null;
    } catch (e) {
      print('Error getting order type: $e');
      return null;
    }
  }

  /// Get pickup time from saved payment details
  static Future<TimeOfDay?> getPickupTime(String orderId) async {
    try {
      final paymentDetails = await getPaymentDetails(orderId);
      if (paymentDetails != null && paymentDetails.containsKey('pickupTime') && paymentDetails['pickupTime'] != null) {
        final pickupTimeData = paymentDetails['pickupTime'] as Map<String, dynamic>;
        return TimeOfDay(
          hour: pickupTimeData['hour'],
          minute: pickupTimeData['minute'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting pickup time: $e');
      return null;
    }
  }

  /// Get only payment response data for an order
  static Future<Map<String, dynamic>?> getPaymentResponse(String orderId) async {
    try {
      final paymentDetails = await getPaymentDetails(orderId);
      if (paymentDetails != null && paymentDetails.containsKey('paymentResponse')) {
        return paymentDetails['paymentResponse'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting payment response: $e');
      return null;
    }
  }

  /// Get transaction status for an order
  static Future<String?> getTransactionStatus(String orderId) async {
    try {
      final paymentResponse = await getPaymentResponse(orderId);
      if (paymentResponse != null) {
        return paymentResponse['transaction_status'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting transaction status: $e');
      return null;
    }
  }

  /// Get VA numbers for an order (for bank transfer)
  static Future<List<Map<String, dynamic>>?> getVANumbers(String orderId) async {
    try {
      final paymentResponse = await getPaymentResponse(orderId);
      if (paymentResponse != null && paymentResponse.containsKey('va_numbers')) {
        return List<Map<String, dynamic>>.from(paymentResponse['va_numbers']);
      }
      return null;
    } catch (e) {
      print('Error getting VA numbers: $e');
      return null;
    }
  }

  /// Update transaction status for an order
  static Future<bool> updateTransactionStatus(String orderId, String newStatus) async {
    try {
      final existingData = await getPaymentDetails(orderId);
      if (existingData != null) {
        // Update the transaction status in payment response
        if (existingData.containsKey('paymentResponse')) {
          existingData['paymentResponse']['transaction_status'] = newStatus;

          // Update saved timestamp
          existingData['updatedAt'] = DateTime.now().toIso8601String();

          final prefs = await SharedPreferences.getInstance();
          final jsonString = jsonEncode(existingData);
          return await prefs.setString('$_paymentPrefix$orderId', jsonString);
        }
      }
      return false;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  /// Check if payment details exist for an order
  static Future<bool> hasPaymentDetails(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_paymentPrefix$orderId');
    } catch (e) {
      print('Error checking payment details: $e');
      return false;
    }
  }

  /// Remove payment details for an order
  static Future<bool> removePaymentDetails(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_paymentPrefix$orderId');
    } catch (e) {
      print('Error removing payment details: $e');
      return false;
    }
  }

  /// Get all stored payment details
  static Future<List<Map<String, dynamic>>> getAllPaymentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_paymentPrefix));

      final List<Map<String, dynamic>> allPaymentDetails = [];

      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final paymentData = jsonDecode(jsonString) as Map<String, dynamic>;
          allPaymentDetails.add(paymentData);
        }
      }

      // Sort by savedAt timestamp (newest first)
      allPaymentDetails.sort((a, b) {
        final aTime = DateTime.tryParse(a['savedAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['savedAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return allPaymentDetails;
    } catch (e) {
      print('Error getting all payment details: $e');
      return [];
    }
  }

  /// Get payment details filtered by transaction status
  static Future<List<Map<String, dynamic>>> getPaymentDetailsByStatus(String status) async {
    try {
      final allPayments = await getAllPaymentDetails();
      return allPayments.where((payment) {
        if (payment.containsKey('paymentResponse')) {
          final paymentResponse = payment['paymentResponse'] as Map<String, dynamic>;
          return paymentResponse['transaction_status'] == status;
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error getting payment details by status: $e');
      return [];
    }
  }

  /// Clear all payment details (for cleanup)
  static Future<bool> clearAllPaymentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_paymentPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      return true;
    } catch (e) {
      print('Error clearing all payment details: $e');
      return false;
    }
  }

  /// Clean up expired payment details (older than specified days)
  static Future<int> cleanupExpiredPayments({int daysToKeep = 30}) async {
    try {
      final allPayments = await getAllPaymentDetails();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      int removedCount = 0;

      for (final payment in allPayments) {
        final savedAt = DateTime.tryParse(payment['savedAt'] ?? '');
        if (savedAt != null && savedAt.isBefore(cutoffDate)) {
          final orderId = payment['orderId'] as String;
          if (await removePaymentDetails(orderId)) {
            removedCount++;
          }
        }
      }

      return removedCount;
    } catch (e) {
      print('Error cleaning up expired payments: $e');
      return 0;
    }
  }
}