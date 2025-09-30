import 'package:baraja_app/utils/base_screen_wrapper.dart';
import 'package:baraja_app/widgets/utils/classic_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order_type.dart';
import '../models/reservation_data.dart';
import '../models/voucher_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart' as serviceorder;
import '../services/table_Service.dart';
import '../services/tax_service.dart';
import '../widgets/checkout/cart_item_widget.dart';
import '../widgets/checkout/checkout_summary.dart';
import '../widgets/checkout/checkout_validator.dart';
import '../widgets/checkout/dine_in_info_widget.dart';
import '../widgets/checkout/open_bill_info_widget.dart';
import '../widgets/checkout/reservation_info_widget.dart';
import '../widgets/checkout/order_type_selector_widget.dart';
import '../widgets/checkout/reservation_payment_type_widget.dart';
import '../widgets/checkout/reservation_type_selector_widget.dart';
import '../widgets/checkout/voucher_widget.dart';
import '../widgets/utils/payment_method_with_validation.dart';

// Enum untuk tipe reservasi
enum ReservationType { nonBlocking, blocking }

class CheckoutPage extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;
  final bool isOpenBill;
  final OpenBillData? openBillData;

  const CheckoutPage({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
    this.isOpenBill = false,
    this.openBillData,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {

  // Pilihan tipe pesanan
  late OrderType selectedOrderType;
  String? outletId;
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
  Voucher? selectedVoucher;

  String voucherDescription = "";
  int discountAmount = 0;
  PaymentType selectedPaymentType = PaymentType.fullPayment;

  // Tambahan untuk reservation type
  ReservationType selectedReservationType = ReservationType.nonBlocking;

  // Validation state variables
  Map<String, String> validationErrors = {};
  bool hasAttemptedSubmit = false;

  final TaxService _taxService = TaxService();
  final TableService _tableService = TableService();
  TaxCalculationResult? _taxCalculation;
  bool _taxesLoaded = false;
  // Scroll controller untuk auto scroll ke error
  final ScrollController _scrollController = ScrollController();

  // Global keys untuk setiap field yang perlu validasi
  final GlobalKey _deliveryAddressKey = GlobalKey();
  final GlobalKey _pickupTimeKey = GlobalKey();
  final GlobalKey _tableNumberKey = GlobalKey();
  final GlobalKey _paymentMethodKey = GlobalKey();
  final GlobalKey _reservationTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeTaxData();

    // Set default values
    selectedOrderType = OrderType.dineIn; // Default order type
    tableNumber = ""; // Default table number

    // Get actual data from CartProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (_isReservationWithoutMenu(cartProvider)) {
        setState(() {
          selectedPaymentType = PaymentType.fullPayment;
        });
      }
      if (cartProvider.items.isNotEmpty) {
        setState(() {
          outletId = cartProvider.items.first.outletId?.toString();
        });
      }
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
  bool _isReservationWithoutMenu(CartProvider cartProvider) {
    return cartProvider.isReservation &&
        cartProvider.items.isEmpty &&
        cartProvider.totalPrice == 25000;
  }
  Future<void> _initializeTaxData() async {
    try {
      await _taxService.getTaxesAndServices();
      setState(() {
        _taxesLoaded = true;
      });
      _calculateTaxes();
    } catch (e) {
      print('Error initializing tax data: $e');
      setState(() {
        _taxesLoaded = true; // Continue without taxes
      });
    }
  }

  // Add these debug statements to your _calculateTaxes() method in checkout_page.dart

  void _calculateTaxes() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    print("🔍 DEBUG TAX CALCULATION:");
    print("- _taxesLoaded: $_taxesLoaded");
    print("- outletId: $outletId");
    print("- isOpenBill: ${cartProvider.isOpenBill}");
    print("- isReservation: ${cartProvider.isReservation}");

    if (!_taxesLoaded || outletId == null) {
      print("❌ Tax calculation skipped - missing requirements");
      setState(() {
        _taxCalculation = null;
      });
      return;
    }

    final subtotal = cartProvider.totalPrice;
    final discount = calculateDiscount(subtotal);
    final finalTotal = subtotal - discount;

    print("- subtotal: $subtotal");
    print("- discount: $discount");
    print("- finalTotal: $finalTotal");

    final taxCalculation = _taxService.calculateTaxes(
      subtotal: finalTotal.toDouble(),
      outletId: outletId!,
      isReservation: cartProvider.isReservation,
      isOpenBill: cartProvider.isOpenBill,
    );

    print("- taxCalculation result: ${taxCalculation.totalTaxAmount}");
    print("- taxDetails: ${taxCalculation.taxDetails}");

    setState(() {
      _taxCalculation = taxCalculation;
    });
  }

  int calculateDiscount(int subtotal) {
    if (selectedVoucher == null) return 0;

    int discount = 0;
    if (selectedVoucher!.discountType == "percentage") {
      discount = (subtotal * (selectedVoucher!.discountAmount / 100)).round();
    } else if (selectedVoucher!.discountType == "fixed") {
      discount = selectedVoucher!.discountAmount;
    }

    // Recalculate taxes when discount changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTaxes();
    });

    return discount;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Method untuk scroll ke field yang error
  void _scrollToError(String errorKey) {
    GlobalKey? targetKey;

    switch (errorKey) {
      case 'deliveryAddress':
        targetKey = _deliveryAddressKey;
        break;
      case 'pickupTime':
        targetKey = _pickupTimeKey;
        break;
      case 'tableNumber':
        targetKey = _tableNumberKey;
        break;
      case 'paymentMethod':
        targetKey = _paymentMethodKey;
        break;
      case 'reservationType':
        targetKey = _reservationTypeKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll sedikit ke atas dari field
        );
      });
    }
  }

  // Helper method untuk mendapatkan waktu minimum pickup (5 menit dari sekarang)
  TimeOfDay _getMinimumPickupTime() {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));
    return TimeOfDay.fromDateTime(minimumTime);
  }

  // Helper method untuk mengecek apakah waktu pickup valid
  bool _isValidPickupTime(TimeOfDay selectedTime) {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));

    // Convert TimeOfDay to DateTime untuk perbandingan
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
  }

  // Helper method untuk format waktu
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method untuk format currency
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.'
    );
  }

  // Calculate the discount amount based on the selected voucher
  // int calculateDiscount(int subtotal) {
  //   if (selectedVoucher == null) return 0;
  //
  //   if (selectedVoucher!.discountType == "percentage") {
  //     final discount = (subtotal * (selectedVoucher!.discountAmount / 100)).round();
  //     return discount;
  //   } else if (selectedVoucher!.discountType == "fixed") {
  //     return selectedVoucher!.discountAmount;
  //   }
  //   return 0;
  // }


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

  // Method untuk menentukan apakah order type selector harus ditampilkan
// Method untuk menentukan apakah order type selector harus ditampilkan
  bool _shouldShowOrderTypeSelector(CartProvider cartProvider) {
    // Jangan tampilkan selector jika dalam mode reservasi, dine-in, atau open bill
    return !cartProvider.isReservation && !cartProvider.isDineIn && !cartProvider.isOpenBill;
  }

  // Method untuk mendapatkan title section berdasarkan mode
  String _getOrderTypeTitle(CartProvider cartProvider) {
    if (cartProvider.isReservation) {
      return "Konfirmasi Pesanan Reservasi";
    } else if (cartProvider.isDineIn) {
      return "Konfirmasi Pesanan Dine In";
    } else if (cartProvider.isOpenBill){
      return "Konfirmasi Open Bill";
    } else {
      // Cek selected order type untuk non-fixed modes
      switch (selectedOrderType) {
        case OrderType.takeAway:
          return "Konfirmasi Pesanan Take Away";
        case OrderType.delivery:
          return "Konfirmasi Pesanan Delivery";
        case OrderType.pickup:
          return "Konfirmasi Pesanan Pickup";
        case OrderType.dineIn:
          return "Konfirmasi Pesanan Dine In";
        default:
          return "Mau makan dimana?";
      }
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
        final int taxAmount = _taxCalculation?.totalTaxAmount.round() ?? 0;
        final int grandTotal = finalTotal + taxAmount;

        // Calculate down payment amount based on grand total (including tax)
        final int downPaymentAmount = (grandTotal * 0.5).round();

        // Recalculate taxes when cart changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_taxesLoaded) {
            _calculateTaxes();
          }
        });

        // Auto-set reservation type to non-blocking if blocking is not available
        // Update this check to use grandTotal instead of finalTotal
        if (cartProvider.isReservation &&
            cartProvider.reservationData != null &&
            _shouldShowReservationType(cartProvider.reservationData!.areaCode) &&
            !_canSelectBlocking(cartProvider.reservationData!.areaCode, grandTotal) &&
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
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Reservation info at the top
                          if (cartProvider.isReservation && cartProvider.reservationData != null)
                            ReservationInfoWidget(data: cartProvider.reservationData!),


                          if (cartProvider.isReservation && cartProvider.reservationData != null)
                            ReservationTypeSelectorWidget(
                              data: cartProvider.reservationData!,
                              finalTotal: finalTotal,
                              selectedReservationType: selectedReservationType,
                              hasAttemptedSubmit: hasAttemptedSubmit,
                              validationErrors: validationErrors,
                              onChanged: (type) {
                                setState(() {
                                  selectedReservationType = type;
                                  if (hasAttemptedSubmit) {
                                    validationErrors.remove('reservationType');
                                  }
                                });
                              },
                            ),
                          if (cartProvider.isOpenBill && cartProvider.openBillData != null)
                            OpenBillInfoWidget(openBillData: cartProvider.openBillData!),


                          // Dine-in info at the top
                          if (cartProvider.isDineIn)
                            const DineInInfoWidget(),




                          // Daftar Item Keranjang
                          if (cartItems.isEmpty)
                            if (cartProvider.isReservation)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    "Reservasi tanpa menu (Rp25.000)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
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

                            // Enhanced Order Type Selector with inline validation
                            OrderTypeSelectorWithValidation(
                              selectedType: selectedOrderType,
                              onChanged: (type) => setState(() => selectedOrderType = type),
                              tableNumber: tableNumber,
                              onTableNumberChanged: (val) => setState(() => tableNumber = val),
                              deliveryAddress: deliveryAddress,
                              onDeliveryAddressChanged: (val) => setState(() => deliveryAddress = val),
                              pickupTime: pickupTime,
                              onPickupTimeChanged: (time) => setState(() => pickupTime = time),
                              validationErrors: validationErrors,
                              hasAttemptedSubmit: hasAttemptedSubmit,
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
                                        : cartProvider.isOpenBill
                                        ? 'Pesanan untuk meja ${cartProvider.openBillData!.tableNumbers}'
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
                            // Jika reservasi tanpa menu, otomatis hide widget atau set ke full payment
                            if (!_isReservationWithoutMenu(cartProvider))
                              ReservationPaymentTypeWidget(
                                selectedType: selectedPaymentType,
                                onChanged: (PaymentType type) {
                                  setState(() {
                                    selectedPaymentType = type;
                                  });
                                },
                                totalAmount: grandTotal,
                                downPaymentAmount: downPaymentAmount,
                              ),

                            // Info box untuk reservasi tanpa menu
                            if (_isReservationWithoutMenu(cartProvider))
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      color: Colors.blue.shade600,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pembayaran Reservasi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Biaya reservasi tanpa menu: ${_formatCurrency(25000)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pembayaran penuh diperlukan untuk mengkonfirmasi reservasi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],

                          // Enhanced Payment Method Widget with inline validation
                          PaymentMethodWithValidation(
                            displayedPaymentMethod: displayedPaymentMethod,
                            errorMessage: hasAttemptedSubmit ? validationErrors['paymentMethod'] : null,
                            onMethodSelected: (result) {
                              setState(() {
                                selectedPaymentMethod = result['payment_method'];
                                selectedPaymentMethodName = result['payment_method_name'];
                                selectedBankName = result['name'];
                                selectedBankCode = result['bank_code'];
                                validationErrors.remove('paymentMethod');
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          VoucherWidget(
                            voucherCode: selectedVoucher?.code ?? "",
                            voucherApplied: selectedVoucher != null,
                            onVoucherSelected: (Voucher voucher) {
                              setState(() {
                                selectedVoucher = voucher;
                                selectedVoucherCode = voucher.code; // ✅ tambahkan ini
                                discountAmount = calculateDiscount(subtotal);
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
                  discountType: selectedVoucher?.discountType,
                  isReservation: cartProvider.isReservation,
                  isOpenBill: cartProvider.isOpenBill,
                  selectedPaymentType: cartProvider.isReservation ? selectedPaymentType : null,
                  taxCalculation: _taxCalculation, // Pass tax calculation
                  onCheckoutPressed: () async {
                    print("➡️ Tombol checkout ditekan");

                    setState(() {
                      hasAttemptedSubmit = true;
                    });

                    // ✅ FIX: Add await and tableService parameter
                    final validationResult = await CheckoutValidator.validateForm(
                      cartProvider: cartProvider,
                      selectedOrderType: selectedOrderType,
                      deliveryAddress: deliveryAddress,
                      pickupTime: pickupTime,
                      tableNumber: tableNumber,
                      selectedPaymentMethod: selectedPaymentMethod,
                      selectedPaymentMethodName: selectedPaymentMethodName,
                      selectedReservationType: selectedReservationType,
                      calculateDiscount: calculateDiscount,
                      shouldShowReservationType: _shouldShowReservationType,
                      canSelectBlocking: _canSelectBlocking,
                      getMinimumAmountForBlocking: _getMinimumAmountForBlocking,
                      formatCurrency: _formatCurrency,
                      isValidPickupTime: _isValidPickupTime,
                      getMinimumPickupTime: _getMinimumPickupTime,
                      formatTime: _formatTime,
                      tableService: _tableService, // ✅ ADD THIS PARAMETER
                    );

                    if (!validationResult['isValid']) {
                      setState(() {
                        validationErrors = Map<String, String>.from(validationResult['errors']);
                      });

                      // Show general error snackbar
                      if (validationErrors.containsKey('general')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validationErrors['general']!),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Scroll to first error field
                      if (validationResult['firstErrorKey'] != null) {
                        _scrollToError(validationResult['firstErrorKey']);
                      }

                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId');
                    final userName = prefs.getString('userName') ?? 'Guest';
                    int amountToPay = grandTotal;
                    if (cartProvider.isReservation && selectedPaymentType == PaymentType.downPayment) {
                      // Jika reservasi tanpa menu, selalu bayar full
                      if (_isReservationWithoutMenu(cartProvider)) {
                        amountToPay = grandTotal; // Always full payment for reservation without menu
                      } else {
                        amountToPay = downPaymentAmount;
                      }
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
                        'outletId': item.outletId,       // ✅ tambahkan
                        'outletName': item.outletName,
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
                      } else if (cartProvider.isOpenBill) {
                        // For open bill, it's essentially a dine-in order for an existing reservation
                        finalOrderType = OrderType.dineIn;
                      } else {
                        finalOrderType = selectedOrderType;
                      }
                      print("✅ sebelum createOrder : Memulai pembuatan pesanan...");
                      // Create order with payment type information for reservations
                      final orderResult = await orderService.createOrder(
                        items: items,
                        userId: userId ?? 'guest',
                        userName: userName,
                        orderType: finalOrderType,
                        outletId: outletId ?? '',
                        tableNumber: cartProvider.isDineIn ? cartProvider.tableNumber :
                        (finalOrderType == OrderType.dineIn ? tableNumber : null),
                        deliveryAddress: finalOrderType == OrderType.delivery ? deliveryAddress : null,
                        pickupTime: finalOrderType == OrderType.pickup ? pickupTime : null,
                        paymentDetails: paymentDetails,
                        subtotal: subtotal,
                        discount: discount,
                        taxDetails: _taxCalculation?.taxDetails,
                        totalTax: taxAmount,
                        voucherCode: selectedVoucherCode,
                        reservationData: cartProvider.isReservation ? cartProvider.reservationData : null,
                        openBillData: cartProvider.openBillData, // ✅ tambahkan ini
                        // PERBAIKAN: Pastikan reservationType dikirim dengan kondisi yang benar
                        reservationType: cartProvider.isReservation &&
                            cartProvider.reservationData != null &&
                            _shouldShowReservationType(cartProvider.reservationData!.areaCode)
                            ? selectedReservationType
                            : null, // Kirim null jika tidak applicable
                      );

                      print("✅ createOrder berhasil: $orderResult");

                      Navigator.of(context).pop();

                      // Navigate to payment confirmation with payment type data
                      // Update the extra data for navigation to include open bill info
                      final extraData = {
                        'items': List.from(cartItems),
                        'userId': userId,
                        'userName': userName,
                        'orderType': finalOrderType,
                        'tableNumber': cartProvider.isDineIn ? cartProvider.tableNumber :
                        cartProvider.isOpenBill ? cartProvider.openBillData?.tableNumbers :
                        tableNumber,
                        'deliveryAddress': deliveryAddress,
                        'pickupTime': pickupTime,
                        'paymentDetails': paymentDetails,
                        'subtotal': subtotal,
                        'discount': discount,
                        'total': finalTotal,
                        // ✅ TAMBAHKAN INI - Tax data yang sebelumnya hilang
                        'taxAmount': taxAmount,
                        'taxDetails': _taxCalculation?.taxDetails ?? [],
                        'grandTotal': grandTotal, // Total sudah termasuk tax
                        'paymentType': cartProvider.isReservation ? selectedPaymentType : null,
                        'amountToPay': amountToPay, // Sudah menggunakan grandTotal untuk perhitungan
                        'voucherCode': selectedVoucherCode,
                        'id': orderResult['order']?['_id'] ?? '',
                        'orderId': orderResult['order']?['order_id'] ?? '',
                      };

// Add open bill specific data
                      if (cartProvider.isOpenBill && cartProvider.openBillData != null) {
                        extraData['isOpenBill'] = true;
                        extraData['openBillData'] = cartProvider.openBillData;
                        extraData['existingReservation'] = orderResult['existingReservation'];
                      }

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