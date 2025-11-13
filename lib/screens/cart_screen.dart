import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/reservation_data.dart';
import '../models/cart_item.dart'; // ✅ TAMBAH: Import CartItem
import '../utils/gro_mode_badge.dart';
import '../widgets/cart/cart_item_card.dart';
import '../widgets/cart/cart_item_edit_dialog.dart';
import '../utils/currency_formatter.dart';

class CartScreen extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;
  final bool isOpenBill;
  final OpenBillData? openBillData;
  final bool isGroMode;

  const CartScreen({
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
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // 🔒 SAFETY CHECK: Verifikasi user sudah login
      try {
        // Ini akan throw error jika user belum set
        final _ = cartProvider.items;

        // Set GRO mode terlebih dahulu sebelum set context lainnya
        if (widget.isGroMode) {
          cartProvider.setGroMode(true);
          debugPrint('🛒 CartScreen: GRO Mode activated');
        }

        // Set context hanya jika diberikan dari parameter
        if (widget.isReservation && widget.reservationData != null) {
          cartProvider.setReservationData(widget.isReservation, widget.reservationData);
        } else if (widget.isDineIn && widget.tableNumber != null) {
          cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
        } else if (widget.isOpenBill && widget.openBillData != null) {
          cartProvider.setOpenBillData(widget.isOpenBill, widget.openBillData);
        }
      } catch (e) {
        // 🔒 User belum login, redirect ke login
        debugPrint('❌ CartScreen: User not logged in - $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan login terlebih dahulu'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );

          // Redirect ke login
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      }
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

  Widget _buildOpenBillInfo(OpenBillData openBillData) {
    if (!widget.isOpenBill || widget.openBillData == null) {
      return const SizedBox.shrink();
    }

    final data = widget.openBillData!;
    print(data);

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
                'Detail Open Bill',
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
                  '📅 ${DateFormat('yyyy-MM-dd').format(data.date)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '🕐 ${data.time.hour}:${data.time.minute.toString().padLeft(2, '0')}',
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
              const SizedBox(width: 8),
              Text(
                '🪑 ${data.tableNumbers}',
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
  String _getTitle(bool isReservation, bool isDineIn, bool isOpenBill, bool isGroMode) {
    if (isGroMode) {
      if (isReservation) return 'Keranjang Reservasi (GRO)';
      if (isOpenBill) return 'Keranjang Open Bill (GRO)';
      return 'Keranjang (GRO)';
    }

    if (isReservation) {
      return 'Keranjang Reservasi';
    } else if (isDineIn) {
      return 'Keranjang Dine In';
    } else if (isOpenBill) {
      return 'Keranjang Open Bill';
    } else {
      return 'Keranjang';
    }
  }

  // Method untuk mendapatkan empty state message
  String _getEmptyStateMessage(bool isReservation, bool isDineIn, bool isOpenBill, bool isGroMode) {
    if (isGroMode) {
      if (isReservation) return 'Tambahkan menu untuk reservasi';
      if (isOpenBill) return 'Tambahkan menu untuk open bill';
      return 'Tambahkan menu';
    }

    if (isReservation) {
      return 'Tambahkan menu untuk reservasi Anda';
    } else if (isDineIn) {
      return 'Tambahkan menu untuk dine in Anda';
    } else if (isOpenBill) {
      return 'Tambahkan menu untuk open bill Anda';
    } else {
      return 'Tambahkan menu favorit Anda';
    }
  }

  // Method untuk mendapatkan checkout button text
  String _getCheckoutButtonText(bool isReservation, bool isDineIn, bool isOpenBill, bool isGroMode) {
    return 'Lanjut Bayar';
  }

  // ✅ Method untuk handle edit item
  void _showEditDialog(BuildContext context, CartItem item, int index) {
    showDialog(
      context: context,
      builder: (context) => CartItemEditDialog(
        item: item,
        onSave: (updatedItem) {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          cartProvider.updateCartItem(index, updatedItem);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil diubah'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items;
        final bool isReservation = cartProvider.isReservation;
        final ReservationData? reservationData = cartProvider.reservationData;
        final bool isDineIn = cartProvider.isDineIn;
        final String? tableNumber = cartProvider.tableNumber;
        final bool isOpenBill = cartProvider.isOpenBill;
        final OpenBillData? openBillData = cartProvider.openBillData;
        final bool isGroMode = cartProvider.isGroMode;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (isGroMode) {
                  context.push('/menu', extra: {'isGroMode': true});
                } else {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/menu');
                  }
                }
              },
            ),
            // ✅ TITLE DENGAN BADGE GRO
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _getTitle(isReservation, isDineIn, isOpenBill, isGroMode),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isGroMode) const GroModeAppBarBadge(), // ✅ Badge di AppBar
              ],
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ✅ BANNER GRO MODE (Optional)

              // Reservation info at the top
              if (isReservation && reservationData != null)
                SliverToBoxAdapter(
                  child: _buildReservationInfo(reservationData),
                ),

              if (isOpenBill && openBillData != null)
                SliverToBoxAdapter(
                  child: _buildOpenBillInfo(openBillData),
                ),

              // Dine-in info at the top
              if (isDineIn && tableNumber != null)
                SliverToBoxAdapter(
                  child: _buildDineInInfo(tableNumber),
                ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cartItems.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade400),
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
                          _getEmptyStateMessage(isReservation, isDineIn, isOpenBill, isGroMode),
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
                            onIncrease: () => cartProvider.increaseQuantity(index),
                            onDecrease: () => cartProvider.decreaseQuantity(index),
                            onEdit: () => _showEditDialog(context, item, index),
                          ),
                        );
                      },
                      childCount: cartItems.length,
                    ),
                  ),
                ),

              // Button "Tambah Pesanan"
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3, left: 16, right: 16, bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isGroMode) {
                        context.push('/menu', extra: {'isGroMode': true});
                      } else {
                        context.go('/menu');
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
                        const Text('Total Harga',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          formatCurrency(cartProvider.totalPrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: cartItems.isEmpty ? null : () {
                        Map<String, dynamic> extraData = {'isGroMode': isGroMode};

                        if (isReservation && reservationData != null) {
                          extraData['isReservation'] = true;
                          extraData['reservationData'] = reservationData;
                        } else if (isOpenBill && openBillData != null) {
                          extraData['isOpenBill'] = true;
                          extraData['openBillData'] = openBillData;
                        } else if (isDineIn && tableNumber != null) {
                          extraData['isDineIn'] = true;
                          extraData['tableNumber'] = tableNumber;
                        }

                        if (extraData.length > 1) {
                          context.go('/checkout', extra: extraData);
                        } else {
                          context.go('/checkout', extra: {'isGroMode': isGroMode});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        _getCheckoutButtonText(isReservation, isDineIn, isOpenBill, isGroMode),
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

  // @override
  // Widget build(BuildContext context) {
  //   return Consumer<CartProvider>(
  //     builder: (context, cartProvider, child) {
  //       final cartItems = cartProvider.items;
  //
  //       // Gunakan context dari provider
  //       final bool isReservation = cartProvider.isReservation;
  //       final ReservationData? reservationData = cartProvider.reservationData;
  //       final bool isDineIn = cartProvider.isDineIn;
  //       final String? tableNumber = cartProvider.tableNumber;
  //       final bool isOpenBill = cartProvider.isOpenBill;
  //       final OpenBillData? openBillData = cartProvider.openBillData;
  //       final bool isGroMode = cartProvider.isGroMode;
  //
  //       // Debug log untuk memastikan tidak ada kebocoran mode
  //       debugPrint('🛒 CartScreen Build - isGroMode: $isGroMode, widget.isGroMode: ${widget.isGroMode}');
  //
  //       return Scaffold(
  //         backgroundColor: Colors.white,
  //         appBar: ClassicAppBar(
  //           title: _getTitle(isReservation, isDineIn, isOpenBill, isGroMode),
  //           onBackPressed: () {
  //             if (isGroMode) {
  //               // ✅ GRO mode: kembali ke menu GRO dengan flag isGroMode
  //               context.push('/menu', extra: {
  //                 'isGroMode': true,
  //               });
  //             } else {
  //               // Customer mode: kembali ke menu atau pop
  //               if (Navigator.canPop(context)) {
  //                 Navigator.of(context).pop();
  //               } else {
  //                 context.go('/menu');
  //               }
  //             }
  //           },
  //         ),
  //         body: CustomScrollView(
  //           slivers: [
  //             // Reservation info at the top
  //             if (isReservation && reservationData != null)
  //               SliverToBoxAdapter(
  //                 child: _buildReservationInfo(reservationData),
  //               ),
  //
  //             if (isOpenBill && openBillData != null)
  //               SliverToBoxAdapter(
  //                 child: _buildOpenBillInfo(openBillData),
  //               ),
  //
  //             // Dine-in info at the top
  //             if (isDineIn && tableNumber != null)
  //               SliverToBoxAdapter(
  //                 child: _buildDineInInfo(tableNumber),
  //               ),
  //
  //             if (_isLoading)
  //               const SliverFillRemaining(
  //                 child: Center(child: CircularProgressIndicator()),
  //               )
  //             else if (cartItems.isEmpty)
  //               SliverFillRemaining(
  //                 child: Center(
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
  //                       const SizedBox(height: 16),
  //                       Text(
  //                         'Keranjang Anda kosong',
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.grey.shade700,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         _getEmptyStateMessage(isReservation, isDineIn, isOpenBill, isGroMode),
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.grey.shade600,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               )
  //             else
  //               SliverPadding(
  //                 padding: const EdgeInsets.all(16),
  //                 sliver: SliverList(
  //                   delegate: SliverChildBuilderDelegate(
  //                         (context, index) {
  //                       final item = cartItems[index];
  //                       return Padding(
  //                         padding: const EdgeInsets.only(bottom: 16),
  //                         child: CartItemCard(
  //                           item: item,
  //                           onIncrease: () => cartProvider.increaseQuantity(index),
  //                           onDecrease: () => cartProvider.decreaseQuantity(index),
  //                           onEdit: () => _showEditDialog(context, item, index),
  //                         ),
  //                       );
  //                     },
  //                     childCount: cartItems.length,
  //                   ),
  //                 ),
  //               ),
  //
  //             // ✅ Button "Tambah Pesanan" - kembali ke menu dengan mode yang sesuai
  //             SliverToBoxAdapter(
  //               child: Padding(
  //                 padding: const EdgeInsets.only(top: 3, left: 16, right: 16, bottom: 16),
  //                 child: ElevatedButton.icon(
  //                   onPressed: () {
  //                     if (isGroMode) {
  //                       // ✅ GRO mode: kembali ke menu GRO
  //                       context.push('/menu', extra: {
  //                         'isGroMode': true,
  //                       });
  //                     } else {
  //                       // Customer mode: kembali ke menu
  //                       context.go('/menu');
  //                     }
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     minimumSize: const Size(double.infinity, 50),
  //                     backgroundColor: AppTheme.primaryColor,
  //                   ),
  //                   icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
  //                   label: const Text(
  //                     'Tambah Pesanan',
  //                     style: TextStyle(color: Colors.white, fontSize: 16),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         bottomNavigationBar: SafeArea(
  //           child: Material(
  //             elevation: 4,
  //             shadowColor: Colors.grey.shade300,
  //             color: Colors.white,
  //             clipBehavior: Clip.none,
  //             child: Container(
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.grey.withOpacity(0.4),
  //                     spreadRadius: 1,
  //                     blurRadius: 6,
  //                     offset: const Offset(0, -3),
  //                   ),
  //                 ],
  //               ),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       const Text('Total Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //                       Text(
  //                           formatCurrency(cartProvider.totalPrice),
  //                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 16),
  //                   ElevatedButton(
  //                     onPressed: cartItems.isEmpty ? null : () {
  //                       Map<String, dynamic> extraData = {
  //                         'isGroMode': isGroMode,
  //                       };
  //
  //                       if (isReservation && reservationData != null) {
  //                         extraData['isReservation'] = true;
  //                         extraData['reservationData'] = reservationData;
  //                       } else if (isOpenBill && openBillData != null) {
  //                         extraData['isOpenBill'] = true;
  //                         extraData['openBillData'] = openBillData;
  //                       } else if (isDineIn && tableNumber != null) {
  //                         extraData['isDineIn'] = true;
  //                         extraData['tableNumber'] = tableNumber;
  //                       }
  //
  //                       if (extraData.length > 1) {
  //                         context.go('/checkout', extra: extraData);
  //                       } else {
  //                         context.go('/checkout', extra: {'isGroMode': isGroMode});
  //                       }
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       minimumSize: const Size(double.infinity, 50),
  //                       backgroundColor: AppTheme.primaryColor,
  //                     ),
  //                     child: Text(
  //                       _getCheckoutButtonText(isReservation, isDineIn, isOpenBill, isGroMode),
  //                       style: const TextStyle(color: Colors.white, fontSize: 16),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}