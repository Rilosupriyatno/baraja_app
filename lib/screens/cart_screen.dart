import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/reservation_data.dart';
import '../widgets/cart/cart_item_card.dart';
import '../utils/currency_formatter.dart';

class CartScreen extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;

  const CartScreen({
    super.key,
    this.isReservation = false,
    this.reservationData,
  });

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set reservation data in cart provider when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isReservation && widget.reservationData != null) {
        Provider.of<CartProvider>(context, listen: false)
            .setReservationData(widget.isReservation, widget.reservationData);
      }
    });
  }

  // Widget untuk menampilkan info reservasi
  Widget _buildReservationInfo() {
    if (!widget.isReservation || widget.reservationData == null) {
      return const SizedBox.shrink();
    }

    final data = widget.reservationData!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Detail Reservasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${data.formattedDate} • ${data.formattedTime}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            '${data.personCount} orang • Lantai ${data.floor}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    // Dynamic title based on reservation status
    String title = widget.isReservation ? 'Keranjang Reservasi' : 'Keranjang';

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.grey.shade300,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(title, style: const TextStyle(color: Colors.black)),
          ),

          // Reservation info at the top
          if (widget.isReservation && widget.reservationData != null)
            SliverToBoxAdapter(
              child: _buildReservationInfo(),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (cartItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Keranjang Anda kosong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isReservation
                          ? 'Tambahkan menu untuk reservasi Anda'
                          : 'Tambahkan menu favorit Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CartItemCard(
                        item: item,
                        onIncrease: () {
                          cartProvider.increaseQuantity(index);
                        },
                        onDecrease: () {
                          cartProvider.decreaseQuantity(index);
                        },
                      ),
                    );
                  },
                  childCount: cartItems.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 3, left: 16, right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to menu with reservation data if needed
                  if (widget.isReservation && widget.reservationData != null) {
                    context.pop(); // Just go back to the menu screen
                  } else {
                    context.push('/menu');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.primaryColor,
                ),
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                label: const Text(
                  'Tambah Pesanan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          elevation: 4,
          shadowColor: Colors.grey.shade300,
          color: Colors.white,
          clipBehavior: Clip.none,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        formatCurrency(cartProvider.totalPrice),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : () {
                    context.go('/checkout');
                    // Pass reservation data to checkout if needed
                    // if (widget.isReservation && widget.reservationData != null) {
                    //   context.go('/checkout', extra: {
                    //     'isReservation': true,
                    //     'reservationData': widget.reservationData,
                    //   });
                    // } else {
                    //   context.go('/checkout');
                    // }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Text(
                    widget.isReservation ? 'Konfirmasi Reservasi' : 'Lanjutkan Pesanan',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}