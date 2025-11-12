import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/reservation_data.dart';

class CheckoutButton extends StatelessWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;
  final bool isOpenBill;
  final OpenBillData? openBillData;
  final bool isGroMode;

  const CheckoutButton({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
    this.isOpenBill = false,
    this.openBillData,
    this.isGroMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () {
            _navigateToCart(context, cartProvider);
          },
          backgroundColor: const Color(0xFF076A3B),
          label: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    size: 30,
                    color: Colors.white,
                  ),
                  if (cartProvider.totalItems > 0)
                    Positioned(
                      right: -2,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartProvider.totalItems.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // ⭐ PERBAIKAN: Selalu "Lihat Keranjang"
              const Text(
                'Lihat Keranjang',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCart(BuildContext context, CartProvider cartProvider) {
    Map<String, dynamic> extraData = {
      'isGroMode': isGroMode,
    };

    // Tambahkan data context
    if (isReservation && reservationData != null) {
      extraData['isReservation'] = true;
      extraData['reservationData'] = reservationData;
    } else if (isDineIn && tableNumber != null) {
      extraData['isDineIn'] = true;
      extraData['tableNumber'] = tableNumber;
    } else if (isOpenBill && openBillData != null) {
      extraData['isOpenBill'] = true;
      extraData['openBillData'] = openBillData;
    }

    context.push('/cart', extra: extraData);
  }
}