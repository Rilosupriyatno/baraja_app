// Cart Item Model
class CartItem {
  final String name;
  final String imageUrl;
  final int price;
  final String additional;
  final String topping;
  int quantity;

  CartItem({
    required this.name,
    required this.imageUrl,
    required this.price,
    this.additional = '-',
    this.topping = '-',
    this.quantity = 1,
  });
}