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
  final bool isDineIn;
  final String? tableNumber;

  const CartScreen({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
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
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Set context hanya jika diberikan dari parameter
      if (widget.isReservation && widget.reservationData != null) {
        cartProvider.setReservationData(widget.isReservation, widget.reservationData);
      } else if (widget.isDineIn && widget.tableNumber != null) {
        cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
      }
      // Jika tidak ada parameter, gunakan context yang sudah tersimpan di provider
    });
  }

  // Widget untuk menampilkan info reservasi yang simple dan compact
  Widget _buildReservationInfo(ReservationData data) {
    // Helper method untuk mendapatkan nomor meja yang dipilih
    String getSelectedTables() {
      if (data.selectedTableIds.isEmpty) {
        return 'Belum dipilih';
      }
      return '${data.selectedTableIds.length} meja';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Detail Reservasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Info dalam 2 baris
          Row(
            children: [
              Expanded(
                child: Text(
                  '📅 ${data.formattedDate}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '🕐 ${data.formattedTime}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: Text(
                  '📍 Area ${data.areaCode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
              Text(
                '👥 ${data.personCount} orang',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              Text(
                '🪑 ${getSelectedTables()}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDineInInfo(String tableNumber) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Dine In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Meja No. $tableNumber',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            'Pesanan akan disajikan langsung ke meja Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Method untuk mendapatkan title yang sesuai
  String _getTitle(bool isReservation, bool isDineIn) {
    if (isReservation) {
      return 'Keranjang Reservasi';
    } else if (isDineIn) {
      return 'Keranjang Dine In';
    } else {
      return 'Keranjang';
    }
  }

  // Method untuk mendapatkan empty state message
  String _getEmptyStateMessage(bool isReservation, bool isDineIn) {
    if (isReservation) {
      return 'Tambahkan menu untuk reservasi Anda';
    } else if (isDineIn) {
      return 'Tambahkan menu untuk dine in Anda';
    } else {
      return 'Tambahkan menu favorit Anda';
    }
  }

  // Method untuk mendapatkan checkout button text
  String _getCheckoutButtonText(bool isReservation, bool isDineIn) {
    if (isReservation) {
      return 'Konfirmasi Reservasi';
    } else if (isDineIn) {
      return 'Pesan Sekarang';
    } else {
      return 'Lanjutkan Pesanan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items;

        // Gunakan context dari provider, bukan dari widget parameter
        final bool isReservation = cartProvider.isReservation;
        final ReservationData? reservationData = cartProvider.reservationData;
        final bool isDineIn = cartProvider.isDineIn;
        final String? tableNumber = cartProvider.tableNumber;

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
                title: Text(_getTitle(isReservation, isDineIn),
                    style: const TextStyle(color: Colors.black)),
              ),

              // Reservation info at the top
              if (isReservation && reservationData != null)
                SliverToBoxAdapter(
                  child: _buildReservationInfo(reservationData),
                ),

              // Dine-in info at the top
              if (isDineIn && tableNumber != null)
                SliverToBoxAdapter(
                  child: _buildDineInInfo(tableNumber),
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
                          _getEmptyStateMessage(isReservation, isDineIn),
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
                      // Navigate back to menu with appropriate context
                      if (isReservation && reservationData != null) {
                        context.pop(); // Just go back to the menu screen
                      } else if (isDineIn && tableNumber != null) {
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
                        // Pass all relevant data to checkout
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

                        if (extraData.isNotEmpty) {
                          context.go('/checkout', extra: extraData);
                        } else {
                          context.go('/checkout');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        _getCheckoutButtonText(isReservation, isDineIn),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}