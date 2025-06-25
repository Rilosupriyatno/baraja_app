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

  const CheckoutButton({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (cartProvider.items.isEmpty) {
          return const SizedBox.shrink(); // Tidak menampilkan tombol jika keranjang kosong
        }
        final bool isReservation = cartProvider.isReservation;
        final ReservationData? reservationData = cartProvider.reservationData;
        final bool isDineIn = cartProvider.isDineIn;
        final String? tableNumber = cartProvider.tableNumber;
        return FloatingActionButton.extended(
          onPressed: () {
            // Prepare extra data for navigation
            Map<String, dynamic> extraData = {};

            if (isReservation && reservationData != null) {
              extraData = {
                'isReservation': true,
                'reservationData': reservationData,
              };
            } else if (isDineIn && tableNumber != null) {
              extraData = {
                'isDineIn': true,
                'tableNumber': tableNumber,
              };
            }

            // Navigate to cart with appropriate data
            if (extraData.isNotEmpty) {
              context.push('/cart', extra: extraData);
            } else {
              context.push('/cart');
            }
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
              const SizedBox(width: 8), // Jarak antara ikon dan teks
              Text(
                _getButtonText(),
                style: const TextStyle(
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

  // Method untuk menentukan teks tombol berdasarkan context
  String _getButtonText() {
    if (isReservation) {
      return 'Lanjut Reservasi';
    } else if (isDineIn) {
      return 'Pesan Sekarang';
    } else {
      return 'Lanjut Bayar';
    }
  }
}