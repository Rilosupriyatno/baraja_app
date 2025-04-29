class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final int price;
  final int totalprice;
  late final int quantity;
  final List<Map<String, dynamic>> addons;
  final List<Map<String, dynamic>> toppings;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.totalprice,
    required this.quantity,
    required this.addons,
    required this.toppings,
  });
}
