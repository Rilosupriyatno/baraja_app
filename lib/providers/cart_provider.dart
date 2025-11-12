// import 'package:flutter/material.dart';
// import '../models/cart_item.dart';
// import '../models/reservation_data.dart';
//
// class CartProvider with ChangeNotifier {
//   final List<CartItem> _items = [];
//   bool _isReservation = false;
//   ReservationData? _reservationData;
//   bool _isDineIn = false;
//   String? _tableNumber;
//   bool _isOpenBill = false;
//   OpenBillData? _openBillData;
//
//   String? _guestName;
//   String? _guestPhone;
//   String? _guestNotes;
//
//   String? get guestName => _guestName;
//   String? get guestPhone => _guestPhone;
//   String? get guestNotes => _guestNotes;
//
//
//   List<CartItem> get items => _items;
//   bool get isReservation => _isReservation;
//   ReservationData? get reservationData => _reservationData;
//   bool get isOpenBill => _isOpenBill;
//   OpenBillData? get openBillData => _openBillData;
//   bool get isDineIn => _isDineIn;
//   String? get tableNumber => _tableNumber;
//
//
//   void setGuestData({
//     required String guestName,
//     required String guestPhone,
//     String? notes,
//   }) {
//     _guestName = guestName;
//     _guestPhone = guestPhone;
//     _guestNotes = notes;
//     notifyListeners();
//   }
//
//   void clearGuestData() {
//     _guestName = null;
//     _guestPhone = null;
//     _guestNotes = null;
//     notifyListeners();
//   }
//   // Method untuk set reservation data (sudah ada, pastikan seperti ini)
//   void setReservationData(bool isReservation, ReservationData? data) {
//     _isReservation = isReservation;
//     _reservationData = data;
//     _isDineIn = false;
//     _tableNumber = null;
//     _isOpenBill = false;
//     _openBillData = null;
//     notifyListeners();
//   }
//
//   void setOpenBillData(bool isOpenBill, OpenBillData? data) {
//     _isOpenBill = isOpenBill;
//     _openBillData = data;
//     _isReservation = false;
//     _reservationData = null;
//     _isDineIn = false;
//     _tableNumber = null;
//     notifyListeners();
//   }
//
//
//   // Method untuk set dine-in data
//   void setDineInData(bool isDineIn, String? tableNumber) {
//     _isDineIn = isDineIn;
//     _tableNumber = tableNumber;
//     _isReservation = false;
//     _reservationData = null;
//     _isOpenBill = false;
//     _openBillData = null;
//     notifyListeners();
//   }
//
//   // Method untuk clear semua context
//   void clearOrderContext() {
//     _isReservation = false;
//     _reservationData = null;
//     _isDineIn = false;
//     _tableNumber = null;
//     _isOpenBill = false;
//     _openBillData = null;
//     notifyListeners();
//   }
//
//   // Method untuk clear cart sekaligus context
//   void clearCart() {
//     _items.clear();
//     _isReservation = false;
//     _reservationData = null;
//     _isDineIn = false;
//     _tableNumber = null;
//     _isOpenBill = false;
//     _openBillData = null;
//
//     // Clear guest data
//     clearGuestData();
//
//     notifyListeners();
//     clearOrderContext();
//     notifyListeners();
//   }
//
//   void addToCart(CartItem item) {
//     // Check if the item already exists in the cart with the same properties
//     int index = _items.indexWhere((cartItem) =>
//     cartItem.name == item.name &&
//         _listsEqual(cartItem.addons, item.addons) &&
//         _listsEqual(cartItem.toppings, item.toppings));
//
//     if (index != -1) {
//       // If it exists, increase the quantity
//       _items[index].quantity += item.quantity;
//     } else {
//       // If it doesn't exist, add as a new item
//       _items.add(item);
//     }
//
//     notifyListeners(); // Update UI
//   }
//
//   // Helper method to compare lists of maps
//   bool _listsEqual(dynamic list1, dynamic list2) {
//     // Handle different types of lists and strings
//     if (list1 is String && list2 is String) {
//       return list1 == list2;
//     } else if (list1 is List && list2 is List) {
//       if (list1.length != list2.length) return false;
//
//       // For simple lists
//       if (list1.isEmpty) return list2.isEmpty;
//
//       // For lists of maps
//       if (list1.first is Map && list2.first is Map) {
//         for (int i = 0; i < list1.length; i++) {
//           final map1 = list1[i] as Map;
//           final map2 = list2[i] as Map;
//
//           // Compare keys and values
//           if (map1.length != map2.length) return false;
//           for (final key in map1.keys) {
//             if (!map2.containsKey(key) || map1[key] != map2[key]) {
//               return false;
//             }
//           }
//         }
//         return true;
//       }
//
//       // Simple list comparison
//       for (int i = 0; i < list1.length; i++) {
//         if (list1[i] != list2[i]) return false;
//       }
//       return true;
//     }
//     return false;
//   }
//
//   void increaseQuantity(int index) {
//     if (index >= 0 && index < _items.length) {
//       _items[index].quantity++;
//       notifyListeners();
//     }
//   }
//
//   void decreaseQuantity(int index) {
//     if (index >= 0 && index < _items.length) {
//       if (_items[index].quantity > 1) {
//         _items[index].quantity--;
//         notifyListeners();
//       } else {
//         // If quantity = 1, remove the item
//         removeFromCart(index);
//       }
//     }
//   }
//
//   void removeFromCart(int index) {
//     if (index >= 0 && index < _items.length) {
//       _items.removeAt(index);
//       notifyListeners();
//     }
//   }
//
//   // Clear everything including reservation data
//   void clearAll() {
//     _items.clear();
//     _isReservation = false;
//     _reservationData = null;
//     notifyListeners();
//   }
//
//   int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
//
//   // Fixed total price calculation
//   int get totalPrice {
//     // Jika reservasi tanpa item → fallback harga default
//     if (_isReservation && _items.isEmpty) {
//       return 25000;
//     }
//
//     // Hitung total semua item di cart
//     return _items.fold(0, (sum, item) {
//       int itemPrice = item.price;
//
//       // Add toppings price
//       if (item.toppings != null && item.toppings is List) {
//         for (var topping in item.toppings as List) {
//           if (topping is Map && topping.containsKey('price')) {
//             itemPrice += (topping['price'] as num).toInt();
//           }
//         }
//       }
//
//       // Add addons price
//       for (var addon in item.addons as List) {
//         if (addon is Map && addon.containsKey('price')) {
//           itemPrice += (addon['price'] as num).toInt();
//         }
//       }
//
//       return sum + (itemPrice * item.quantity);
//     });
//   }
//
//
//   // Helper method to get individual item total price (including addons and toppings)
//   int getItemTotalPrice(CartItem item) {
//     int itemPrice = item.price;
//
//     // Add toppings price
//     if (item.toppings != null && item.toppings is List) {
//       for (var topping in item.toppings as List) {
//         if (topping is Map && topping.containsKey('price')) {
//           itemPrice += (topping['price'] as num).toInt();
//         }
//       }
//     }
//
//     // Add addons price
//     for (var addon in item.addons as List) {
//       if (addon is Map && addon.containsKey('price')) {
//         itemPrice += (addon['price'] as num).toInt();
//       }
//     }
//
//     return itemPrice * item.quantity;
//   }
// }

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
  bool _isGroMode = false; // ⭐ TAMBAHKAN FLAG GRO MODE

  String? _guestName;
  String? _guestPhone;
  String? _guestNotes;

  String? get guestName => _guestName;
  String? get guestPhone => _guestPhone;
  String? get guestNotes => _guestNotes;
  bool get isGroMode => _isGroMode; // ⭐ GETTER GRO MODE

  List<CartItem> get items => _items;
  bool get isReservation => _isReservation;
  ReservationData? get reservationData => _reservationData;
  bool get isOpenBill => _isOpenBill;
  OpenBillData? get openBillData => _openBillData;
  bool get isDineIn => _isDineIn;
  String? get tableNumber => _tableNumber;

  // ⭐ METHOD BARU: Set GRO Mode
  void setGroMode(bool isGroMode) {
    _isGroMode = isGroMode;
    notifyListeners();
  }

  // ⭐ METHOD BARU: Clear semua context termasuk GRO mode
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

  // Method untuk set reservation data - TAMBAHKAN VALIDASI GRO MODE
  void setReservationData(bool isReservation, ReservationData? data) {
    // ⭐ VALIDASI: Jika mode GRO, pastikan hanya GRO yang bisa set
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
    // ⭐ VALIDASI: Hanya GRO yang bisa set open bill
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

  // Method untuk set dine-in data - TAMBAHKAN VALIDASI
  void setDineInData(bool isDineIn, String? tableNumber) {
    // ⭐ VALIDASI: Jika mode GRO, jangan set dine-in
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

  // Method untuk clear semua context
  void clearOrderContext() {
    _isReservation = false;
    _reservationData = null;
    _isDineIn = false;
    _tableNumber = null;
    _isOpenBill = false;
    _openBillData = null;
    notifyListeners();
  }

  // Method untuk clear cart sekaligus context
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
    _isGroMode = false; // ⭐ CLEAR GRO MODE JUGA
    notifyListeners();
  }

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  // Fixed total price calculation
  int get totalPrice {
    // Jika reservasi tanpa item → fallback harga default
    if (_isReservation && _items.isEmpty) {
      return 25000;
    }

    // Hitung total semua item di cart
    return _items.fold(0, (sum, item) {
      int itemPrice = item.price;

      // Add toppings price
      if (item.toppings != null && item.toppings is List) {
        for (var topping in item.toppings as List) {
          if (topping is Map && topping.containsKey('price')) {
            itemPrice += (topping['price'] as num).toInt();
          }
        }
      }

      // Add addons price
      for (var addon in item.addons as List) {
        if (addon is Map && addon.containsKey('price')) {
          itemPrice += (addon['price'] as num).toInt();
        }
      }

      return sum + (itemPrice * item.quantity);
    });
  }

  // Helper method to get individual item total price (including addons and toppings)
  int getItemTotalPrice(CartItem item) {
    int itemPrice = item.price;

    // Add toppings price
    if (item.toppings != null && item.toppings is List) {
      for (var topping in item.toppings as List) {
        if (topping is Map && topping.containsKey('price')) {
          itemPrice += (topping['price'] as num).toInt();
        }
      }
    }

    // Add addons price
    for (var addon in item.addons as List) {
      if (addon is Map && addon.containsKey('price')) {
        itemPrice += (addon['price'] as num).toInt();
      }
    }

    return itemPrice * item.quantity;
  }
}