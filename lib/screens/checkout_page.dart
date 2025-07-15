import 'package:baraja_app/utils/base_screen_wrapper.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart' as serviceorder;
import '../widgets/payment/cart_item_widget.dart';
import '../widgets/payment/checkout_summary.dart';
import '../widgets/payment/order_type_selector.dart';
import '../widgets/payment/payment_method_widget.dart';
import '../widgets/payment/payment_type_widget.dart';
import '../widgets/payment/voucher_widget.dart';

// Enum untuk tipe reservasi
enum ReservationType { nonBlocking, blocking }

class CheckoutPage extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;

  const CheckoutPage({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Pilihan tipe pesanan
  late OrderType selectedOrderType;
  // Data meja untuk Dine-in
  late String tableNumber;
  // Data untuk Delivery
  String deliveryAddress = "";
  // Data untuk Pickup
  TimeOfDay? pickupTime;
  // Data metode pembayaran
  String? selectedPaymentMethod;
  String? selectedPaymentMethodName;
  String? selectedBankName;
  String? selectedBankCode;
  // Data voucher - updated variables
  String? selectedVoucherCode;
  String voucherDescription = "";
  int discountAmount = 0;
  PaymentType selectedPaymentType = PaymentType.fullPayment;

  // Tambahan untuk reservation type
  ReservationType selectedReservationType = ReservationType.nonBlocking;

  @override
  void initState() {
    super.initState();

    // Set default values
    selectedOrderType = OrderType.delivery; // Default order type
    tableNumber = ""; // Default table number

    // Get actual data from CartProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Set initial order type based on the current context
      if (cartProvider.isReservation) {
        // For reservations, we'll use a special handling in the UI
        // No need to set tableNumber for reservations
      } else if (cartProvider.isDineIn && cartProvider.tableNumber != null) {
        selectedOrderType = OrderType.dineIn;
        tableNumber = cartProvider.tableNumber!;
      } else {
        // For delivery or pickup, tableNumber remains an empty string
        tableNumber = "";
      }
      setState(() {});
    });
  }

  // Calculate the discount amount based on the selected voucher
  int calculateDiscount(int subtotal) {
    if (selectedVoucherCode == null) return 0;

    switch (selectedVoucherCode) {
      case 'DISC10':
        final discount = (subtotal * 0.1).round();
        return discount > 20000 ? 20000 : discount;
      case 'DISC15':
        if (subtotal >= 20000) {
          final discount = (subtotal * 0.15).round();
          return discount > 25000 ? 25000 : discount;
        }
        return 0;
      default:
        return 0;
    }
  }

  // Method untuk mengecek apakah area code memerlukan pilihan reservation type
  bool _shouldShowReservationType(String? areaCode) {
    return areaCode == 'A' || areaCode == 'B';
  }

  // Method untuk mengecek apakah blocking bisa dipilih berdasarkan total dan area code
  bool _canSelectBlocking(String? areaCode, int totalAmount) {
    if (areaCode == 'A') {
      return totalAmount >= 3000000; // Rp. 3.000.000 untuk area A
    } else if (areaCode == 'B') {
      return totalAmount >= 2000000; // Rp. 2.000.000 untuk area B
    }
    return false;
  }

  // Method untuk mendapatkan minimum amount untuk blocking
  int _getMinimumAmountForBlocking(String? areaCode) {
    if (areaCode == 'A') {
      return 3000000;
    } else if (areaCode == 'B') {
      return 2000000;
    }
    return 0;
  }

  // Format tampilan metode pembayaran
  String get displayedPaymentMethod {
    if (selectedPaymentMethodName == null ||
        selectedPaymentMethodName!.isEmpty) {
      return "Pilih Pembayaran";
    }
    if (selectedBankName != null && selectedBankName!.isNotEmpty) {
      return "$selectedPaymentMethodName - $selectedBankName";
    }
    return selectedPaymentMethodName!;
  }

  // Widget untuk menampilkan info reservasi
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

  // Widget untuk pilihan reservation type
  Widget _buildReservationTypeSelector(ReservationData data, int finalTotal) {
    if (!_shouldShowReservationType(data.areaCode)) {
      return const SizedBox.shrink();
    }

    final bool canSelectBlocking = _canSelectBlocking(data.areaCode, finalTotal);
    final int minAmount = _getMinimumAmountForBlocking(data.areaCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_seat, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Tipe Reservasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Non-Blocking Option
          GestureDetector(
            onTap: () {
              setState(() {
                selectedReservationType = ReservationType.nonBlocking;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: selectedReservationType == ReservationType.nonBlocking
                    ? Colors.purple.shade100
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedReservationType == ReservationType.nonBlocking
                      ? Colors.purple.shade400
                      : Colors.grey.shade300,
                  width: selectedReservationType == ReservationType.nonBlocking ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedReservationType == ReservationType.nonBlocking
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Non-Blocking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          'Meja bisa digunakan customer lain setelah waktu reservasi berakhir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blocking Option
          GestureDetector(
            onTap: canSelectBlocking ? () {
              setState(() {
                selectedReservationType = ReservationType.blocking;
              });
            } : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canSelectBlocking
                    ? (selectedReservationType == ReservationType.blocking
                    ? Colors.purple.shade100
                    : Colors.white)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canSelectBlocking
                      ? (selectedReservationType == ReservationType.blocking
                      ? Colors.purple.shade400
                      : Colors.grey.shade300)
                      : Colors.grey.shade300,
                  width: selectedReservationType == ReservationType.blocking ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedReservationType == ReservationType.blocking
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: canSelectBlocking ? Colors.purple.shade700 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blocking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: canSelectBlocking ? Colors.purple.shade700 : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          canSelectBlocking
                              ? 'Meja tidak bisa digunakan customer lain sampai Anda datang'
                              : 'Minimum pembelian Rp${minAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} untuk area ${data.areaCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!canSelectBlocking) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tambahkan Rp${(minAmount - finalTotal).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} lagi untuk mengaktifkan opsi Blocking',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget untuk menampilkan info dine-in
  Widget _buildDineInInfo() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (!cartProvider.isDineIn || cartProvider.tableNumber == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            'Meja No. ${cartProvider.tableNumber}',
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

  // Method untuk menentukan apakah order type selector harus ditampilkan
  bool _shouldShowOrderTypeSelector(CartProvider cartProvider) {
    // Jangan tampilkan selector jika dalam mode reservasi atau dine-in
    return !cartProvider.isReservation && !cartProvider.isDineIn;
  }

  // Method untuk mendapatkan title section berdasarkan mode
  String _getOrderTypeTitle(CartProvider cartProvider) {
    if (cartProvider.isReservation) {
      return "Konfirmasi Pesanan Reservasi";
    } else if (cartProvider.isDineIn) {
      return "Konfirmasi Pesanan Dine In";
    } else {
      return "Mau makan dimana?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final List<CartItem> cartItems = cartProvider.items;
        final int subtotal = cartProvider.totalPrice;
        final int discount = calculateDiscount(subtotal);
        final int finalTotal = subtotal - discount;

        // Calculate down payment amount (50% of final total)
        final int downPaymentAmount = (finalTotal * 0.5).round();

        // Auto-set reservation type to non-blocking if blocking is not available
        if (cartProvider.isReservation &&
            cartProvider.reservationData != null &&
            _shouldShowReservationType(cartProvider.reservationData!.areaCode) &&
            !_canSelectBlocking(cartProvider.reservationData!.areaCode, finalTotal) &&
            selectedReservationType == ReservationType.blocking) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedReservationType = ReservationType.nonBlocking;
            });
          });
        }

        return BaseScreenWrapper(
          customBackRoute: '/cart',
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: const ClassicAppBar(
              title: 'Pembayaran',
              customBackRoute: '/history',
            ),
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                // Konten utama dengan scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reservation info at the top
                          if (cartProvider.isReservation && cartProvider.reservationData != null)
                            _buildReservationInfo(cartProvider.reservationData!),

                          // Reservation Type Selector - untuk area A dan B
                          if (cartProvider.isReservation &&
                              cartProvider.reservationData != null &&
                              _shouldShowReservationType(cartProvider.reservationData!.areaCode))
                            _buildReservationTypeSelector(cartProvider.reservationData!, finalTotal),

                          // Dine-in info at the top
                          if (cartProvider.isDineIn)
                            _buildDineInInfo(),

                          // Daftar Item Keranjang
                          if (cartItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  "Keranjang belanja kosong",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...cartItems.asMap().entries.map((entry) {
                              CartItem item = entry.value;
                              return CartItemWidget(
                                item: item,
                              );
                            }),
                          const SizedBox(height: 24),

                          // Pemilihan Tipe Pesanan - Conditional Display
                          Text(
                            _getOrderTypeTitle(cartProvider),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          if (_shouldShowOrderTypeSelector(cartProvider)) ...[
                            Text(
                              "*Kami buka 24 Jam",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Custom Order Type Selector - Hanya tampilkan Delivery dan Pickup
                            OrderTypeSelector(
                              selectedType: selectedOrderType,
                              onChanged: (type) {
                                setState(() {
                                  selectedOrderType = type;
                                });
                              },
                              tableNumber: tableNumber,
                              onTableNumberChanged: (value) {
                                setState(() {
                                  tableNumber = value;
                                });
                              },
                              deliveryAddress: deliveryAddress,
                              onDeliveryAddressChanged: (value) {
                                setState(() {
                                  deliveryAddress = value;
                                });
                              },
                              pickupTime: pickupTime,
                              onPickupTimeChanged: (time) {
                                setState(() {
                                  pickupTime = time;
                                });
                              },
                              // Parameter baru untuk menyembunyikan opsi dine-in
                              hideDineInOption: true,
                            ),
                          ] else ...[
                            // Show fixed order type info untuk reservasi/dine-in
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cartProvider.isReservation
                                        ? 'Pesanan untuk reservasi Anda'
                                        : 'Pesanan untuk meja ${cartProvider.tableNumber}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Payment Type Selection for Reservations - Moved here
                          if (cartProvider.isReservation) ...[
                            ReservationPaymentTypeWidget(
                              selectedType: selectedPaymentType,
                              onChanged: (PaymentType type) {
                                setState(() {
                                  selectedPaymentType = type;
                                });
                              },
                              totalAmount: finalTotal,
                              downPaymentAmount: downPaymentAmount,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Metode Pembayaran
                          PaymentMethodWidget(
                            selectedMethod: displayedPaymentMethod,
                            onTap: () async {
                              final result = await context
                                  .push<Map<String, dynamic>>('/paymentMethod');
                              if (result != null) {
                                setState(() {
                                  selectedPaymentMethod = result['payment_method'];
                                  selectedPaymentMethodName =
                                  result['payment_method_name'];
                                  if (result.containsKey('name')) {
                                    selectedBankName = result['name'];
                                  } else {
                                    selectedBankName = null;
                                  }
                                  if (result.containsKey('bank_code')) {
                                    selectedBankCode = result['bank_code'];
                                  } else {
                                    selectedBankCode = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          VoucherWidget(
                            voucherCode: selectedVoucherCode ?? "",
                            voucherApplied: selectedVoucherCode != null,
                            onVoucherSelected: (String selectedCode) {
                              setState(() {
                                selectedVoucherCode = selectedCode;
                                discountAmount = calculateDiscount(subtotal);
                                switch (selectedCode) {
                                  case 'DISC10':
                                    voucherDescription = 'Disc 10% up to Rp20.000';
                                    break;
                                  case 'DISC15':
                                    voucherDescription = 'Disc 15% up to Rp25.000';
                                    break;
                                  default:
                                    voucherDescription = '';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Updated Checkout Summary without payment type widget
                CheckoutSummary(
                  totalPrice: subtotal,
                  discount: discount,
                  voucherCode: selectedVoucherCode,
                  isReservation: cartProvider.isReservation,
                  selectedPaymentType: cartProvider.isReservation ? selectedPaymentType : null,
                  onCheckoutPressed: () async {
                    // Validasi input berdasarkan tipe pesanan
                    bool isValid = true;
                    String errorMessage = '';

                    // Skip validation untuk reservasi dan dine-in karena sudah pre-configured
                    if (!cartProvider.isReservation && !cartProvider.isDineIn) {
                      if (selectedOrderType == OrderType.delivery &&
                          deliveryAddress.isEmpty) {
                        isValid = false;
                        errorMessage = 'Silakan masukkan alamat pengantaran';
                      } else if (selectedOrderType == OrderType.pickup &&
                          pickupTime == null) {
                        isValid = false;
                        errorMessage = 'Silakan pilih waktu pengambilan';
                      }
                    }

                    if (selectedPaymentMethod == null) {
                      isValid = false;
                      errorMessage = 'Silakan pilih metode pembayaran';
                    }

                    if (!isValid) {
                      print(errorMessage);
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId');
                    final userName = prefs.getString('userName') ?? 'Guest';
                    int amountToPay = finalTotal;
                    if (cartProvider.isReservation && selectedPaymentType == PaymentType.downPayment) {
                      amountToPay = downPaymentAmount;
                    }
                    // Tampilkan loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    try {
                      final orderService = serviceorder.OrderService();
                      final List<Map<String, dynamic>> items = cartItems
                          .map((item) => {
                        'productId': item.id,
                        'productName': item.name,
                        'price': item.price,
                        'quantity': item.quantity,
                        'addons': item.addons,
                        'toppings': item.toppings,
                        'notes': item.notes,
                      })
                          .toList();

                      final Map<String, String?> paymentDetails = {
                        'method': selectedPaymentMethodName,
                        'methodName': selectedPaymentMethod,
                        'bankName': selectedBankName,
                        'bankCode': selectedBankCode,
                      };

                      // Determine order type based on current context
                      OrderType finalOrderType;
                      if (cartProvider.isReservation) {
                        finalOrderType = OrderType.reservation;
                      } else if (cartProvider.isDineIn) {
                        finalOrderType = OrderType.dineIn;
                      } else {
                        finalOrderType = selectedOrderType;
                      }

                      // Create order with payment type information for reservations
                      final orderResult = await orderService.createOrder(
                        items: items,
                        userId: userId ?? 'guest',
                        userName: userName,
                        orderType: finalOrderType,
                        tableNumber: cartProvider.isDineIn ? cartProvider.tableNumber :
                        (finalOrderType == OrderType.dineIn ? tableNumber : null),
                        deliveryAddress: finalOrderType == OrderType.delivery ? deliveryAddress : null,
                        pickupTime: finalOrderType == OrderType.pickup ? pickupTime : null,
                        paymentDetails: paymentDetails,
                        subtotal: subtotal,
                        discount: discount,
                        voucherCode: selectedVoucherCode,
                        reservationData: cartProvider.isReservation ? cartProvider.reservationData : null,
                        // PERBAIKAN: Pastikan reservationType dikirim dengan kondisi yang benar
                        reservationType: cartProvider.isReservation &&
                            cartProvider.reservationData != null &&
                            _shouldShowReservationType(cartProvider.reservationData!.areaCode)
                            ? selectedReservationType
                            : null, // Kirim null jika tidak applicable
                      );

                      Navigator.of(context).pop();

                      // Navigate to payment confirmation with payment type data
                      final extraData = {
                        'items': List.from(cartItems),
                        'userId': userId,
                        'userName': userName,
                        'orderType': finalOrderType,
                        'tableNumber': cartProvider.isDineIn ? cartProvider.tableNumber : tableNumber,
                        'deliveryAddress': deliveryAddress,
                        'pickupTime': pickupTime,
                        'paymentDetails': paymentDetails,
                        'subtotal': subtotal,
                        'discount': discount,
                        'total': finalTotal,
                        'paymentType': cartProvider.isReservation ? selectedPaymentType : null,
                        'amountToPay': amountToPay,
                        'voucherCode': selectedVoucherCode,
                        'id': orderResult['order']?['_id'] ?? '',
                        'orderId': orderResult['order']?['order_id'] ?? '',
                      };

                      // Add reservation and payment type data if applicable
                      if (cartProvider.isReservation && cartProvider.reservationData != null) {
                        extraData['reservationData'] = cartProvider.reservationData;
                        extraData['isReservation'] = true;
                        extraData['paymentType'] = selectedPaymentType;
                        extraData['downPaymentAmount'] = downPaymentAmount;

                        // Add reservation type data
                        if (_shouldShowReservationType(cartProvider.reservationData!.areaCode)) {
                          extraData['reservationType'] = selectedReservationType;
                          extraData['isBlocking'] = selectedReservationType == ReservationType.blocking;
                        }

                        // Add remaining payment amount for down payment option
                        if (selectedPaymentType == PaymentType.downPayment) {
                          extraData['remainingPayment'] = finalTotal - downPaymentAmount;
                          extraData['isDownPayment'] = true;
                        } else {
                          extraData['remainingPayment'] = 0;
                          extraData['isDownPayment'] = false;
                        }
                      } else {
                        // For non-reservation orders, set default values
                        extraData['remainingPayment'] = 0;
                        extraData['isDownPayment'] = false;
                      }

                      context.push('/paymentConfirmation', extra: extraData);

                      // Clear cart after successful checkout
                      cartProvider.clearCart();
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat pesanan: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}