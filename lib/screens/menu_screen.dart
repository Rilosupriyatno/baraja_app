import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/cart_item.dart'; // ✅ Import CartItem
import '../models/category.dart';
import '../models/product.dart';
import '../models/reservation_data.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../utils/base_screen_wrapper.dart';
import '../utils/gro_mode_badge.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/menu/product_grid.dart';
import '../widgets/menu/sub_menu_slider.dart';
import '../widgets/menu/menu_selector.dart';
import '../widgets/menu/search_menu_widget.dart'; // ✅ Import widget search
import '../widgets/cart/cart_item_edit_dialog.dart';

class MenuScreen extends StatefulWidget {
  final bool isReservation;
  final ReservationData? reservationData;
  final bool isDineIn;
  final String? tableNumber;
  final bool isOpenBill;
  final OpenBillData? openBillData;
  final bool isGroMode;

  const MenuScreen({
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
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  Map<String, List<Category>> _categoriesMap = {};

  String selectedMenu = 'Makanan';
  String selectedCategory = '';
  String _searchQuery = ''; // ✅ Tambah state untuk search

  bool _isLoading = true;
  String _errorMessage = '';

  // ✅ State untuk tablet layout (GRO mode)
  Product? _selectedProduct; // Product yang dipilih untuk order form
  int _selectedQuantity = 1; // Quantity untuk product yang dipilih
  final TextEditingController _notesController = TextEditingController();

  // Addon & Topping states
  Map<String, AddonOption?> _selectedAddonOptions = {};
  List<Topping> _selectedToppings = [];

  // ✅ FIX: Controllers untuk custom amount form - pindah ke class level
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _customDescriptionController = TextEditingController();
  final GlobalKey<FormState> _customAmountFormKey = GlobalKey<FormState>();

  // Helper to calculate total
  double _calculateTotal() {
    if (_selectedProduct == null) return 0;

    double basePrice =
        _selectedProduct!.discountPrice ?? _selectedProduct!.originalPrice ?? 0;
    double toppingsTotal =
        _selectedToppings.fold(0, (sum, topping) => sum + topping.price);

    double addonOptionsTotal = 0;
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price;
      }
    });

    return (basePrice + toppingsTotal + addonOptionsTotal) * _selectedQuantity;
  }

  // Helper to reset selection and init defaults
  void _resetSelection(Product product) {
    setState(() {
      _selectedProduct = product;
      _selectedQuantity = 1;
      _selectedAddonOptions.clear();
      _selectedToppings.clear();
      _notesController.clear();

      // Init default addons
      if (product.addons != null) {
        for (var addon in product.addons!) {
          if (addon.options.isNotEmpty) {
            var defaultOption =
                addon.options.where((o) => o.isDefault).firstOrNull;
            defaultOption ??= addon.options.first;
            _selectedAddonOptions[addon.id] = defaultOption;
          }
        }
      }
    });
  }

  // Helper to show edit dialog
  void _showEditItemDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => CartItemEditDialog(
        item: item,
        onSave: (updatedItem) {
          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);
          int index = cartProvider.items.indexOf(item);
          if (index != -1) {
            cartProvider.updateCartItem(index, updatedItem);
          }
        },
      ),
    );
  } // Notes controller

  bool _showCustomAmountForm = false; // Toggle untuk custom amount form

  @override
  void initState() {
    super.initState();
    _loadProducts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // ⭐ PERBAIKAN KRITIS: Set GRO mode terlebih dahulu
      if (widget.isGroMode) {
        cartProvider.setGroMode(true);
        debugPrint('📱 MenuScreen: GRO Mode activated');
      } else {
        // Jika mode user, pastikan cart provider tidak dalam mode GRO
        if (cartProvider.isGroMode) {
          debugPrint('⚠️ MenuScreen: Clearing GRO mode for user access');
          cartProvider.clearContext();
        }
      }

      // Set data sesuai parameter dengan validasi mode
      if (widget.isReservation && widget.reservationData != null) {
        cartProvider.setReservationData(
            widget.isReservation, widget.reservationData);
      } else if (widget.isDineIn && widget.tableNumber != null) {
        cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
      } else if (widget.isOpenBill && widget.openBillData != null) {
        cartProvider.setOpenBillData(widget.isOpenBill, widget.openBillData);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customNameController.dispose();
    _customAmountController.dispose();
    _customDescriptionController.dispose();
    super.dispose();
  }

  // void initState() {
  //   super.initState();
  //   _loadProducts();
  //   print(widget.reservationData);
  //   print("ini adalah data open bill: ${widget.openBillData}");
  //   print("GRO Mode: ${widget.isGroMode}");
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final cartProvider = Provider.of<CartProvider>(context, listen: false);
  //
  //     if (widget.isReservation && widget.reservationData != null) {
  //       cartProvider.setReservationData(widget.isReservation, widget.reservationData);
  //     } else if (widget.isDineIn && widget.tableNumber != null) {
  //       cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
  //     } else if (widget.isOpenBill && widget.openBillData != null) {
  //       cartProvider.setOpenBillData(widget.isOpenBill, widget.openBillData);
  //     }
  //   });
  // }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final products = await _productService.getProducts();

      setState(() {
        _allProducts = products;
        _generateCategoriesMap(products);
        _setInitialSelections();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat produk: ${e.toString()}';
      });
      debugPrint('Error in _loadProducts: $e');
    }
  }

  void _generateCategoriesMap(List<Product> products) {
    try {
      Map<String, Set<String>> tempCategoriesMap = {};

      for (var product in products) {
        String mainCategory = product.mainCategory;
        String category = product.category ?? 'Lainnya';

        if (!tempCategoriesMap.containsKey(mainCategory)) {
          tempCategoriesMap[mainCategory] = <String>{};
        }

        tempCategoriesMap[mainCategory]!.add(category);
      }

      _categoriesMap = {};
      tempCategoriesMap.forEach((mainCategory, categories) {
        _categoriesMap[mainCategory] =
            categories.map((name) => Category(name: name)).toList();
      });

      debugPrint("Generated categories: $_categoriesMap");
    } catch (e) {
      debugPrint("Error in _generateCategoriesMap: $e");
      _categoriesMap = {
        'Makanan': [Category(name: 'Pasta')],
        'Minuman': [Category(name: 'Frappe')]
      };
    }
  }

  // ✅ Update filter products dengan search functionality
  List<Product> _getFilteredProducts() {
    // ✅ Check if tablet GRO mode
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;
    final isGroTabletMode = widget.isGroMode && isTablet;

    return _allProducts.where((product) {
      // Filter by search query first
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesCategory =
            product.category?.toLowerCase().contains(query) ?? false;
        final matchesDescription =
            product.description.toLowerCase().contains(query);

        return matchesName || matchesCategory || matchesDescription;
      }

      // ✅ In tablet GRO mode, show ALL products (no category filter)
      if (isGroTabletMode) {
        return true;
      }

      // Filter by mainCategory (Makanan/Minuman) - for mobile mode
      if (product.mainCategory != selectedMenu) {
        return false;
      }

      // Jika tidak ada category yang dipilih, tampilkan semua
      if (selectedCategory.isEmpty) {
        return true;
      }

      // Filter by category
      return product.category == selectedCategory;
    }).toList();
  }

  void _setInitialSelections() {
    if (_categoriesMap.isNotEmpty) {
      if (_categoriesMap.containsKey('Makanan')) {
        selectedMenu = 'Makanan';
      } else if (_categoriesMap.containsKey('Minuman')) {
        selectedMenu = 'Minuman';
      } else {
        selectedMenu = _categoriesMap.keys.first;
      }

      if (_categoriesMap[selectedMenu]!.isNotEmpty) {
        selectedCategory = _categoriesMap[selectedMenu]![0].name;
      }
    }
  }

  // ✅ Handler untuk search
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // ✅ Handler untuk clear search
  void _onClearSearch() {
    setState(() {
      _searchQuery = '';
    });
  }

  List<Product> _getDummyProducts() {
    return List.generate(
      6,
      (index) => Product(
        id: 'dummy_$index',
        name: 'Loading Product Name',
        category: 'Loading',
        mainCategory: 'Loading',
        subCategory: null,
        imageUrl: '',
        originalPrice: 50000.0,
        discountPrice: 45000.0,
        description: 'Loading description',
        discountPercentage: '10%',
        toppings: [],
        addons: [],
        averageRating: 4.5,
        reviewCount: 100,
        availableAt: [
          Outlet(
            outletId: 'dummy_outlet',
            name: 'Loading Outlet',
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo() {
    if (!widget.isReservation || widget.reservationData == null) {
      return const SizedBox.shrink();
    }

    final data = widget.reservationData!;

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
          Row(
            children: [
              Icon(Icons.restaurant_menu,
                  color: Colors.orange.shade700, size: 18),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '📅 ${data.formattedDate}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '🕐 ${data.formattedTime}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildOpenBillInfo() {
    if (!widget.isOpenBill || widget.openBillData == null) {
      return const SizedBox.shrink();
    }

    final data = widget.openBillData!;

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
          Row(
            children: [
              Icon(Icons.restaurant_menu,
                  color: Colors.orange.shade700, size: 18),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '📅 ${DateFormat('yyyy-MM-dd').format(data.date)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '🕐 ${data.time.hour}:${data.time.minute.toString().padLeft(2, '0')}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildDineInInfo() {
    if (!widget.isDineIn || widget.tableNumber == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dine In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'Meja ${widget.tableNumber!.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget untuk menampilkan hasil search
  Widget _buildSearchResultsInfo() {
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    final filteredProducts = _getFilteredProducts();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ditemukan ${filteredProducts.length} hasil untuk "$_searchQuery"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBackRoute() {
    if (widget.isGroMode) {
      return '/gro-dashboard';
    } else {
      return '/main';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;
    final isGroTabletMode = widget.isGroMode && isTablet;

    // ✅ Route ke tablet layout jika GRO mode di tablet
    if (isGroTabletMode) {
      return _buildTabletLayout();
    }

    // ✅ Layout mobile (existing)
    return _buildMobileLayout();
  }

  // ✅ MOBILE LAYOUT (existing code)
  Widget _buildMobileLayout() {
    final List<Category> categoryList = _categoriesMap[selectedMenu] ?? [];
    final List<Product> filteredProducts =
        _isLoading ? _getDummyProducts() : _getFilteredProducts();

    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: _getBackRoute(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go(_getBackRoute()),
          ),
          // ✅ TITLE DENGAN BADGE GRO
          title: Row(
            children: [
              Text(
                widget.isReservation
                    ? 'Menu Reservasi'
                    : widget.isDineIn
                        ? 'Menu Dine In'
                        : 'Menu',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.isGroMode) ...[
                const SizedBox(width: 12),
                const GroModeAppBarBadge(), // ✅ Badge di AppBar
              ],
            ],
          ),
          // ✅ TAMBAH TOMBOL + DI APPBAR UNTUK GRO MODE
          actions: widget.isGroMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: () {
                      context.push('/custom-amount', extra: {
                        'isGroMode': true,
                      });
                    },
                    tooltip: 'Penyesuaian',
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    // ✅ BANNER GRO MODE (Optional - bisa dihilangkan jika tidak perlu)
                    if (widget.isGroMode) _buildReservationInfo(),
                    _buildOpenBillInfo(),
                    _buildDineInInfo(),

                    // Search Widget
                    SearchMenuWidget(
                      onSearchChanged: _onSearchChanged,
                      onClearSearch: _onClearSearch,
                    ),

                    // Search Results Info
                    _buildSearchResultsInfo(),

                    // Menu selector & category slider (hidden saat search aktif)
                    if (_searchQuery.isEmpty) ...[
                      MenuSelector(
                        selectedMenu: selectedMenu,
                        onMenuSelected: (menu) {
                          setState(() {
                            selectedMenu = menu;
                            if (_categoriesMap[menu]!.isNotEmpty) {
                              selectedCategory = _categoriesMap[menu]![0].name;
                            }
                          });
                        },
                      ),
                      SubMenuSlider(
                        subMenus: categoryList,
                        selectedSubMenu: selectedCategory,
                        onSubMenuSelected: (category) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                      ),
                    ],

                    Expanded(
                      child: Skeletonizer(
                        enabled: _isLoading,
                        enableSwitchAnimation: true,
                        child: filteredProducts.isEmpty && !_isLoading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada menu yang ditemukan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Coba kata kunci lain'
                                          : 'Belum ada menu tersedia',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ProductGrid(products: filteredProducts),
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: CheckoutButton(
          isReservation: widget.isReservation,
          reservationData: widget.reservationData,
          isDineIn: widget.isDineIn,
          tableNumber: widget.tableNumber,
          isOpenBill: widget.isOpenBill,
          openBillData: widget.openBillData,
          isGroMode: widget.isGroMode,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // floatingActionButton: CheckoutButton(
        //   isReservation: widget.isReservation,
        //   reservationData: widget.reservationData,
        //   isDineIn: widget.isDineIn,
        //   tableNumber: widget.tableNumber,
        //   isOpenBill: widget.isOpenBill,
        //   openBillData: widget.openBillData,
        //   isGroMode: widget.isGroMode,
        // ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final List<Category> categoryList = _categoriesMap[selectedMenu] ?? [];
  //   final List<Product> filteredProducts = _isLoading
  //       ? _getDummyProducts()
  //       : _getFilteredProducts();
  //
  //   return BaseScreenWrapper(
  //     canPop: false,
  //     customBackRoute: _getBackRoute(),
  //     child: Scaffold(
  //       backgroundColor: Colors.white,
  //       appBar: ClassicAppBar(
  //         title: _getAppBarTitle(),
  //         customBackRoute: _getBackRoute(),
  //       ),
  //       body: SafeArea(
  //         child: _errorMessage.isNotEmpty
  //             ? Center(child: Text(_errorMessage))
  //             : Column(
  //           children: [
  //             _buildReservationInfo(),
  //             _buildOpenBillInfo(),
  //             _buildDineInInfo(),
  //
  //             // ✅ Search Widget
  //             SearchMenuWidget(
  //               onSearchChanged: _onSearchChanged,
  //               onClearSearch: _onClearSearch,
  //             ),
  //
  //             // ✅ Search Results Info
  //             _buildSearchResultsInfo(),
  //
  //             // ✅ Hide menu selector & category slider saat search aktif
  //             if (_searchQuery.isEmpty) ...[
  //               MenuSelector(
  //                 selectedMenu: selectedMenu,
  //                 onMenuSelected: (menu) {
  //                   setState(() {
  //                     selectedMenu = menu;
  //                     if (_categoriesMap[menu]!.isNotEmpty) {
  //                       selectedCategory = _categoriesMap[menu]![0].name;
  //                     }
  //                   });
  //                 },
  //               ),
  //               SubMenuSlider(
  //                 subMenus: categoryList,
  //                 selectedSubMenu: selectedCategory,
  //                 onSubMenuSelected: (category) {
  //                   setState(() {
  //                     selectedCategory = category;
  //                   });
  //                 },
  //               ),
  //             ],
  //
  //             Expanded(
  //               child: Skeletonizer(
  //                 enabled: _isLoading,
  //                 enableSwitchAnimation: true,
  //                 child: filteredProducts.isEmpty && !_isLoading
  //                     ? Center(
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Icon(
  //                         Icons.search_off,
  //                         size: 64,
  //                         color: Colors.grey.shade400,
  //                       ),
  //                       const SizedBox(height: 16),
  //                       Text(
  //                         'Tidak ada menu yang ditemukan',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           color: Colors.grey.shade600,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         _searchQuery.isNotEmpty
  //                             ? 'Coba kata kunci lain'
  //                             : 'Belum ada menu tersedia',
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.grey.shade500,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 )
  //                     : ProductGrid(products: filteredProducts),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       floatingActionButton: CheckoutButton(
  //         isReservation: widget.isReservation,
  //         reservationData: widget.reservationData,
  //         isDineIn: widget.isDineIn,
  //         tableNumber: widget.tableNumber,
  //         isOpenBill: widget.isOpenBill,
  //         openBillData: widget.openBillData,
  //         isGroMode: widget.isGroMode,
  //       ),
  //     ),
  //   );
  // }

  // ==================== TABLET LAYOUT (GRO MODE) ====================

  Widget _buildTabletLayout() {
    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: _getBackRoute(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go(_getBackRoute()),
          ),
          title: Row(
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const GroModeAppBarBadge(),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                // ✅ Show custom amount form in column 2
                setState(() {
                  _selectedProduct = null; // Clear product selection
                  _showCustomAmountForm = true; // Show custom amount form
                });
              },
              tooltip: 'Penyesuaian',
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: Row(
            children: [
              // ✅ COLUMN 1: Menu List (32% - smaller)
              Expanded(
                flex: 32,
                child: _buildMenuColumn(),
              ),
              const VerticalDivider(width: 1, thickness: 1),

              // ✅ COLUMN 2: Order Form (36% - larger)
              Expanded(
                flex: 36,
                child: _buildOrderFormColumn(),
              ),
              const VerticalDivider(width: 1, thickness: 1),

              // ✅ COLUMN 3: Cart (32% - larger)
              Expanded(
                flex: 32,
                child: _buildCartColumn(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ COLUMN 1: Menu List
  Widget _buildMenuColumn() {
    final List<Product> filteredProducts =
        _isLoading ? _getDummyProducts() : _getFilteredProducts();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Info banners + search
          Flexible(
            flex: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReservationInfo(),
                _buildOpenBillInfo(),
                _buildDineInInfo(),

                // Search bar - reduced padding to prevent overflow
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SearchMenuWidget(
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: _onClearSearch,
                  ),
                ),

                // Search results info
                _buildSearchResultsInfo(),
              ],
            ),
          ),

          // Menu grid (NO CATEGORIES in tablet GRO mode) - 3 COLUMNS
          Expanded(
            child: Skeletonizer(
              enabled: _isLoading,
              enableSwitchAnimation: true,
              child: filteredProducts.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada menu yang ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // ✅ 3 columns for more items
                        childAspectRatio:
                            0.85, // ✅ Wider/shorter cards (was 0.7)
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildCompactMenuCard(filteredProducts[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Compact Menu Card untuk tablet
  Widget _buildCompactMenuCard(Product product) {
    final isSelected = _selectedProduct?.id == product.id;
    final hasValidImage = product.imageUrl != null &&
        product.imageUrl.isNotEmpty &&
        product.imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () => _resetSelection(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E8B57) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E8B57).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image - compact
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                child: hasValidImage
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/product_default_image.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/product_default_image.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
              ),
            ),

            // Product info - very compact
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(
                        product.discountPrice ?? product.originalPrice ?? 0),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF2E8B57),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ COLUMN 2: Order Form
  Widget _buildOrderFormColumn() {
    // ✅ Show custom amount form if flag is true
    if (_showCustomAmountForm) {
      return _buildCustomAmountForm();
    }

    // ✅ Show placeholder if no product selected
    if (_selectedProduct == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Pilih menu untuk menambah pesanan',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Product Order Form - with FIXED button at bottom
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedProduct!.imageUrl.isNotEmpty
                        ? Image.network(
                            _selectedProduct!.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/product_default_image.png',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/product_default_image.png',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    _selectedProduct!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Product Price
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(_selectedProduct!.discountPrice ??
                        _selectedProduct!.originalPrice ??
                        0),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2E8B57),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quantity selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jumlah Pesanan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: _selectedQuantity > 1
                                  ? Colors.red
                                  : Colors.grey,
                              onPressed: _selectedQuantity > 1
                                  ? () => setState(() => _selectedQuantity--)
                                  : null,
                            ),
                            Text(
                              '$_selectedQuantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF2E8B57),
                              onPressed: () =>
                                  setState(() => _selectedQuantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ ADDONS Section
                  if (_selectedProduct!.addons != null &&
                      _selectedProduct!.addons!.isNotEmpty) ...[
                    ...(_selectedProduct!.addons!.map((addon) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addon.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: addon.options.map((option) {
                                bool isSelected =
                                    _selectedAddonOptions[addon.id] == option;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedAddonOptions.remove(addon.id);
                                      } else {
                                        _selectedAddonOptions[addon.id] =
                                            option;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2E8B57)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '${option.label} ${option.price > 0 ? "+${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(option.price)}" : ""}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ))),
                  ],

                  // ✅ TOPPINGS Section
                  if (_selectedProduct!.toppings != null &&
                      _selectedProduct!.toppings!.isNotEmpty) ...[
                    const Text(
                      'Extra Toppings',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedProduct!.toppings!
                        .map((topping) => CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(topping.name,
                                  style: const TextStyle(fontSize: 13)),
                              secondary: Text(
                                NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp',
                                        decimalDigits: 0)
                                    .format(topping.price),
                                style: const TextStyle(
                                    color: Color(0xFF2E8B57),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                              value: _selectedToppings.contains(topping),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedToppings.add(topping);
                                  } else {
                                    _selectedToppings.remove(topping);
                                  }
                                });
                              },
                              activeColor: const Color(0xFF2E8B57),
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
                    const SizedBox(height: 8),
                  ],

                  // Notes
                  const Text(
                    'Catatan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E8B57), width: 2),
                      ),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // ✅ FIXED Footer with Total & Add Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Harga',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    Text(
                      NumberFormat.currency(
                              locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                          .format(_calculateTotal()),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E8B57)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);

                      List<Map<String, dynamic>> toppingsList =
                          _selectedToppings
                              .map((t) => {
                                    "name": t.name,
                                    "price": t.price,
                                  })
                              .toList();

                      List<Map<String, dynamic>> addonList = [];
                      _selectedAddonOptions.forEach((addonId, option) {
                        if (option != null) {
                          var addon = _selectedProduct!.addons!
                              .firstWhere((a) => a.id == addonId);
                          addonList.add({
                            "name": addon.name,
                            "label": option.label,
                            "price": option.price,
                          });
                        }
                      });

                      final cartItem = CartItem(
                        id: _selectedProduct!.id,
                        name: _selectedProduct!.name,
                        imageUrl: _selectedProduct!.imageUrl,
                        price: (_selectedProduct!.discountPrice ??
                                _selectedProduct!.originalPrice ??
                                0)
                            .toInt(),
                        totalprice: _calculateTotal().toInt(),
                        quantity: _selectedQuantity,
                        addons: addonList,
                        toppings: toppingsList,
                        notes: _notesController.text,
                      );

                      cartProvider.addToCart(cartItem);

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(
                      //         '${_selectedProduct!.name} ditambahkan ke keranjang'),
                      //     duration: const Duration(seconds: 1),
                      //     backgroundColor: const Color(0xFF2E8B57),
                      //   ),
                      // );

                      _resetSelection(_selectedProduct!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Tambah Order',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Custom Amount Form (Inline)
  Widget _buildCustomAmountForm() {
    // ✅ FIX: Gunakan class-level controllers untuk menghindari keyboard hilang

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _customAmountFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Penyesuaian',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showCustomAmountForm = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tambahkan biaya tambahan atau penyesuaian',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Nama Item
              const Text(
                'Nama Item',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customNameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Biaya Layanan',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2E8B57), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Jumlah
              const Text(
                'Jumlah (Rp)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customAmountController,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixText: 'Rp ',
                  prefixStyle:
                      const TextStyle(color: Colors.black87, fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2E8B57), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  final amount = int.tryParse(
                      value.replaceAll('.', '').replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Deskripsi
              const Text(
                'Deskripsi (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customDescriptionController,
                decoration: InputDecoration(
                  hintText: 'Tambahkan keterangan',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF2E8B57), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_customAmountFormKey.currentState!.validate()) {
                      return;
                    }

                    final cartProvider =
                        Provider.of<CartProvider>(context, listen: false);
                    final amountStr = _customAmountController.text
                        .replaceAll('.', '')
                        .replaceAll(',', '');
                    final amount = int.tryParse(amountStr) ?? 0;

                    if (amount == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jumlah harus lebih dari 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create custom amount cart item
                    final customAmountItem = CartItem.customAmount(
                      name: _customNameController.text.trim(),
                      amount: amount,
                      description: _customDescriptionController.text.trim().isEmpty
                          ? null
                          : _customDescriptionController.text.trim(),
                      dineType: 'Dine-In',
                    );

                    // Add to cart
                    cartProvider.addToCart(customAmountItem);

                    // Show success message
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text(
                      //         '${_customNameController.text} ditambahkan ke keranjang'),
                      //     backgroundColor: const Color(0xFF2E8B57),
                      //     duration: const Duration(seconds: 2),
                      //   ),
                      // );

                    // Clear form dan close
                    _customNameController.clear();
                    _customAmountController.clear();
                    _customDescriptionController.clear();

                    // Close form
                    setState(() {
                      _showCustomAmountForm = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tambahkan ke Keranjang',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ COLUMN 3: Cart (Using existing CartScreen body)
  Widget _buildCartColumn() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cartItems = cartProvider.items;
        final isReservation = cartProvider.isReservation;
        final reservationData = cartProvider.reservationData;
        final isDineIn = cartProvider.isDineIn;
        final tableNumber = cartProvider.tableNumber;
        final isOpenBill = cartProvider.isOpenBill;
        final openBillData = cartProvider.openBillData;
        final isGroMode = cartProvider.isGroMode;

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header - Changed to white/gray theme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Keranjang',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${cartProvider.totalItems}',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cart items list
              Expanded(
                child: cartItems.isEmpty
                    ? SingleChildScrollView(
                        // ✅ FIXED: Prevents overflow when keyboard appears
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang kosong',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tambahkan menu',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          // Build addons text
                          String addonsText = '';
                          if (item.addons.isNotEmpty) {
                            addonsText = item.addons
                                .map((addon) => addon['label'] ?? addon['name'])
                                .join(', ');
                          }

                          // Build toppings text
                          String toppingsText = '';
                          if (item.toppings is List &&
                              (item.toppings as List).isNotEmpty) {
                            toppingsText = (item.toppings as List)
                                .map((topping) => topping['name'])
                                .join(', ');
                          }

                          // ✅ Redesigned cart item with white+shadow
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product info row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image - small
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: item.imageUrl.isNotEmpty
                                          ? Image.network(
                                              item.imageUrl,
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/product_default_image.png',
                                                  width: 45,
                                                  height: 45,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              'assets/images/product_default_image.png',
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // ✅ Edit button
                                              IconButton(
                                                icon: Icon(Icons.edit_outlined,
                                                    size: 16,
                                                    color:
                                                        Colors.grey.shade600),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    _showEditItemDialog(item),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp',
                                              decimalDigits: 0,
                                            ).format(item.totalprice),
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

                                // Quantity controls (inline)
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Quantity controls
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => cartProvider
                                              .decreaseQuantity(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.remove,
                                                size: 16,
                                                color: Colors.red.shade400),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => cartProvider
                                              .increaseQuantity(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(Icons.add,
                                                size: 16,
                                                color: Colors.green.shade600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Total for this item
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'id_ID',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(item.totalprice * item.quantity),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),

                                // Addons/Toppings/Notes (scrollable if needed)
                                if (addonsText.isNotEmpty ||
                                    toppingsText.isNotEmpty ||
                                    (item.notes != null &&
                                        item.notes!.isNotEmpty)) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (addonsText.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.add_circle_outline,
                                                  size: 12,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  addonsText,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (toppingsText.isNotEmpty) ...[
                                          if (addonsText.isNotEmpty)
                                            const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.local_pizza_outlined,
                                                  size: 12,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  toppingsText,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (item.notes != null &&
                                            item.notes!.isNotEmpty) ...[
                                          if (addonsText.isNotEmpty ||
                                              toppingsText.isNotEmpty)
                                            const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.note_outlined,
                                                  size: 12,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item.notes!,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontStyle:
                                                          FontStyle.italic),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Footer with total and checkout - FIXED at bottom
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(cartProvider.totalPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cartItems.isEmpty
                            ? null
                            : () {
                                // Navigate to checkout screen
                                Map<String, dynamic> extraData = {
                                  'isGroMode': isGroMode
                                };

                                if (isReservation && reservationData != null) {
                                  extraData['isReservation'] = true;
                                  extraData['reservationData'] =
                                      reservationData;
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
                                  context.go('/checkout',
                                      extra: {'isGroMode': isGroMode});
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lanjut Bayar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
