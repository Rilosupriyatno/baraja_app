class CartItem {
  final String id; // Added id field
  final String name;
  final String imageUrl;
  final int price;
  int quantity;
  final List<Map<String, dynamic>> addons;
  final dynamic toppings; // Can be String, List<String>, or List<Map>

  // Private field to store the total price
  final int _totalprice;

  CartItem({
    required this.id, // Required id parameter
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.addons,
    required this.toppings,
    int? totalprice, String? notes, // Optional parameter - if provided, use it directly
  }) : _totalprice = totalprice ?? calculateTotalPrice(price, addons, toppings);

  // Getter for total price
  int get totalprice => _totalprice;

  // Static method to calculate total price
  static int calculateTotalPrice(int basePrice, List<Map<String, dynamic>> addons, dynamic toppings) {
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
}