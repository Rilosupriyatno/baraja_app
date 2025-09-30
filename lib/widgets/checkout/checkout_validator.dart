import 'package:flutter/material.dart';
import '../../models/order_type.dart';
import '../../providers/cart_provider.dart';
import '../../screens/checkout_page.dart';
import '../../services/table_Service.dart';

class CheckoutValidator {
  static Future<Map<String, dynamic>> validateForm({
    required CartProvider cartProvider,
    required OrderType selectedOrderType,
    required String deliveryAddress,
    required TimeOfDay? pickupTime,
    required String tableNumber,
    required String? selectedPaymentMethod,
    required String? selectedPaymentMethodName,
    required ReservationType selectedReservationType,
    required int Function(int) calculateDiscount,
    required bool Function(String?) shouldShowReservationType,
    required bool Function(String?, int) canSelectBlocking,
    required int Function(String?) getMinimumAmountForBlocking,
    required String Function(int) formatCurrency,
    required bool Function(TimeOfDay) isValidPickupTime,
    required TimeOfDay Function() getMinimumPickupTime,
    required String Function(TimeOfDay) formatTime,
    required TableService tableService,
  }) async {
    Map<String, String> errors = {};
    String? firstErrorKey;

    // Validasi keranjang kosong
    if (cartProvider.items.isEmpty && !cartProvider.isReservation) {
      return {
        'isValid': false,
        'errors': {'general': 'Keranjang belanja masih kosong'},
        'firstErrorKey': 'general',
      };
    }

    // Skip validasi untuk open bill
    if (cartProvider.isOpenBill) {
      return {
        'isValid': true,
        'errors': {},
        'firstErrorKey': null,
      };
    }

    // Skip validation untuk reservasi & dine-in
    if (!cartProvider.isReservation && !cartProvider.isDineIn) {
      switch (selectedOrderType) {
        case OrderType.delivery:
          if (deliveryAddress.trim().isEmpty) {
            errors['deliveryAddress'] = 'Alamat pengantaran harus diisi';
            firstErrorKey ??= 'deliveryAddress';
          } else if (deliveryAddress.trim().length < 10) {
            errors['deliveryAddress'] =
            'Alamat pengantaran terlalu singkat (minimal 10 karakter)';
            firstErrorKey ??= 'deliveryAddress';
          }
          break;

        case OrderType.pickup:
          if (pickupTime == null) {
            errors['pickupTime'] = 'Waktu pengambilan harus dipilih';
            firstErrorKey ??= 'pickupTime';
          } else if (!isValidPickupTime(pickupTime)) {
            final minimumTime = getMinimumPickupTime();
            errors['pickupTime'] =
            'Waktu pickup minimal ${formatTime(minimumTime)} (5 menit dari sekarang)';
            firstErrorKey ??= 'pickupTime';
          }
          break;

        case OrderType.dineIn:
          if (tableNumber.trim().isEmpty) {
            errors['tableNumber'] = 'Nomor meja harus diisi';
            firstErrorKey ??= 'tableNumber';
          } else {
            try {
              final result = await tableService.checkTableAvailability(tableNumber);
              if (!result['isAvailable']) {
                errors['tableNumber'] = result['message'] ?? 'Meja tidak tersedia';
              }
            } catch (e) {
              errors['tableNumber'] = 'Gagal memvalidasi ketersediaan meja';
            }
          }
          break;

        case OrderType.takeAway:
        // Take Away tidak memerlukan validasi tambahan
        // Karena tidak perlu nomor meja, alamat, atau waktu pickup
          break;

        case OrderType.reservation:
        // Tidak perlu validasi di sini karena sudah di-handle di bawah
          break;
      }
    }

    // Validasi metode pembayaran
    if (selectedPaymentMethod == null || selectedPaymentMethodName == null) {
      errors['paymentMethod'] = 'Metode pembayaran harus dipilih';
      firstErrorKey ??= 'paymentMethod';
    }

    // Validasi khusus untuk reservasi
    if (cartProvider.isReservation && cartProvider.reservationData != null) {
      final reservationData = cartProvider.reservationData!;
      if (shouldShowReservationType(reservationData.areaCode)) {
        final int finalTotal =
            cartProvider.totalPrice - calculateDiscount(cartProvider.totalPrice);

        if (selectedReservationType == ReservationType.blocking &&
            !canSelectBlocking(reservationData.areaCode, finalTotal)) {
          final minAmount =
          getMinimumAmountForBlocking(reservationData.areaCode);
          errors['reservationType'] =
          'Minimum pembelian Rp${formatCurrency(minAmount)} untuk reservasi blocking di area ${reservationData.areaCode}';
          firstErrorKey ??= 'reservationType';
        }
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'firstErrorKey': firstErrorKey,
    };
  }
}