import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/reservation_data.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isReservation = false;
  ReservationData? _reservationData;
  bool _isDineIn = false;
  String? _tableNumber;
  bool _isOpenBill = false;
  OpenBillData? _openBillData;
  bool _isGroMode = false;

  String? _guestName;
  String? _guestPhone;
  String? _guestNotes;

  String? get guestName => _guestName;
  String? get guestPhone => _guestPhone;
  String? get guestNotes => _guestNotes;
  bool get isGroMode => _isGroMode;

  List<CartItem> get items => _items;
  bool get isReservation => _isReservation;
  ReservationData? get reservationData => _reservationData;
  bool get isOpenBill => _isOpenBill;
  OpenBillData? get openBillData => _openBillData;
  bool get isDineIn => _isDineIn;
  String? get tableNumber => _tableNumber;

  void setGroMode(bool isGroMode) {
    _isGroMode = isGroMode;
    notifyListeners();
  }

  void clearContext() {
    _isReservation = false;
    _reservationData = null;
    _isDineIn = false;
    _tableNumber = null;
    _isOpenBill = false;
    _openBillData = null;
    _isGroMode = false;
    notifyListeners();
  }

  void setGuestData({
    required String guestName,
    required String guestPhone,
    String? notes,
  }) {
    _guestName = guestName;
    _guestPhone = guestPhone;
    _guestNotes = notes;
    notifyListeners();
  }

  void clearGuestData() {
    _guestName = null;
    _guestPhone = null;
    _guestNotes = null;
    notifyListeners();
  }

  void setReservationData(bool isReservation, ReservationData? data) {
    if (_isGroMode && !isReservation) {
      debugPrint('⚠️ GRO Mode: Hanya bisa set reservation context');
      return;
    }

    _isReservation = isReservation;
    _reservationData = data;
    _isDineIn = false;
    _tableNumber = null;
    _isOpenBill = false;
    _openBillData = null;
    notifyListeners();
  }

  void setOpenBillData(bool isOpenBill, OpenBillData? data) {
    if (!_isGroMode && isOpenBill) {
      debugPrint('⚠️ Open Bill hanya tersedia untuk GRO Mode');
      return;
    }

    _isOpenBill = isOpenBill;
    _openBillData = data;
    _isReservation = false;
    _reservationData = null;
    _isDineIn = false;
    _tableNumber = null;
    notifyListeners();
  }

  void setDineInData(bool isDineIn, String? tableNumber) {
    if (_isGroMode && isDineIn) {
      debugPrint('⚠️ GRO Mode: Tidak bisa set dine-in context');
      return;
    }

    _isDineIn = isDineIn;
    _tableNumber = tableNumber;
    _isReservation = false;
    _reservationData = null;
    _isOpenBill = false;
    _openBillData = null;
    notifyListeners();
  }

  void clearOrderContext() {
    _isReservation = false;
    _reservationData = null;
    _isDineIn = false;
    _tableNumber = null;
    _isOpenBill = false;
    _openBillData = null;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    clearOrderContext();
    clearGuestData();
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

    notifyListeners();
  }

  // ✅ TAMBAH: Method untuk update cart item
  void updateCartItem(int index, CartItem updatedItem) {
    if (index >= 0 && index < _items.length) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  // Helper method to compare lists of maps
  bool _listsEqual(dynamic list1, dynamic list2) {
    if (list1 is String && list2 is String) {
      return list1 == list2;
    } else if (list1 is List && list2 is List) {
      if (list1.length != list2.length) return false;

      if (list1.isEmpty) return list2.isEmpty;

      if (list1.first is Map && list2.first is Map) {
        for (int i = 0; i < list1.length; i++) {
          final map1 = list1[i] as Map;
          final map2 = list2[i] as Map;

          if (map1.length != map2.length) return false;
          for (final key in map1.keys) {
            if (!map2.containsKey(key) || map1[key] != map2[key]) {
              return false;
            }
          }
        }
        return true;
      }

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

  void clearAll() {
    _items.clear();
    _isReservation = false;
    _reservationData = null;
    _isGroMode = false;
    notifyListeners();
  }

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice {
    if (_isReservation && _items.isEmpty) {
      return 25000;
    }

    return _items.fold(0, (sum, item) {
      int itemPrice = item.price;

      if (item.toppings != null && item.toppings is List) {
        for (var topping in item.toppings as List) {
          if (topping is Map && topping.containsKey('price')) {
            itemPrice += (topping['price'] as num).toInt();
          }
        }
      }

      for (var addon in item.addons as List) {
        if (addon is Map && addon.containsKey('price')) {
          itemPrice += (addon['price'] as num).toInt();
        }
      }

      return sum + (itemPrice * item.quantity);
    });
  }

  int getItemTotalPrice(CartItem item) {
    int itemPrice = item.price;

    if (item.toppings != null && item.toppings is List) {
      for (var topping in item.toppings as List) {
        if (topping is Map && topping.containsKey('price')) {
          itemPrice += (topping['price'] as num).toInt();
        }
      }
    }

    for (var addon in item.addons as List) {
      if (addon is Map && addon.containsKey('price')) {
        itemPrice += (addon['price'] as num).toInt();
      }
    }

    return itemPrice * item.quantity;
  }
}