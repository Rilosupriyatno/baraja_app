import 'package:baraja_app/utils/base_screen_wrapper.dart';
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
import '../services/calculation_service.dart';
import '../services/auth_service.dart';

import '../utils/gro_mode_badge.dart';
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

enum ReservationType { nonBlocking, blocking }

class CheckoutPage extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;
  final bool isOpenBill;
  final OpenBillData? openBillData;
  final bool isGroMode;

  const CheckoutPage({
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
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late OrderType selectedOrderType;
  String? outletId;
  late String tableNumber;
  String deliveryAddress = "";
  TimeOfDay? pickupTime;
  String? selectedPaymentMethod;
  String? selectedPaymentMethodName;
  String? selectedBankName;
  String? selectedBankCode;
  String? selectedVoucherCode;
  Voucher? selectedVoucher;
  String voucherDescription = "";
  int discountAmount = 0;
  PaymentType selectedPaymentType = PaymentType.fullPayment;
  ReservationType selectedReservationType = ReservationType.nonBlocking;
  Map<String, String> validationErrors = {};
  bool hasAttemptedSubmit = false;

  // ✅ NEW: Manual DP and Tax toggle for GRO
  bool _enableManualDP = false;
  int? _manualDPAmount;
  // bool _enableTax = true; // Tax will be always enabled for specific conditions
  final TextEditingController _manualDPController = TextEditingController();

  final TaxService _taxService = TaxService();
  final TableService _tableService = TableService();
  TaxCalculationResult? _taxCalculation;
  bool _taxesLoaded = false;

  int? _lastCalculatedSubtotal;
  int? _lastCalculatedDiscount;
  String? _lastCalculatedOutletId;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _deliveryAddressKey = GlobalKey();
  final GlobalKey _pickupTimeKey = GlobalKey();
  final GlobalKey _tableNumberKey = GlobalKey();
  final GlobalKey _paymentMethodKey = GlobalKey();
  final GlobalKey _reservationTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedOrderType = OrderType.dineIn;
    tableNumber = "";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      cartProvider.addListener(_onCartChanged);

      // 🔍 NEW: Get Outlet ID from logged in user (GRO) as fallback
      String? userOutletId;
      try {
        final userOutlets = authService.getUserOutlets();
        if (userOutlets.isNotEmpty) {
          final firstOutlet = userOutlets.first;
          print("🔍 CHECKOUT: Checking user outlet data: $firstOutlet");
          
          if (firstOutlet['outletId'] is Map && firstOutlet['outletId'].containsKey('_id')) {
            userOutletId = firstOutlet['outletId']['_id']?.toString();
            print("✅ CHECKOUT: Found outletId from user relation: $userOutletId");
          } else if (firstOutlet.containsKey('_id')) {
            userOutletId = firstOutlet['_id']?.toString();
            print("✅ CHECKOUT: Found outletId from direct object: $userOutletId");
          }
        }
      } catch (e) {
        print("❌ CHECKOUT: Error getting user outlet: $e");
      }

      if (_isReservationWithoutMenu(cartProvider)) {
        setState(() {
          selectedPaymentType = PaymentType.fullPayment;
        });
      }

      if (cartProvider.items.isNotEmpty) {
        final firstItem = cartProvider.items.first;
        print("🔍 DEBUG: First cart item:");
        print("  - name: ${firstItem.name}");
        print("  - outletId: ${firstItem.outletId}");
        print("  - outletName: ${firstItem.outletName}");
        
        setState(() {
          // ✅ FIX: Use item outletId if available, otherwise fallback to userOutletId
          outletId = firstItem.outletId?.toString() ?? userOutletId;
        });
        print("✅ OutletId set to: $outletId (User fallback: ${userOutletId != null})");
        
        if (outletId == null) {
          print("⚠️ WARNING: Cart has items but outletId is null!");
          print("⚠️ This will prevent tax calculation!");
        }
      } else {
        // If cart is empty, use user outlet ID if available
        if (userOutletId != null) {
          setState(() {
            outletId = userOutletId;
          });
          print("✅ Cart empty, using user OutletId: $outletId");
        } else {
          print("⚠️ Cart is empty and no user outletId available");
        }
      }

      if (cartProvider.isReservation) {
        // For reservations, we'll use a special handling in the UI
      } else if (cartProvider.isDineIn && cartProvider.tableNumber != null) {
        selectedOrderType = OrderType.dineIn;
        tableNumber = cartProvider.tableNumber!;
      } else {
        tableNumber = "";
      }

      _initializeTaxData();
      setState(() {});
    });
  }

  void _onCartChanged() {
    if (!mounted) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (cartProvider.items.isNotEmpty) {
      String? newOutletId = cartProvider.items.first.outletId?.toString();
      
      // ✅ Fallback to user outlet ID if cart item has no outlet ID
      if (newOutletId == null) {
         try {
            final userOutlets = authService.getUserOutlets();
            if (userOutlets.isNotEmpty) {
              final firstOutlet = userOutlets.first;
              if (firstOutlet['outletId'] is Map && firstOutlet['outletId'].containsKey('_id')) {
                newOutletId = firstOutlet['outletId']['_id']?.toString();
              } else if (firstOutlet.containsKey('_id')) {
                newOutletId = firstOutlet['_id']?.toString();
              }
            }
         } catch(e) {
           print("Error getting fallback outlet in listener: $e");
         }
      }
      
      if (newOutletId != outletId) {
        setState(() {
          outletId = newOutletId;
        });
        print("🔄 OutletId updated to: $outletId");
      }
    }

    if (_taxesLoaded && outletId != null) {
      _calculateTaxes();
    } else {
      print(
          "⚠️ Cannot calculate taxes: taxesLoaded=$_taxesLoaded, outletId=$outletId");
    }
  }

  bool _isReservationWithoutMenu(CartProvider cartProvider) {
    return cartProvider.isReservation &&
        cartProvider.items.isEmpty &&
        cartProvider.totalPrice == 25000;
  }

  Future<void> _initializeTaxData() async {
    try {
      print("🔄 Initializing tax data...");
      await _taxService.getTaxesAndServices();
      setState(() {
        _taxesLoaded = true;
      });
      print("✅ Tax data loaded successfully");

      if (outletId != null) {
        print("📊 Calculating taxes with outletId: $outletId");
        _calculateTaxes();
      } else {
        print("⚠️ OutletId is null, waiting for cart items");
      }
    } catch (e) {
      print('❌ Error initializing tax data: $e');
      setState(() {
        _taxesLoaded = true;
      });
    }
  }

// ✅ FIXED: Remove double counting
  void _calculateTaxes() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    print("\n🔍 DEBUG TAX CALCULATION:");
    print("  _taxesLoaded: $_taxesLoaded");
    print("  outletId: $outletId");

    if (!_taxesLoaded) {
      print("⚠️ Taxes not loaded yet, skipping calculation");
      return;
    }

    if (outletId == null) {
      print("⚠️ OutletId is null, skipping calculation");
      if (_taxCalculation != null) {
        setState(() {
          _taxCalculation = null;
        });
      }
      return;
    }

    // ✅ FIXED: Gunakan cartProvider.totalPrice yang sudah benar
    // Jangan hitung ulang karena akan double counting
    final subtotal = cartProvider.totalPrice;

    print("  Items in cart:");
    for (var item in cartProvider.items) {
      final itemTotal = cartProvider.getItemTotalPrice(item);
      print("    - ${item.name}: qty=${item.quantity}, total=$itemTotal");
    }

    final discount = calculateDiscount(subtotal);
    final finalTotal = subtotal - discount;

    if (_lastCalculatedSubtotal == subtotal &&
        _lastCalculatedDiscount == discount &&
        _lastCalculatedOutletId == outletId) {
      print("ℹ️ Values unchanged, skipping recalculation");
      return;
    }

    print("  subtotal (from cartProvider.totalPrice): $subtotal");
    print("  discount: $discount");
    print("  finalTotal: $finalTotal");

    try {
      final taxCalculation = _taxService.calculateTaxes(
        subtotal: finalTotal.toDouble(),
        outletId: outletId!,
        isReservation: cartProvider.isReservation,
        isOpenBill: cartProvider.isOpenBill,
      );

      print("  ✅ Tax calculation result:");
      print("    totalTaxAmount: ${taxCalculation.totalTaxAmount}");

      _lastCalculatedSubtotal = subtotal;
      _lastCalculatedDiscount = discount;
      _lastCalculatedOutletId = outletId;

      setState(() {
        _taxCalculation = taxCalculation;
      });

      print("✅ Tax state updated successfully\n");
    } catch (e) {
      print("❌ Error calculating taxes: $e");
    }
  }

  int calculateDiscount(int subtotal) {
    return CalculationService.calculateDiscount(
      subtotal: subtotal,
      voucher: selectedVoucher,
    );
  }


  @override
  void dispose() {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.removeListener(_onCartChanged);
    } catch (e) {
      // Ignore error if provider is already disposed
    }
    _scrollController.dispose();
    _manualDPController.dispose(); // ✅ NEW: Dispose manual DP controller
    super.dispose();
  }

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

    return selectedDateTime.isAfter(minimumTime) ||
        selectedDateTime.isAtSameMomentAs(minimumTime);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  bool _shouldShowReservationType(String? areaCode) {
    return areaCode == 'I' || areaCode == 'F';
  }

  bool _canSelectBlocking(String? areaCode, int totalAmount) {
    if (areaCode == 'I') {
      return totalAmount >= 3000000;
    } else if (areaCode == 'F') {
      return totalAmount >= 2000000;
    }
    return false;
  }

  int _getMinimumAmountForBlocking(String? areaCode) {
    if (areaCode == 'I') {
      return 3000000;
    } else if (areaCode == 'F') {
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
    return !cartProvider.isReservation &&
        !cartProvider.isDineIn &&
        !cartProvider.isOpenBill;
  }

  String _getOrderTypeTitle(CartProvider cartProvider) {
    if (cartProvider.isReservation) {
      return "Konfirmasi Pesanan Reservasi";
    } else if (cartProvider.isDineIn) {
      return "Konfirmasi Pesanan Dine In";
    } else if (cartProvider.isOpenBill) {
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

        // ✅ PERBAIKAN: Gunakan totalPrice dari cartProvider yang sudah benar
        // Sesuai dengan cart_screen.dart yang menggunakan cartProvider.totalPrice
        final int subtotal = cartProvider.totalPrice;

        final int discount = calculateDiscount(subtotal);
        final int finalTotal = subtotal - discount;
        
        // ✅ NEW: Tax calculation with toggle support
        // Disable tax for reservation without menu (only reservation fee)
        final bool isReservationOnly = _isReservationWithoutMenu(cartProvider);
        final bool enableTax = !isReservationOnly; 
        
        final int taxAmount = enableTax 
            ? (_taxCalculation?.totalTaxAmount.round() ?? 0)
            : 0;
        
        
        final int grandTotal = finalTotal + taxAmount;
        
        // ✅ NEW: Down payment with manual input support
        int downPaymentAmount;
        if (_enableManualDP && _manualDPAmount != null && _manualDPAmount! > 0) {
          downPaymentAmount = _manualDPAmount!;
        } else {
          downPaymentAmount = CalculationService.calculateDownPayment(grandTotal);
        }

        // Debug print untuk memastikan konsistensi
        print("\n💰 CHECKOUT CALCULATION (CONSISTENT):");
        print("  CartProvider.totalPrice: $subtotal");
        print("  Discount: $discount");
        print("  FinalTotal: $finalTotal");
        print("  Tax Enabled: $enableTax");
        print("  Tax: $taxAmount");
        print("  GrandTotal: $grandTotal");
        print("  Manual DP Enabled: $_enableManualDP");
        print("  Manual DP Amount: $_manualDPAmount");
        print("  DownPayment: $downPaymentAmount");
        print("  _taxCalculation: $_taxCalculation");
        print("  _taxCalculation?.taxDetails: ${_taxCalculation?.taxDetails}");
        print("  _taxCalculation?.totalTaxAmount: ${_taxCalculation?.totalTaxAmount}\n");

        // Debug print untuk memastikan perhitungan
        print("\n💰 CHECKOUT CALCULATION:");
        print("  Items count: ${cartItems.length}");
        for (var item in cartItems) {
          print(
              "  - ${item.name}: totalprice=${item.totalprice} x qty=${item.quantity} = ${item.totalprice * item.quantity}");
        }
        print("  Subtotal: $subtotal");
        print("  Discount: $discount");
        print("  FinalTotal: $finalTotal");
        print("  Tax: $taxAmount");
        print("  GrandTotal: $grandTotal\n");

        // Auto-set reservation type to non-blocking if blocking is not available
        if (cartProvider.isReservation &&
            cartProvider.reservationData != null &&
            _shouldShowReservationType(
                cartProvider.reservationData!.areaCode) &&
            !_canSelectBlocking(
                cartProvider.reservationData!.areaCode, grandTotal) &&
            selectedReservationType == ReservationType.blocking) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedReservationType = ReservationType.nonBlocking;
            });
          });
        }

        return BaseScreenWrapper(
          customBackRoute: widget.isGroMode ? '/menu' : '/cart',
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.isGroMode) {
                    // ✅ GRO tablet mode: back to menu with tablet layout
                    context.go('/menu', extra: {
                      'isGroMode': true,
                      'isReservation': cartProvider.isReservation,
                      'reservationData': cartProvider.reservationData,
                      'isOpenBill': cartProvider.isOpenBill,
                      'openBillData': cartProvider.openBillData,
                    });
                  } else {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/cart', extra: {
                        'isReservation': cartProvider.isReservation,
                        'reservationData': cartProvider.reservationData,
                        'isDineIn': cartProvider.isDineIn,
                        'tableNumber': cartProvider.tableNumber,
                        'isOpenBill': cartProvider.isOpenBill,
                        'openBillData': cartProvider.openBillData,
                      });
                    }
                  }
                },
              ),
              // ✅ TITLE DENGAN BADGE GRO
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pembayaran',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.isGroMode) const GroModeAppBarBadge(), // ✅ Badge di AppBar
                ],
              ),
            ),
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                Flexible( // ✅ Changed to Flexible to allow shrinking when keyboard appears
                  flex: 1,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cartProvider.isReservation &&
                              cartProvider.reservationData != null)
                            ReservationInfoWidget(
                                data: cartProvider.reservationData!),

                          if (cartProvider.isReservation &&
                              cartProvider.reservationData != null)
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

                          if (cartProvider.isOpenBill &&
                              cartProvider.openBillData != null)
                            OpenBillInfoWidget(
                                openBillData: cartProvider.openBillData!),

                          if (cartProvider.isDineIn) const DineInInfoWidget(),

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
                              onChanged: (type) =>
                                  setState(() => selectedOrderType = type),
                              tableNumber: tableNumber,
                              onTableNumberChanged: (val) =>
                                  setState(() => tableNumber = val),
                              deliveryAddress: deliveryAddress,
                              onDeliveryAddressChanged: (val) =>
                                  setState(() => deliveryAddress = val),
                              pickupTime: pickupTime,
                              onPickupTimeChanged: (time) =>
                                  setState(() => pickupTime = time),
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
                                  border:
                                      Border.all(color: Colors.blue.shade200),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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

                          // ✅ NEW: Manual DP Input for GRO Reservation
                          if (widget.isGroMode && cartProvider.isReservation && !_isReservationWithoutMenu(cartProvider)) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.edit_note, color: Colors.purple.shade600, size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Input DP Manual',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        value: _enableManualDP,
                                        activeColor: Colors.purple.shade600,
                                        onChanged: (value) {
                                          setState(() {
                                            _enableManualDP = value;
                                            if (!value) {
                                              _manualDPAmount = null;
                                              _manualDPController.clear();
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_enableManualDP) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _manualDPController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Jumlah DP',
                                        prefixText: 'Rp ',
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.purple.shade200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.purple.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                                        ),
                                        helperText: 'Kosongkan untuk menggunakan 50% otomatis',
                                        helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                          _manualDPAmount = cleanValue.isEmpty ? null : int.tryParse(cleanValue);
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Grand Total:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(grandTotal),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ✅ NEW: Tax Toggle for GRO (Reservation & Dine-In)
                          // Removed Tax Toggle - Always show Tax Info if applied
                          if (widget.isGroMode && _taxCalculation != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, color: Colors.orange.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pajak & Service',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '+${_formatCurrency(_taxCalculation!.totalTaxAmount.round())}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Switch removed
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          PaymentMethodWithValidation(
                            displayedPaymentMethod: displayedPaymentMethod,
                            errorMessage: hasAttemptedSubmit
                                ? validationErrors['paymentMethod']
                                : null,
                            isReservation: cartProvider.isReservation, // ✅ NEW
                            isGroMode: widget.isGroMode, // ✅ NEW
                            onMethodSelected: (result) {
                              setState(() {
                                selectedPaymentMethod =
                                    result['payment_method'];
                                selectedPaymentMethodName =
                                    result['payment_method_name'];
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
                  selectedPaymentType:
                      cartProvider.isReservation ? selectedPaymentType : null,
                  taxCalculation: _taxCalculation,
                  manualDownPaymentAmount: _manualDPAmount, // ✅ Pass manual DP
                  onCheckoutPressed: () async {
                    print("➡️ Tombol checkout ditekan");

                    setState(() {
                      hasAttemptedSubmit = true;
                    });

                    final validationResult =
                        await CheckoutValidator.validateForm(
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
                        validationErrors = Map<String, String>.from(
                            validationResult['errors']);
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

                    String? userId;
                    String userName;

                    if (widget.isGroMode) {
                      if (cartProvider.reservationData != null) {
                        userId = null;
                        userName = 'null';

                        print("🔍 GRO Mode - Using Guest Data:");
                        print("  Guest Name: $userName");
                      } else {
                        userId = null;
                        userName = 'Dine-In Guest';
                        print(
                            "⚠️ GRO Mode - No reservation data, using default");
                      }
                    } else {
                      userId = prefs.getString('userId');
                      userName = prefs.getString('userName') ?? 'Guest';

                      print("👤 Normal Mode - Using Logged In User:");
                      print("  User ID: $userId");
                      print("  User Name: $userName");
                    }

                    int amountToPay = grandTotal;
                    if (cartProvider.isReservation &&
                        selectedPaymentType == PaymentType.downPayment) {
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

                      // ✅ PERBAIKAN: Gunakan totalprice dari CartItem yang sudah termasuk addons & toppings
                      final List<Map<String, dynamic>> items = cartItems
                          .map((item) => {
                                'productId': item.id,
                                'productName': item.name,
                                'price': item.price, // base price saja
                                'quantity': item.quantity,
                                'addons': item.addons,
                                'toppings': item.toppings,
                                'notes': item.notes,
                                'outletId': item.outletId,
                                'outletName': item.outletName,
                                'totalprice': item
                                    .totalprice, // ✅ TAMBAHKAN: total per item (sudah include addons & toppings)
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
                        groId = prefs.getString('userId');
                        guestPhone = cartProvider.guestPhone;
                        guestName = cartProvider.guestName;

                        print("🔍 GRO Mode Checkout:");
                        print("  GRO ID: $groId");
                        print("  Guest Name: $guestName");
                        print("  Guest Phone: $guestPhone");
                      }

                      print(
                          "✅ Sebelum createOrder - Memulai pembuatan pesanan...");
                      print("  User ID: $userId");
                      print("  User Name: $userName");
                      print("  Order Type: ${finalOrderType.toString()}");
                      print("  Is GRO Mode: ${widget.isGroMode}");
                      print("  Subtotal yang dikirim: $subtotal");

                      final orderResult = await orderService.createOrder(
                        items: items,
                        userId: userId ?? 'guest',
                        userName: guestName ?? 'Guest',
                        orderType: finalOrderType,
                        outletId: outletId ?? '',
                        tableNumber: cartProvider.isDineIn
                            ? cartProvider.tableNumber
                            : (finalOrderType == OrderType.dineIn
                                ? tableNumber
                                : null),
                        deliveryAddress: finalOrderType == OrderType.delivery
                            ? deliveryAddress
                            : null,
                        pickupTime: finalOrderType == OrderType.pickup
                            ? pickupTime
                            : null,
                        paymentDetails: paymentDetails,
                        subtotal: subtotal,
                        discount: discount,
                        taxDetails: _taxCalculation?.taxDetails,
                        totalTax: taxAmount,
                        voucherCode: selectedVoucherCode,
                        reservationData: cartProvider.isReservation
                            ? cartProvider.reservationData
                            : null,
                        openBillData: cartProvider.openBillData,
                        reservationType: cartProvider.isReservation &&
                                cartProvider.reservationData != null &&
                                _shouldShowReservationType(
                                    cartProvider.reservationData!.areaCode)
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
                        'tableNumber': cartProvider.isDineIn
                            ? cartProvider.tableNumber
                            : cartProvider.isOpenBill
                                ? cartProvider.openBillData?.tableNumbers
                                : tableNumber,
                        'deliveryAddress': deliveryAddress,
                        'pickupTime': pickupTime,
                        'paymentDetails': paymentDetails,
                        'subtotal': subtotal,
                        'discount': discount,
                        'total': finalTotal,
                        'taxAmount': taxAmount,
                        'taxDetails': _taxCalculation?.taxDetails ?? [],
                        'grandTotal': grandTotal,
                        'paymentType': cartProvider.isReservation
                            ? selectedPaymentType
                            : null,
                        'amountToPay': amountToPay,
                        'voucherCode': selectedVoucherCode,
                        'id': orderResult['order']?['_id'] ?? '',
                        'orderId': orderResult['order']?['order_id'] ?? '',
                        'isGroMode': widget.isGroMode,
                      };

                      // ✅ FIX: Process open bill data for both GRO and customer flows
                      if (cartProvider.isOpenBill &&
                          cartProvider.openBillData != null) {
                        extraData['isOpenBill'] = true;
                        extraData['openBillData'] = cartProvider.openBillData;
                        extraData['existingReservation'] =
                            orderResult['existingReservation'];
                      }

                      // ✅ FIX: Process reservation/down payment data for BOTH GRO and customer flows
                      // Previously GRO mode returned early and skipped this logic
                      if (cartProvider.isReservation &&
                          cartProvider.reservationData != null) {
                        extraData['reservationData'] =
                            cartProvider.reservationData;
                        extraData['isReservation'] = true;
                        extraData['paymentType'] = selectedPaymentType;
                        extraData['downPaymentAmount'] = downPaymentAmount;

                        if (_shouldShowReservationType(
                            cartProvider.reservationData!.areaCode)) {
                          extraData['reservationType'] =
                              selectedReservationType;
                          extraData['isBlocking'] = selectedReservationType ==
                              ReservationType.blocking;
                        }

                        if (selectedPaymentType == PaymentType.downPayment) {
                          extraData['remainingPayment'] =
                              finalTotal - downPaymentAmount;
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
                          content:
                              Text('Gagal membuat pesanan: ${e.toString()}'),
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
