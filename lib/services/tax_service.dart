import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaxItem {
  final String id;
  final String type;
  final String name;
  final double percentage;
  final List<String> appliesToOutlets;
  final bool isActive;

  TaxItem({
    required this.id,
    required this.type,
    required this.name,
    required this.percentage,
    required this.appliesToOutlets,
    required this.isActive,
  });

  factory TaxItem.fromJson(Map<String, dynamic> json) {
    return TaxItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      appliesToOutlets: (json['appliesToOutlets'] as List<dynamic>?)
          ?.map((outlet) => outlet['_id'] as String)
          .toList() ?? [],
      isActive: json['isActive'] ?? false,
    );
  }
}

class TaxCalculationResult {
  final double ppnAmount;
  final double pb1Amount;
  final double totalTaxAmount;
  final List<Map<String, dynamic>> taxDetails;

  TaxCalculationResult({
    required this.ppnAmount,
    required this.pb1Amount,
    required this.totalTaxAmount,
    required this.taxDetails,
  });
}

class TaxService {
  final String? baseUrl = dotenv.env['BASE_URL'];
  List<TaxItem>? _cachedTaxes;

  Future<List<TaxItem>> getTaxesAndServices() async {
    if (_cachedTaxes != null) {
      return _cachedTaxes!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.get(
        Uri.parse('$baseUrl/api/tax-service/cashier'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> taxesData = responseData['data'] ?? [];

        _cachedTaxes = taxesData
            .map((taxData) => TaxItem.fromJson(taxData))
            .where((tax) => tax.isActive)
            .toList();

        return _cachedTaxes!;
      } else {
        throw Exception('Failed to load taxes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching taxes: $e');
      return [];
    }
  }

  TaxCalculationResult calculateTaxes({
    required double subtotal,
    required String outletId,
    required bool isReservation,
    required bool isOpenBill,
  }) {
    if (_cachedTaxes == null || _cachedTaxes!.isEmpty) {
      return TaxCalculationResult(
        ppnAmount: 0,
        pb1Amount: 0,
        totalTaxAmount: 0,
        taxDetails: [],
      );
    }

    double ppnAmount = 0;
    double pb1Amount = 0;
    List<Map<String, dynamic>> taxDetails = [];

    // Don't apply any tax for open bill orders
    // if (isOpenBill) {
    //   return TaxCalculationResult(
    //     ppnAmount: 0,
    //     pb1Amount: 0,
    //     totalTaxAmount: 0,
    //     taxDetails: [],
    //   );
    // }

    for (TaxItem tax in _cachedTaxes!) {
      // Check if tax applies to this outlet
      if (!tax.appliesToOutlets.contains(outletId)) {
        continue;
      }

      if (tax.name == 'PPN') {
        // PPN applies to all transactions except open bill
        ppnAmount = subtotal * (tax.percentage / 100);
        taxDetails.add({
          'id': tax.id,
          'name': tax.name,
          'type': tax.type,
          'percentage': tax.percentage,
          'amount': ppnAmount,
        });
      } else if (tax.name == 'PB1' && isReservation) {
        // PB1 only applies to reservations (except open bill)
        pb1Amount = subtotal * (tax.percentage / 100);
        taxDetails.add({
          'id': tax.id,
          'name': tax.name,
          'type': tax.type,
          'percentage': tax.percentage,
          'amount': pb1Amount,
        });
      }
    }

    return TaxCalculationResult(
      ppnAmount: ppnAmount,
      pb1Amount: pb1Amount,
      totalTaxAmount: ppnAmount + pb1Amount,
      taxDetails: taxDetails,
    );
  }

  void clearCache() {
    _cachedTaxes = null;
  }
}