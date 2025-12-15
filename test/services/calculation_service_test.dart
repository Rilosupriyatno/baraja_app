import 'package:flutter_test/flutter_test.dart';
import 'package:baraja_app/services/calculation_service.dart';
import 'package:baraja_app/models/cart_item.dart';
import 'package:baraja_app/models/voucher_item.dart';

void main() {
  group('CalculationService', () {
    group('calculateItemPrice', () {
      test('should calculate base price only when no addons or toppings', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [],
          toppings: [],
        );
        expect(price, 10000);
      });

      test('should add addon prices to base price', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [
            {'price': 2000},
            {'price': 3000},
          ],
          toppings: [],
        );
        expect(price, 15000); // 10000 + 2000 + 3000
      });

      test('should add topping prices to base price', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [],
          toppings: [
            {'price': 1000},
            {'price': 500},
          ],
        );
        expect(price, 11500); // 10000 + 1000 + 500
      });

      test('should add both addons and toppings to base price', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [
            {'price': 2000},
            {'price': 3000},
          ],
          toppings: [
            {'price': 1000},
            {'price': 500},
          ],
        );
        expect(price, 16500); // 10000 + 2000 + 3000 + 1000 + 500
      });

      test('should ignore addons without price', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [
            {'name': 'Extra Cheese'}, // no price
            {'price': 2000},
          ],
          toppings: [],
        );
        expect(price, 12000); // 10000 + 2000
      });

      test('should handle null topping prices', () {
        final price = CalculationService.calculateItemPrice(
          basePrice: 10000,
          addons: [],
          toppings: [
            {'name': 'Sauce', 'price': null},
            {'price': 1000},
          ],
        );
        expect(price, 11000); // 10000 + 1000
      });
    });

    group('calculateCartItemTotal', () {
      test('should calculate item total with quantity', () {
        final item = CartItem(
          id: '1',
          name: 'Test Item',
          imageUrl: '',
          price: 10000,
          quantity: 2,
          addons: [
            {'price': 2000},
          ],
          toppings: [
            {'price': 1000},
          ],
          notes: null,
        );

        final total = CalculationService.calculateCartItemTotal(item);
        expect(total, 26000); // (10000 + 2000 + 1000) * 2
      });
    });

    group('calculateCartTotal', () {
      test('should return 25000 for empty reservation cart', () {
        final total = CalculationService.calculateCartTotal(
          items: [],
          isReservation: true,
        );
        expect(total, 25000);
      });

      test('should return 0 for empty non-reservation cart', () {
        final total = CalculationService.calculateCartTotal(
          items: [],
          isReservation: false,
        );
        expect(total, 0);
      });

      test('should calculate total for multiple items', () {
        final items = [
          CartItem(
            id: '1',
            name: 'Item 1',
            imageUrl: '',
            price: 10000,
            quantity: 2,
            addons: [],
            toppings: [],
            notes: null,
          ),
          CartItem(
            id: '2',
            name: 'Item 2',
            imageUrl: '',
            price: 15000,
            quantity: 1,
            addons: [
              {'price': 5000},
            ],
            toppings: [],
            notes: null,
          ),
        ];

        final total = CalculationService.calculateCartTotal(
          items: items,
          isReservation: false,
        );
        expect(total, 40000); // (10000 * 2) + ((15000 + 5000) * 1)
      });
    });

    group('calculateDiscount', () {
      test('should return 0 when no voucher provided', () {
        final discount = CalculationService.calculateDiscount(
          subtotal: 100000,
          voucher: null,
        );
        expect(discount, 0);
      });

      test('should calculate percentage discount correctly', () {
        final voucher = Voucher(
          id: '1',
          code: 'TEST10',
          name: 'Test 10%',
          description: 'Test voucher 10%',
          discountType: 'percentage',
          discountAmount: 10,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 30)),
          isActive: true,
        );

        final discount = CalculationService.calculateDiscount(
          subtotal: 100000,
          voucher: voucher,
        );
        expect(discount, 10000); // 10% of 100000
      });

      test('should calculate fixed discount correctly', () {
        final voucher = Voucher(
          id: '2',
          code: 'SAVE5K',
          name: 'Save 5000',
          description: 'Save 5000 rupiah',
          discountType: 'fixed',
          discountAmount: 5000,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 30)),
          isActive: true,
        );

        final discount = CalculationService.calculateDiscount(
          subtotal: 100000,
          voucher: voucher,
        );
        expect(discount, 5000);
      });

      test('should round percentage discount correctly', () {
        final voucher = Voucher(
          id: '3',
          code: 'TEST15',
          name: 'Test 15%',
          description: 'Test voucher 15%',
          discountType: 'percentage',
          discountAmount: 15,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 30)),
          isActive: true,
        );

        final discount = CalculationService.calculateDiscount(
          subtotal: 33333,
          voucher: voucher,
        );
        expect(discount, 5000); // 15% of 33333 = 4999.95, rounded to 5000
      });

    });

    group('calculateGrandTotal', () {
      test('should calculate all totals correctly', () {
        final result = CalculationService.calculateGrandTotal(
          subtotal: 100000,
          discount: 10000,
          tax: 9000,
        );

        expect(result.subtotal, 100000);
        expect(result.discount, 10000);
        expect(result.finalTotal, 90000); // 100000 - 10000
        expect(result.tax, 9000);
        expect(result.grandTotal, 99000); // 90000 + 9000
      });

      test('should handle zero discount', () {
        final result = CalculationService.calculateGrandTotal(
          subtotal: 100000,
          discount: 0,
          tax: 10000,
        );

        expect(result.finalTotal, 100000);
        expect(result.grandTotal, 110000);
      });

      test('should handle zero tax', () {
        final result = CalculationService.calculateGrandTotal(
          subtotal: 100000,
          discount: 10000,
          tax: 0,
        );

        expect(result.finalTotal, 90000);
        expect(result.grandTotal, 90000);
      });
    });

    group('calculateDownPayment', () {
      test('should calculate 50% down payment', () {
        final downPayment = CalculationService.calculateDownPayment(100000);
        expect(downPayment, 50000);
      });

      test('should round down payment correctly', () {
        final downPayment = CalculationService.calculateDownPayment(99999);
        expect(downPayment, 50000); // 49999.5 rounded to 50000
      });
    });
  });
}
