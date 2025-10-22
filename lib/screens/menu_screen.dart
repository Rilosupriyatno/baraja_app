import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/reservation_data.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../utils/base_screen_wrapper.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/menu/product_grid.dart';
import '../widgets/menu/sub_menu_slider.dart';
import '../widgets/menu/menu_selector.dart';
import '../widgets/utils/classic_app_bar.dart';

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
  Map<String, List<Category>> _categoriesMap = {}; // ✅ mainCategory → [categories]

  String selectedMenu = 'Makanan'; // ✅ mainCategory
  String selectedCategory = ''; // ✅ category (dulu selectedSubMenu)

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    print(widget.reservationData);
    print("ini adalah data open bill: ${widget.openBillData}");
    print("GRO Mode: ${widget.isGroMode}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (widget.isReservation && widget.reservationData != null) {
        cartProvider.setReservationData(widget.isReservation, widget.reservationData);
      } else if (widget.isDineIn && widget.tableNumber != null) {
        cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
      } else if (widget.isOpenBill && widget.openBillData != null) {
        cartProvider.setOpenBillData(widget.isOpenBill, widget.openBillData);
      }
    });
  }

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

  // ✅ Generate categories berdasarkan mainCategory
  void _generateCategoriesMap(List<Product> products) {
    try {
      Map<String, Set<String>> tempCategoriesMap = {};

      for (var product in products) {
        String mainCategory = product.mainCategory; // ✅ makanan/minuman
        String category = product.category ?? 'Lainnya'; // ✅ category name

        if (!tempCategoriesMap.containsKey(mainCategory)) {
          tempCategoriesMap[mainCategory] = <String>{};
        }

        tempCategoriesMap[mainCategory]!.add(category);
      }

      _categoriesMap = {};
      tempCategoriesMap.forEach((mainCategory, categories) {
        _categoriesMap[mainCategory] = categories
            .map((name) => Category(name: name))
            .toList();
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

  // ✅ Filter products berdasarkan mainCategory dan category
  List<Product> _getFilteredProducts() {
    return _allProducts.where((product) {
      // Filter by mainCategory (Makanan/Minuman)
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

  // Dummy products untuk skeleton
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

  String _getAppBarTitle() {
    if (widget.isGroMode) {
      return 'Menu (GRO Mode)';
    } else if (widget.isReservation) {
      return 'Menu Reservasi';
    } else if (widget.isDineIn) {
      return 'Menu Dine In';
    } else {
      return 'Menu';
    }
  }

  String _getBackRoute() {
    if (widget.isGroMode) {
      return '/gro-table-availability';
    } else {
      return '/main';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> categoryList = _categoriesMap[selectedMenu] ?? [];
    final List<Product> filteredProducts = _isLoading
        ? _getDummyProducts()
        : _getFilteredProducts();

    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: _getBackRoute(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ClassicAppBar(
          title: _getAppBarTitle(),
          customBackRoute: _getBackRoute(),
        ),
        body: SafeArea(
          child: _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
            children: [
              _buildReservationInfo(),
              _buildOpenBillInfo(),
              _buildDineInInfo(),

              // ✅ Menu Selector (Makanan/Minuman)
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

              // ✅ Category Slider (Pasta, Frappe, Mocktail, dll)
              SubMenuSlider(
                subMenus: categoryList,
                selectedSubMenu: selectedCategory,
                onSubMenuSelected: (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),

              Expanded(
                child: Skeletonizer(
                  enabled: _isLoading,
                  enableSwitchAnimation: true,
                  child: ProductGrid(products: filteredProducts),
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
      ),
    );
  }
}