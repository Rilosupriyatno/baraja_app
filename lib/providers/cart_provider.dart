import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/reservation_data.dart';
import '../services/calculation_service.dart';


class CartProvider with ChangeNotifier {
  // 🔒 USER ISOLATION: Track current user to prevent data leakage
  String? _currentUserId;
  String? _currentUserRole; // 'customer' or 'gro'

  // 🔒 SEPARATE CARTS dengan User ID sebagai key
  final Map<String, List<CartItem>> _userCarts = {};

  // Context data - juga per user
  final Map<String, bool> _userIsReservation = {};
  final Map<String, ReservationData?> _userReservationData = {};
  final Map<String, bool> _userIsDineIn = {};
  final Map<String, String?> _userTableNumber = {};
  final Map<String, bool> _userIsOpenBill = {};
  final Map<String, OpenBillData?> _userOpenBillData = {};
  final Map<String, bool> _userIsGroMode = {};

  // Guest data - per user
  final Map<String, String?> _userGuestName = {};
  final Map<String, String?> _userGuestPhone = {};
  final Map<String, String?> _userGuestNotes = {};

  // 🔒 CRITICAL: Method untuk set user saat login
  void setCurrentUser(String userId, String userRole) {
    if (_currentUserId != userId || _currentUserRole != userRole) {
      debugPrint('🔐 User Context Changed:');
      debugPrint('   Previous: $_currentUserId ($_currentUserRole)');
      debugPrint('   New: $userId ($userRole)');

      _currentUserId = userId;
      _currentUserRole = userRole;

      // Initialize cart untuk user baru jika belum ada
      _userCarts.putIfAbsent(userId, () => []);

      notifyListeners();
    }
  }

  // 🔒 CRITICAL: Method untuk clear user saat logout
  void clearCurrentUser() {
    debugPrint('🔓 User Logged Out: $_currentUserId');
    _currentUserId = null;
    _currentUserRole = null;
    notifyListeners();
  }

  // 🔒 Helper untuk mendapatkan user key yang unik
  String get _userKey {
    if (_currentUserId == null) {
      throw StateError('❌ CRITICAL: No user logged in! Call setCurrentUser() first.');
    }
    return _currentUserId!;
  }

  // 🔒 GETTER: Kembalikan cart sesuai user yang login
  List<CartItem> get items {
    if (_currentUserId == null) {
      debugPrint('⚠️ WARNING: Accessing cart without user login');
      return [];
    }
    return _userCarts[_userKey] ?? [];
  }

  // Getters dengan user isolation
  bool get isReservation => _userIsReservation[_userKey] ?? false;
  ReservationData? get reservationData => _userReservationData[_userKey];
  bool get isOpenBill => _userIsOpenBill[_userKey] ?? false;
  OpenBillData? get openBillData => _userOpenBillData[_userKey];
  bool get isDineIn => _userIsDineIn[_userKey] ?? false;
  String? get tableNumber => _userTableNumber[_userKey];
  bool get isGroMode => _userIsGroMode[_userKey] ?? (_currentUserRole == 'gro');

  String? get guestName => _userGuestName[_userKey];
  String? get guestPhone => _userGuestPhone[_userKey];
  String? get guestNotes => _userGuestNotes[_userKey];

  void setGroMode(bool isGroMode) {
    _userIsGroMode[_userKey] = isGroMode;
    debugPrint('🔄 Cart Mode Changed for user $_userKey: ${isGroMode ? "GRO" : "Customer"}');
    debugPrint('   Cart Items: ${items.length}');
    notifyListeners();
  }

  void clearContext() {
    _userIsReservation[_userKey] = false;
    _userReservationData[_userKey] = null;
    _userIsDineIn[_userKey] = false;
    _userTableNumber[_userKey] = null;
    _userIsOpenBill[_userKey] = false;
    _userOpenBillData[_userKey] = null;
    notifyListeners();
  }

  void setGuestData({
    required String guestName,
    required String guestPhone,
    String? notes,
  }) {
    _userGuestName[_userKey] = guestName;
    _userGuestPhone[_userKey] = guestPhone;
    _userGuestNotes[_userKey] = notes;
    notifyListeners();
  }

  void clearGuestData() {
    _userGuestName.remove(_userKey);
    _userGuestPhone.remove(_userKey);
    _userGuestNotes.remove(_userKey);
    notifyListeners();
  }

  void setReservationData(bool isReservation, ReservationData? data) {
    _userIsReservation[_userKey] = isReservation;
    _userReservationData[_userKey] = data;

    // Clear other contexts
    _userIsDineIn[_userKey] = false;
    _userTableNumber.remove(_userKey);
    _userIsOpenBill[_userKey] = false;
    _userOpenBillData.remove(_userKey);

    debugPrint('✅ Reservation data set for user $_userKey');
    notifyListeners();
  }

  void setOpenBillData(bool isOpenBill, OpenBillData? data) {
    _userIsOpenBill[_userKey] = isOpenBill;
    _userOpenBillData[_userKey] = data;

    // Clear other contexts
    _userIsReservation[_userKey] = false;
    _userReservationData.remove(_userKey);
    _userIsDineIn[_userKey] = false;
    _userTableNumber.remove(_userKey);

    debugPrint('✅ Open Bill data set for user $_userKey');
    notifyListeners();
  }

  // ✅ FIXED: Hapus validasi yang memblokir GRO mode untuk dine-in
  void setDineInData(bool isDineIn, String? tableNumber) {
    _userIsDineIn[_userKey] = isDineIn;
    _userTableNumber[_userKey] = tableNumber;

    // Clear other contexts
    _userIsReservation[_userKey] = false;
    _userReservationData.remove(_userKey);
    _userIsOpenBill[_userKey] = false;
    _userOpenBillData.remove(_userKey);

    debugPrint('✅ Dine-In data set for user $_userKey');
    debugPrint('   Table Number: $tableNumber');
    debugPrint('   Is GRO Mode: ${isGroMode}');
    notifyListeners();
  }

  void clearOrderContext() {
    _userIsReservation[_userKey] = false;
    _userReservationData.remove(_userKey);
    _userIsDineIn[_userKey] = false;
    _userTableNumber.remove(_userKey);
    _userIsOpenBill[_userKey] = false;
    _userOpenBillData.remove(_userKey);
    notifyListeners();
  }

  void clearCart() {
    _userCarts[_userKey]?.clear();
    debugPrint('🗑️ Cart cleared for user: $_userKey');
    clearOrderContext();
    clearGuestData();
    notifyListeners();
  }

  void addToCart(CartItem item) {
    final targetCart = _userCarts[_userKey] ?? [];

    int index = targetCart.indexWhere((cartItem) =>
    cartItem.name == item.name &&
        _listsEqual(cartItem.addons, item.addons) &&
        _listsEqual(cartItem.toppings, item.toppings));

    if (index != -1) {
      targetCart[index].quantity += item.quantity;
    } else {
      targetCart.add(item);
    }

    _userCarts[_userKey] = targetCart;

    debugPrint('🛒 Item added to cart for user $_userKey: ${item.name}');
    debugPrint('   Total items: ${targetCart.length}');
    notifyListeners();
  }

  void updateCartItem(int index, CartItem updatedItem) {
    final targetCart = _userCarts[_userKey] ?? [];
    if (index >= 0 && index < targetCart.length) {
      targetCart[index] = updatedItem;
      notifyListeners();
    }
  }

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
    final targetCart = _userCarts[_userKey] ?? [];
    if (index >= 0 && index < targetCart.length) {
      targetCart[index].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(int index) {
    final targetCart = _userCarts[_userKey] ?? [];
    if (index >= 0 && index < targetCart.length) {
      if (targetCart[index].quantity > 1) {
        targetCart[index].quantity--;
        notifyListeners();
      } else {
        removeFromCart(index);
      }
    }
  }

  void removeFromCart(int index) {
    final targetCart = _userCarts[_userKey] ?? [];
    if (index >= 0 && index < targetCart.length) {
      targetCart.removeAt(index);
      notifyListeners();
    }
  }

  // 🔒 Method untuk admin - clear semua data (gunakan dengan hati-hati!)
  void clearAllUsers() {
    _userCarts.clear();
    _userIsReservation.clear();
    _userReservationData.clear();
    _userIsDineIn.clear();
    _userTableNumber.clear();
    _userIsOpenBill.clear();
    _userOpenBillData.clear();
    _userIsGroMode.clear();
    _userGuestName.clear();
    _userGuestPhone.clear();
    _userGuestNotes.clear();
    debugPrint('🗑️ All user data cleared (ADMIN ACTION)');
    notifyListeners();
  }

  int get totalItems {
    final targetCart = _userCarts[_userKey] ?? [];
    return targetCart.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalPrice {
    final targetCart = _userCarts[_userKey] ?? [];

    return CalculationService.calculateCartTotal(
      items: targetCart,
      isReservation: isReservation,
    );
  }

  int getItemTotalPrice(CartItem item) {
    return CalculationService.calculateCartItemTotal(item);
  }


  // 🔒 Debug method - jangan gunakan di production
  void debugPrintAllCarts() {
    debugPrint('=== DEBUG: All User Carts ===');
    debugPrint('Current User: $_currentUserId ($_currentUserRole)');
    for (var entry in _userCarts.entries) {
      debugPrint('User ${entry.key}: ${entry.value.length} items');
    }
    debugPrint('============================');
  }
}