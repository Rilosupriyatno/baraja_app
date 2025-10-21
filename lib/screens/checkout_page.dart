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
import '../services/table_service.dart';
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
  final bool isGroMode; // NEW

  const CheckoutPage({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
    this.isOpenBill = false,
    this.openBillData,
    this.isGroMode = false, // Default false
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

  // Variables untuk track perubahan dan mencegah infinite loop
  int? _lastCalculatedSubtotal;
  int? _lastCalculatedDiscount;
  String? _lastCalculatedOutletId;

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
    selectedOrderType = OrderType.dineIn;
    tableNumber = "";

    // Get actual data from CartProvider and setup listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Add listener untuk track perubahan cart
      cartProvider.addListener(_onCartChanged);

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
      } else if (cartProvider.isDineIn && cartProvider.tableNumber != null) {
        selectedOrderType = OrderType.dineIn;
        tableNumber = cartProvider.tableNumber!;
      } else {
        tableNumber = "";
      }

      // Initial tax calculation
      if (_taxesLoaded) {
        _calculateTaxes();
      }

      setState(() {});
    });
  }

  // Listener untuk perubahan cart
  void _onCartChanged() {
    if (_taxesLoaded && mounted) {
      _calculateTaxes();
    }
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
        _taxesLoaded = true;
      });
    }
  }

  void _calculateTaxes() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (!_taxesLoaded || outletId == null) {
      if (_taxCalculation != null) {
        setState(() {
          _taxCalculation = null;
        });
      }
      return;
    }

    final subtotal = cartProvider.totalPrice;
    final discount = calculateDiscount(subtotal);
    final finalTotal = subtotal - discount;

    // Check if values have actually changed to prevent unnecessary recalculation
    if (_lastCalculatedSubtotal == subtotal &&
        _lastCalculatedDiscount == discount &&
        _lastCalculatedOutletId == outletId) {
      return; // Skip if nothing changed
    }

    print("🔍 DEBUG TAX CALCULATION:");
    print("- _taxesLoaded: $_taxesLoaded");
    print("- outletId: $outletId");
    print("- isOpenBill: ${cartProvider.isOpenBill}");
    print("- isReservation: ${cartProvider.isReservation}");
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

    // Update last calculated values
    _lastCalculatedSubtotal = subtotal;
    _lastCalculatedDiscount = discount;
    _lastCalculatedOutletId = outletId;

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

    return discount;
  }

  @override
  void dispose() {
    // Remove listener sebelum dispose
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.removeListener(_onCartChanged);
    } catch (e) {
      // Ignore error if provider is already disposed
    }
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
          alignment: 0.1,
        );
      });
    }
  }

  TimeOfDay _getMinimumPickupTime() {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));
    return TimeOfDay.fromDateTime(minimumTime);
  }

  bool _isValidPickupTime(TimeOfDay selectedTime) {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.'
    );
  }

  bool _shouldShowReservationType(String? areaCode) {
    return areaCode == 'A' || areaCode == 'B';
  }

  bool _canSelectBlocking(String? areaCode, int totalAmount) {
    if (areaCode == 'A') {
      return totalAmount >= 3000000;
    } else if (areaCode == 'B') {
      return totalAmount >= 2000000;
    }
    return false;
  }

  int _getMinimumAmountForBlocking(String? areaCode) {
    if (areaCode == 'A') {
      return 3000000;
    } else if (areaCode == 'B') {
      return 2000000;
    }
    return 0;
  }

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

  bool _shouldShowOrderTypeSelector(CartProvider cartProvider) {
    return !cartProvider.isReservation && !cartProvider.isDineIn && !cartProvider.isOpenBill;
  }

  String _getOrderTypeTitle(CartProvider cartProvider) {
    if (cartProvider.isReservation) {
      return "Konfirmasi Pesanan Reservasi";
    } else if (cartProvider.isDineIn) {
      return "Konfirmasi Pesanan Dine In";
    } else if (cartProvider.isOpenBill){
      return "Konfirmasi Open Bill";
    } else {
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

        final int downPaymentAmount = (grandTotal * 0.5).round();

        // Auto-set reservation type to non-blocking if blocking is not available
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
          customBackRoute: widget.isGroMode ? '/gro-table-availability' : '/cart',
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: const ClassicAppBar(
              title: 'Pembayaran',
              usePopInsteadOfGo: true
              // customBackRoute: widget.isGroMode ? '/gro-table-availability' : '/history',
            ),
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

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

                          if (cartProvider.isReservation) ...[
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
                                selectedVoucherCode = voucher.code;
                                discountAmount = calculateDiscount(subtotal);
                              });
                              // Trigger tax recalculation after voucher changes
                              _calculateTaxes();
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                CheckoutSummary(
                  totalPrice: subtotal,
                  discount: discount,
                  voucherCode: selectedVoucherCode,
                  discountType: selectedVoucher?.discountType,
                  isReservation: cartProvider.isReservation,
                  isOpenBill: cartProvider.isOpenBill,
                  selectedPaymentType: cartProvider.isReservation ? selectedPaymentType : null,
                  taxCalculation: _taxCalculation,
                  // File: checkout_page.dart
// Di dalam method onCheckoutPressed (sekitar line 718)
// GANTI BAGIAN INI:

                  onCheckoutPressed: () async {
                    print("➡️ Tombol checkout ditekan");

                    setState(() {
                      hasAttemptedSubmit = true;
                    });

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
                      tableService: _tableService,
                      isGroMode: widget.isGroMode,
                    );

                    if (!validationResult['isValid']) {
                      setState(() {
                        validationErrors = Map<String, String>.from(validationResult['errors']);
                      });

                      if (validationErrors.containsKey('general')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validationErrors['general']!),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (validationResult['firstErrorKey'] != null) {
                        _scrollToError(validationResult['firstErrorKey']);
                      }

                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();

                    // ✅ PERBAIKAN UTAMA: Handle user data berbeda untuk GRO mode
                    String? userId;
                    String userName;

                    if (widget.isGroMode) {
                      // Untuk GRO mode, gunakan guest data dari reservationData
                      if (cartProvider.reservationData != null) {
                        // Backend akan create/find user berdasarkan phone
                        userId = null;
                        userName = 'null';

                        print("🔍 GRO Mode - Using Guest Data:");
                        print("  Guest Name: $userName");
                        // print("  Guest Phone: ${cartProvider.reservationData!.guestPhone}");
                      } else {
                        userId = null;
                        userName = 'Walk-in Guest';
                        print("⚠️ GRO Mode - No reservation data, using default");
                      }
                    } else {
                      // Normal user flow - gunakan data user yang login
                      userId = prefs.getString('userId');
                      userName = prefs.getString('userName') ?? 'Guest';

                      print("👤 Normal Mode - Using Logged In User:");
                      print("  User ID: $userId");
                      print("  User Name: $userName");
                    }

                    int amountToPay = grandTotal;
                    if (cartProvider.isReservation && selectedPaymentType == PaymentType.downPayment) {
                      if (_isReservationWithoutMenu(cartProvider)) {
                        amountToPay = grandTotal;
                      } else {
                        amountToPay = downPaymentAmount;
                      }
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    // ignore: unused_local_variable
                    bool isDialogShown = false;

                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          isDialogShown = true;
                          return WillPopScope(
                            onWillPop: () async => false,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      );

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
                        'outletId': item.outletId,
                        'outletName': item.outletName,
                      })
                          .toList();

                      final Map<String, String?> paymentDetails = {
                        'method': selectedPaymentMethodName,
                        'methodName': selectedPaymentMethod,
                        'bankName': selectedBankName,
                        'bankCode': selectedBankCode,
                      };

                      OrderType finalOrderType;
                      if (cartProvider.isReservation) {
                        finalOrderType = OrderType.reservation;
                      } else if (cartProvider.isDineIn) {
                        finalOrderType = OrderType.dineIn;
                      } else if (cartProvider.isOpenBill) {
                        finalOrderType = OrderType.dineIn;
                      } else {
                        finalOrderType = selectedOrderType;
                      }
                      String? groId;
                      String? guestPhone;
                      String? guestName;
                      if (widget.isGroMode) {
                        groId = prefs.getString('userId'); // ID GRO yang sedang login
                        guestPhone = cartProvider.guestPhone; // Dari CartProvider
                        guestName = cartProvider.guestName;

                        print("🔍 GRO Mode Checkout:");
                        print("  GRO ID: $groId");
                        print("  Guest Name: $guestName");
                        print("  Guest Phone: $guestPhone");
                      }
                      print("✅ Sebelum createOrder - Memulai pembuatan pesanan...");
                      print("  User ID: $userId");
                      print("  User Name: $userName");
                      print("  Order Type: ${finalOrderType.toString()}");
                      print("  Is GRO Mode: ${widget.isGroMode}");

                      final orderResult = await orderService.createOrder(
                        items: items,
                        userId: userId ?? 'guest',
                        // userName: userName ,
                        userName: guestName ?? 'Guest',
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
                        openBillData: cartProvider.openBillData,
                        reservationType: cartProvider.isReservation &&
                            cartProvider.reservationData != null &&
                            _shouldShowReservationType(cartProvider.reservationData!.areaCode)
                            ? selectedReservationType
                            : null,
                        isGroMode: widget.isGroMode,
                        groId: groId,
                        guestPhone: guestPhone,
                      );

                      print("✅ createOrder berhasil: $orderResult");
                      print("➡️ ini adalah voucher code: $selectedVoucherCode");

                      Navigator.of(context).pop();

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
                        'taxAmount': taxAmount,
                        'taxDetails': _taxCalculation?.taxDetails ?? [],
                        'grandTotal': grandTotal,
                        'paymentType': cartProvider.isReservation ? selectedPaymentType : null,
                        'amountToPay': amountToPay,
                        'voucherCode': selectedVoucherCode,
                        'id': orderResult['order']?['_id'] ?? '',
                        'orderId': orderResult['order']?['order_id'] ?? '',
                        'isGroMode': widget.isGroMode,
                      };

                      if (widget.isGroMode) {
                        // Langsung ke PaymentConfirmationScreen seperti user biasa
                        context.push('/paymentConfirmation', extra: extraData);
                        cartProvider.clearCart();
                        return;
                      }


                      // CONDITIONAL NAVIGATION berdasarkan isGroMode
                      // if (widget.isGroMode) {
                      //   // Jika dari GRO, kembali ke table availability dengan success message
                      //   Navigator.of(context).pop(); // Close loading
                      //
                      //   // Show success dialog
                      //   showDialog(
                      //     context: context,
                      //     builder: (context) => AlertDialog(
                      //       title: const Row(
                      //         children: [
                      //           Icon(Icons.check_circle, color: Colors.green),
                      //           SizedBox(width: 8),
                      //           Text('Berhasil'),
                      //         ],
                      //       ),
                      //       content: Text(
                      //           'Pesanan berhasil dibuat!\nOrder ID: ${extraData['orderId']}'
                      //       ),
                      //       actions: [
                      //         TextButton(
                      //           onPressed: () {
                      //             Navigator.of(context).pop();
                      //             context.go('/gro-table-availability');
                      //           },
                      //           child: const Text('OK'),
                      //         ),
                      //       ],
                      //     ),
                      //   );
                      //
                      //   cartProvider.clearCart();
                      //   return; // Stop execution here for GRO mode
                      // }

                      // Normal user flow continues...
                      if (cartProvider.isOpenBill && cartProvider.openBillData != null) {
                        extraData['isOpenBill'] = true;
                        extraData['openBillData'] = cartProvider.openBillData;
                        extraData['existingReservation'] = orderResult['existingReservation'];
                      }

                      if (cartProvider.isReservation && cartProvider.reservationData != null) {
                        extraData['reservationData'] = cartProvider.reservationData;
                        extraData['isReservation'] = true;
                        extraData['paymentType'] = selectedPaymentType;
                        extraData['downPaymentAmount'] = downPaymentAmount;

                        if (_shouldShowReservationType(cartProvider.reservationData!.areaCode)) {
                          extraData['reservationType'] = selectedReservationType;
                          extraData['isBlocking'] = selectedReservationType == ReservationType.blocking;
                        }

                        if (selectedPaymentType == PaymentType.downPayment) {
                          extraData['remainingPayment'] = finalTotal - downPaymentAmount;
                          extraData['isDownPayment'] = true;
                        } else {
                          extraData['remainingPayment'] = 0;
                          extraData['isDownPayment'] = false;
                        }
                      } else {
                        extraData['remainingPayment'] = 0;
                        extraData['isDownPayment'] = false;
                      }

                      context.push('/paymentConfirmation', extra: extraData);
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