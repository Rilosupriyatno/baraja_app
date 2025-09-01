import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../screens/voucher_screen.dart';

class VoucherService {
  static final String? baseUrl = dotenv.env['BASE_URL'];

  // Model untuk Voucher dari database
  static Future<List<VoucherModel>> getAvailableVouchers({
    String? outletId,
    String? customerType = 'all',
  }) async {
    try {
      final queryParams = <String, String>{
        'isActive': 'true',
        'validNow': 'true', // Filter voucher yang masih berlaku
      };

      if (outletId != null) {
        queryParams['outletId'] = outletId;
      }

      if (customerType != null) {
        queryParams['customerType'] = customerType;
      }

      final uri = Uri.parse('$baseUrl/api/vouchers/available')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> vouchersJson = data['vouchers'] ?? [];

        return vouchersJson
            .map((json) => VoucherModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load vouchers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vouchers: $e');
      throw Exception('Failed to load vouchers: $e');
    }
  }

  // Validasi voucher berdasarkan kode
  static Future<VoucherValidationResult> validateVoucher({
    required String code,
    required double orderAmount,
    String? outletId,
    String? customerType = 'all',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/vouchers/validate'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'code': code,
          'orderAmount': orderAmount,
          'outletId': outletId,
          'customerType': customerType,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return VoucherValidationResult.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return VoucherValidationResult(
          isValid: false,
          message: errorData['message'] ?? 'Invalid voucher',
        );
      }
    } catch (e) {
      print('Error validating voucher: $e');
      return VoucherValidationResult(
        isValid: false,
        message: 'Error validating voucher: $e',
      );
    }
  }

  // Apply voucher (untuk tracking penggunaan)
  static Future<bool> applyVoucher({
    required String code,
    required double orderAmount,
    required String orderId,
    String? outletId,
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/vouchers/apply'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'code': code,
          'orderAmount': orderAmount,
          'orderId': orderId,
          'outletId': outletId,
          'customerId': customerId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error applying voucher: $e');
      return false;
    }
  }
}

// Model untuk outlet
class OutletModel {
  final String id;
  final String name;

  OutletModel({
    required this.id,
    required this.name,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

// Model untuk Voucher dari database
class VoucherModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final double discountAmount;
  final String discountType; // 'percentage' atau 'fixed'
  final DateTime validFrom;
  final DateTime validTo;
  final int quota;
  final List<OutletModel>? applicableOutlets; // Changed to List<OutletModel>
  final String customerType;
  final bool printOnReceipt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountAmount,
    required this.discountType,
    required this.validFrom,
    required this.validTo,
    required this.quota,
    this.applicableOutlets,
    required this.customerType,
    required this.printOnReceipt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    List<OutletModel>? outlets;
    if (json['applicableOutlets'] != null) {
      if (json['applicableOutlets'] is List) {
        outlets = (json['applicableOutlets'] as List)
            .map((outlet) => OutletModel.fromJson(outlet))
            .toList();
      }
    }

    return VoucherModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? json['_id'] ?? '', // Fallback to _id if code is null
      name: json['name'] ?? '',
      description: json['description'],
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      discountType: json['discountType'] ?? 'percentage',
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      quota: json['quota'] ?? 0,
      applicableOutlets: outlets,
      customerType: json['customerType'] ?? 'all',
      printOnReceipt: json['printOnReceipt'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'name': name,
      'description': description,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'quota': quota,
      'applicableOutlets': applicableOutlets?.map((outlet) => outlet.toJson()).toList(),
      'customerType': customerType,
      'printOnReceipt': printOnReceipt,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Calculate actual discount amount for the order
  double calculateDiscount(double orderAmount) {
    if (discountType == 'percentage') {
      return orderAmount * (discountAmount / 100);
    } else {
      return discountAmount;
    }
  }

  // Check if voucher is applicable for the order amount
  bool isApplicableForAmount(double orderAmount) {
    return true; // Always applicable since no minimum spend requirement
  }

  // Konversi ke model Voucher yang digunakan di UI
  Voucher toVoucherUI({double? orderAmount}) {
    String displayDescription = '';
    String additionalInfo = '';
    String? additionalRequirement;
    bool isDisabled = false;

    // Format deskripsi berdasarkan tipe diskon
    if (discountType == 'percentage') {
      displayDescription = 'Disc ${discountAmount.toInt()}%';

      if (orderAmount != null) {
        final discountValue = calculateDiscount(orderAmount);
        displayDescription += ' (Rp${_formatCurrency(discountValue)})';
      }

      additionalInfo = description ?? '';
    } else {
      displayDescription = 'Disc Rp${_formatCurrency(discountAmount)}';
      additionalInfo = description ?? '';
    }

    // Add validity info
    final now = DateTime.now();
    if (validTo.isBefore(now)) {
      isDisabled = true;
      additionalRequirement = 'This voucher has expired';
    } else {
      final daysLeft = validTo.difference(now).inDays;
      if (daysLeft <= 3) {
        additionalInfo += ' • Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}';
      }
    }

    return Voucher(
      code: code,
      description: displayDescription,
      additionalInfo: additionalInfo,
      additionalRequirement: additionalRequirement,
      iconAsset: 'assets/images/voucher_icon.png', // Default icon
      isDisabled: isDisabled,
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}

// Model untuk hasil validasi voucher
class VoucherValidationResult {
  final bool isValid;
  final String message;
  final double? discountAmount;
  final VoucherModel? voucher;

  VoucherValidationResult({
    required this.isValid,
    required this.message,
    this.discountAmount,
    this.voucher,
  });

  factory VoucherValidationResult.fromJson(Map<String, dynamic> json) {
    return VoucherValidationResult(
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? '',
      discountAmount: json['discountAmount']?.toDouble(),
      voucher: json['voucher'] != null
          ? VoucherModel.fromJson(json['voucher'])
          : null,
    );
  }
}