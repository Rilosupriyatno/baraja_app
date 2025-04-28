import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(CartItem item) {
    // Cek apakah item sudah ada di keranjang
    int index = _items.indexWhere((cartItem) =>
    cartItem.name == item.name &&
        cartItem.addons == item.addons &&
        cartItem.toppings == item.toppings);

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

  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        // Jika quantity = 1, hapus item
        removeFromCart(index);
      }
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

  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}