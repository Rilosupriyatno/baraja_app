import '../models/cart_item.dart';
import '../models/voucher_item.dart';

/// Result model for grand total calculation
class CalculationResult {
  final int subtotal;
  final int discount;
  final int finalTotal;
  final int tax;
  final int grandTotal;

  CalculationResult({
    required this.subtotal,
    required this.discount,
    required this.finalTotal,
    required this.tax,
    required this.grandTotal,
  });

  @override
  String toString() {
    return 'CalculationResult(subtotal: $subtotal, discount: $discount, '
        'finalTotal: $finalTotal, tax: $tax, grandTotal: $grandTotal)';
  }
}

/// Centralized service for all calculation logic
/// 
/// This service provides a single source of truth for all price calculations
/// across the application, ensuring consistency between cart, checkout, and
/// order details for both customer and GRO interfaces.
class CalculationService {
  /// Calculate total price for a single item including addons and toppings
  /// 
  /// Formula: basePrice + sum(addons.price) + sum(toppings.price)
  /// 
  /// Example:
  /// ```dart
  /// final price = CalculationService.calculateItemPrice(
  ///   basePrice: 10000,
  ///   addons: [{'price': 2000}, {'price': 3000}],
  ///   toppings: [{'price': 1000}],
  /// );
  /// // Returns: 16000 (10000 + 2000 + 3000 + 1000)
  /// ```
  static int calculateItemPrice({
    required int basePrice,
    required List<Map<String, dynamic>> addons,
    required dynamic toppings,
  }) {
    int total = basePrice;

    // Add addon prices
    for (var addon in addons) {
      if (addon.containsKey('price') && addon['price'] != null) {
        total += addon['price'] as int;
      }
    }

    // Add topping prices based on the type
    if (toppings is List) {
      for (var topping in toppings) {
        if (topping is Map && topping.containsKey('price') && topping['price'] != null) {
          total += topping['price'] as int;
        }
      }
    }

    return total;
  }

  /// Calculate total price for a single cart item (price * quantity)
  /// 
  /// This calculates the item's base price + addons + toppings, then multiplies by quantity
  static int calculateCartItemTotal(CartItem item) {
    int itemPrice = item.price;

    // Add toppings
    if (item.toppings != null && item.toppings is List) {
      for (var topping in item.toppings as List) {
        if (topping is Map && topping.containsKey('price')) {
          itemPrice += (topping['price'] as num).toInt();
        }
      }
    }

    // Add addons
    for (var addon in item.addons as List) {
      if (addon is Map && addon.containsKey('price')) {
        itemPrice += (addon['price'] as num).toInt();
      }
    }

    return itemPrice * item.quantity;
  }

  /// Calculate total price for entire cart
  /// 
  /// Formula: sum(item.totalprice * item.quantity) for all items
  /// Special case: Returns 25000 for reservation without menu items
  /// 
  /// Example:
  /// ```dart
  /// final total = CalculationService.calculateCartTotal(
  ///   items: cartItems,
  ///   isReservation: false,
  /// );
  /// ```
  static int calculateCartTotal({
    required List<CartItem> items,
    bool isReservation = false,
  }) {
    // Special case: reservation without menu
    if (isReservation && items.isEmpty) {
      return 25000;
    }

    return items.fold(0, (sum, item) {
      return sum + calculateCartItemTotal(item);
    });
  }

  /// Calculate discount amount based on voucher
  /// 
  /// Supports two discount types:
  /// - percentage: discount = subtotal * (percentage / 100)
  /// - fixed: discount = fixed amount
  /// 
  /// Returns 0 if no voucher is provided
  /// 
  /// Example:
  /// ```dart
  /// final discount = CalculationService.calculateDiscount(
  ///   subtotal: 100000,
  ///   voucher: Voucher(discountType: 'percentage', discountAmount: 10),
  /// );
  /// // Returns: 10000 (10% of 100000)
  /// ```
  static int calculateDiscount({
    required int subtotal,
    required Voucher? voucher,
  }) {
    if (voucher == null) return 0;

    int discount = 0;
    if (voucher.discountType == "percentage") {
      discount = (subtotal * (voucher.discountAmount / 100)).round();
    } else if (voucher.discountType == "fixed") {
      discount = voucher.discountAmount;
    }

    return discount;
  }

  /// Calculate all totals (subtotal, discount, final total, tax, grand total)
  /// 
  /// Formula:
  /// - finalTotal = subtotal - discount
  /// - grandTotal = finalTotal + tax
  /// 
  /// Example:
  /// ```dart
  /// final result = CalculationService.calculateGrandTotal(
  ///   subtotal: 100000,
  ///   discount: 10000,
  ///   tax: 9000,
  /// );
  /// // result.finalTotal = 90000
  /// // result.grandTotal = 99000
  /// ```
  static CalculationResult calculateGrandTotal({
    required int subtotal,
    required int discount,
    required int tax,
  }) {
    final finalTotal = subtotal - discount;
    final grandTotal = finalTotal + tax;

    return CalculationResult(
      subtotal: subtotal,
      discount: discount,
      finalTotal: finalTotal,
      tax: tax,
      grandTotal: grandTotal,
    );
  }

  /// Calculate down payment amount (50% of grand total)
  /// 
  /// Used for reservation down payment calculations
  static int calculateDownPayment(int grandTotal) {
    return (grandTotal * 0.5).round();
  }
}
