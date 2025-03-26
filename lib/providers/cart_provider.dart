import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    // Cek apakah item sudah ada di keranjang
    int index = _items.indexWhere((cartItem) =>
    cartItem.name == item.name &&
        cartItem.additional == item.additional &&
        cartItem.topping == item.topping);

    if (index != -1) {
      // Jika sudah ada, tambahkan jumlahnya
      _items[index].quantity += item.quantity;
    } else {
      // Jika belum, tambahkan sebagai item baru
      _items.add(item);
    }

    notifyListeners(); // Perbarui UI
  }
  void increaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }


  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}
