import '../services/calculation_service.dart';

//   final String id;
//   final String name;
//   final String imageUrl;
//   final int price;
//   int quantity;
//   final String? notes; // Optional notes field
//   final List<Map<String, dynamic>> addons;
//   final dynamic toppings; // Can be String, List<String>, or List<Map>
//
//   // Private field to store the total price
//   final int _totalprice;
//   final String? outletId;
//   final String? outletName;
//
//   CartItem({
//     required this.id,
//     required this.name,
//     required this.imageUrl,
//     required this.price,
//     required this.quantity,
//     required this.addons,
//     required this.toppings,
//     required this.notes,
//     this.outletId,
//     this.outletName,
//     int? totalprice, // Optional parameter - if provided, use it directly
//   }) : _totalprice = totalprice ?? calculateTotalPrice(price, addons, toppings);
//
//   // Getter for total price
//   int get totalprice => _totalprice;
//
//   // Static method to calculate total price
//   static int calculateTotalPrice(int basePrice, List<Map<String, dynamic>> addons, dynamic toppings) {
//     int total = basePrice;
//
//     // Add addon prices
//     for (var addon in addons) {
//       if (addon.containsKey('price') && addon['price'] != null) {
//         total += addon['price'] as int;
//       }
//     }
//
//     // Add topping prices based on the type
//     if (toppings is List) {
//       for (var topping in toppings) {
//         if (topping is Map && topping.containsKey('price') && topping['price'] != null) {
//           total += topping['price'] as int;
//         }
//       }
//     }
//
//     return total;
//   }
// }

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  int quantity;
  final String? notes;
  final List<Map<String, dynamic>> addons;
  final dynamic toppings;
  final int _totalprice;
  final String? outletId;
  final String? outletName;

  // ✅ NEW: Field untuk identify custom amount items
  final bool isCustomAmount;
  final String? customAmountDescription;
  final String? dineType;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.addons,
    required this.toppings,
    required this.notes,
    this.outletId,
    this.outletName,
    int? totalprice,
    // ✅ NEW: Custom amount parameters
    this.isCustomAmount = false,
    this.customAmountDescription,
    this.dineType = 'Dine-In',
  }) : _totalprice = totalprice ?? CalculationService.calculateItemPrice(
    basePrice: price,
    addons: addons,
    toppings: toppings,
  );

  int get totalprice => _totalprice;


  // ✅ NEW: Helper method to create custom amount item
  factory CartItem.customAmount({
    required String name,
    required int amount,
    String? description,
    String dineType = 'Dine-In',
  }) {
    return CartItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      imageUrl: '',
      price: amount,
      quantity: 1,
      addons: [],
      toppings: [],
      notes: description ?? '',
      isCustomAmount: true,
      customAmountDescription: description,
      dineType: dineType,
      totalprice: amount,
    );
  }

  // ✅ NEW: Convert to map with custom amount support
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'addons': addons,
      'toppings': toppings,
      'notes': notes,
      'totalprice': totalprice,
      'outletId': outletId,
      'outletName': outletName,
      'isCustomAmount': isCustomAmount,
      'customAmountDescription': customAmountDescription,
      'dineType': dineType,
    };
  }

  // ✅ NEW: From map with custom amount support
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: map['price'] ?? 0,
      quantity: map['quantity'] ?? 1,
      addons: List<Map<String, dynamic>>.from(map['addons'] ?? []),
      toppings: map['toppings'],
      notes: map['notes'],
      totalprice: map['totalprice'],
      outletId: map['outletId'],
      outletName: map['outletName'],
      isCustomAmount: map['isCustomAmount'] ?? false,
      customAmountDescription: map['customAmountDescription'],
      dineType: map['dineType'] ?? 'Dine-In',
    );
  }
}