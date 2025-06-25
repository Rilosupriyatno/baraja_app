import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/reservation_data.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isReservation = false;
  ReservationData? _reservationData;
  bool _isDineIn = false;
  String? _tableNumber;

  List<CartItem> get items => _items;
  bool get isReservation => _isReservation;
  ReservationData? get reservationData => _reservationData;
  bool get isDineIn => _isDineIn;
  String? get tableNumber => _tableNumber;

  // Method untuk set reservation data (sudah ada, pastikan seperti ini)
  void setReservationData(bool isReservation, ReservationData? data) {
    _isReservation = isReservation;
    _reservationData = data;
    _isDineIn = false;
    _tableNumber = null;
    notifyListeners();
  }

  // Method untuk set dine-in data
  void setDineInData(bool isDineIn, String? tableNumber) {
    _isDineIn = isDineIn;
    _tableNumber = tableNumber;
    _isReservation = false;
    _reservationData = null;
    notifyListeners();
  }

  // Method untuk clear semua context
  void clearOrderContext() {
    _isReservation = false;
    _reservationData = null;
    _isDineIn = false;
    _tableNumber = null;
    notifyListeners();
  }

  // Method untuk clear cart sekaligus context
  void clearCart() {
    _items.clear();
    clearOrderContext();
    notifyListeners();
  }

  void addToCart(CartItem item) {
    // Check if the item already exists in the cart with the same properties
    int index = _items.indexWhere((cartItem) =>
    cartItem.name == item.name &&
        _listsEqual(cartItem.addons, item.addons) &&
        _listsEqual(cartItem.toppings, item.toppings));

    if (index != -1) {
      // If it exists, increase the quantity
      _items[index].quantity += item.quantity;
    } else {
      // If it doesn't exist, add as a new item
      _items.add(item);
    }

    notifyListeners(); // Update UI
  }

  // Helper method to compare lists of maps
  bool _listsEqual(dynamic list1, dynamic list2) {
    // Handle different types of lists and strings
    if (list1 is String && list2 is String) {
      return list1 == list2;
    } else if (list1 is List && list2 is List) {
      if (list1.length != list2.length) return false;

      // For simple lists
      if (list1.isEmpty) return list2.isEmpty;

      // For lists of maps
      if (list1.first is Map && list2.first is Map) {
        for (int i = 0; i < list1.length; i++) {
          final map1 = list1[i] as Map;
          final map2 = list2[i] as Map;

          // Compare keys and values
          if (map1.length != map2.length) return false;
          for (final key in map1.keys) {
            if (!map2.containsKey(key) || map1[key] != map2[key]) {
              return false;
            }
          }
        }
        return true;
      }

      // Simple list comparison
      for (int i = 0; i < list1.length; i++) {
        if (list1[i] != list2[i]) return false;
      }
      return true;
    }
    return false;
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
        // If quantity = 1, remove the item
        removeFromCart(index);
      }
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // Clear everything including reservation data
  void clearAll() {
    _items.clear();
    _isReservation = false;
    _reservationData = null;
    notifyListeners();
  }

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice {
    return _items.fold(0, (sum, item) {
      // Calculate each item's total price correctly
      return sum + (item.price * item.quantity);
    });
  }
}