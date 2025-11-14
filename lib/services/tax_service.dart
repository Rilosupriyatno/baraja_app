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
    // Handle both populated and non-populated appliesToOutlets
    List<String> outlets = [];

    if (json['appliesToOutlets'] != null) {
      final outletsData = json['appliesToOutlets'] as List<dynamic>;
      outlets = outletsData.map((outlet) {
        // Check if outlet is a string (ID) or object (populated)
        if (outlet is String) {
          return outlet;
        } else if (outlet is Map<String, dynamic>) {
          // Handle populated outlet object
          return outlet['_id'] as String? ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    }

    return TaxItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      appliesToOutlets: outlets,
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
      print('📄 Using cached taxes data: ${_cachedTaxes!.length} items');
      return _cachedTaxes!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      print('🌐 Fetching taxes from: $baseUrl/api/tax-service/');

      final response = await http.get(
        Uri.parse('$baseUrl/api/tax-service/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> taxesData = responseData['data'] ?? [];

        print('\n=== FRONTEND TAX DATA ===');
        print('Raw response data: ${response.body}');
        print('Jumlah data dari API: ${taxesData.length}');

        _cachedTaxes = taxesData
            .map((taxData) {
          // Print detail setiap tax item
          print('\n📦 Processing Tax Item:');
          print('  - Raw Data: $taxData');
          print('  - ID: ${taxData['_id'] ?? taxData['id']}');
          print('  - Name: ${taxData['name']}');
          print('  - Type: ${taxData['type']}');
          print('  - Percentage: ${taxData['percentage']}');
          print('  - Is Active: ${taxData['isActive']}');
          print('  - Applies to outlets (raw): ${taxData['appliesToOutlets']}');

          final taxItem = TaxItem.fromJson(taxData);
          print('  - Applies to outlets (parsed): ${taxItem.appliesToOutlets}');

          return taxItem;
        })
            .where((tax) {
          print('  - Filtering: ${tax.name} - Active: ${tax.isActive}');
          return tax.isActive;
        })
            .toList();

        print('\n✅ Final cached taxes: ${_cachedTaxes!.length} active items');
        _cachedTaxes!.forEach((tax) {
          print('   - ${tax.name} (${tax.percentage}%) - Outlets: ${tax.appliesToOutlets}');
        });
        print('=== END FRONTEND DATA ===\n');

        return _cachedTaxes!;
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load taxes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching taxes: $e');
      return [];
    }
  }

  void printTaxCalculationDetails({
    required double subtotal,
    required String outletId,
    required bool isReservation,
    required bool isOpenBill,
  }) {
    print('\n🧮 TAX CALCULATION DETAILS');
    print('Subtotal: $subtotal');
    print('Outlet ID: $outletId');
    print('Is Reservation: $isReservation');
    print('Is Open Bill: $isOpenBill');
    print('Available taxes: ${_cachedTaxes?.length ?? 0}');

    if (_cachedTaxes != null) {
      _cachedTaxes!.forEach((tax) {
        final appliesTo = tax.appliesToOutlets.contains(outletId);
        print('  - ${tax.name} (${tax.percentage}%) - Active: ${tax.isActive}');
        print('    Outlet list: ${tax.appliesToOutlets}');
        print('    Applies to this outlet: $appliesTo');
      });
    }
  }

  TaxCalculationResult calculateTaxes({
    required double subtotal,
    required String outletId,
    required bool isReservation,
    required bool isOpenBill,
  }) {
    // Print calculation details
    printTaxCalculationDetails(
      subtotal: subtotal,
      outletId: outletId,
      isReservation: isReservation,
      isOpenBill: isOpenBill,
    );

    if (_cachedTaxes == null || _cachedTaxes!.isEmpty) {
      print('⚠️ No taxes available for calculation');
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

    for (TaxItem tax in _cachedTaxes!) {
      final appliesToOutlet = tax.appliesToOutlets.contains(outletId);
      print('\n🔍 Checking tax: ${tax.name}');
      print('   - Applies to outlet: $appliesToOutlet');
      print('   - Outlet list: ${tax.appliesToOutlets}');

      if (!appliesToOutlet) {
        print('   ❌ Skipped - does not apply to this outlet');
        continue;
      }

      if (tax.name == 'PPN') {
        ppnAmount = subtotal * (tax.percentage / 100);
        print('   ✅ Applied PPN: $ppnAmount (${tax.percentage}% of $subtotal)');
        taxDetails.add({
          'id': tax.id,
          'name': tax.name,
          'type': tax.type,
          'percentage': tax.percentage,
          'amount': ppnAmount,
        });
      } else if (tax.name == 'PB1' && isReservation) {
        pb1Amount = subtotal * (tax.percentage / 100);
        print('   ✅ Applied PB1: $pb1Amount (${tax.percentage}% of $subtotal)');
        taxDetails.add({
          'id': tax.id,
          'name': tax.name,
          'type': tax.type,
          'percentage': tax.percentage,
          'amount': pb1Amount,
        });
      } else {
        print('   ❌ Not applied - Name: ${tax.name}, Is Reservation: $isReservation');
      }
    }

    final result = TaxCalculationResult(
      ppnAmount: ppnAmount,
      pb1Amount: pb1Amount,
      totalTaxAmount: ppnAmount + pb1Amount,
      taxDetails: taxDetails,
    );

    print('\n📊 FINAL TAX CALCULATION RESULT:');
    print('   PPN Amount: $ppnAmount');
    print('   PB1 Amount: $pb1Amount');
    print('   Total Tax: ${result.totalTaxAmount}');
    print('   Tax Details: ${result.taxDetails}');

    return result;
  }

  void clearCache() {
    print('🗑️ Clearing tax cache');
    _cachedTaxes = null;
  }
}