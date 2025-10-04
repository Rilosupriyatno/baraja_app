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

  const MenuScreen({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
    this.isOpenBill = false,
    this.openBillData,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ProductService _productService = ProductService();

  List<Product> _allProducts = [];
  Map<String, List<Category>> _categoriesMap = {};

  String selectedMenu = 'Makanan';
  String selectedSubMenu = '';

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    print(widget.reservationData);
    print("ini adalah data open bill: ${widget.openBillData}");

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

  // Dummy products untuk skeleton
  List<Product> _getDummyProducts() {
    return List.generate(
      6,
          (index) => Product(
        id: 'dummy_$index',
        name: 'Loading Product Name',
        category: 'Loading',
        mainCategory: 'Loading',
        subCategory: 'Loading',
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

  String _determineMainCategory(Product product) {
    if (product.mainCategory.isNotEmpty) {
      String mainCat = product.mainCategory.toLowerCase();
      if (mainCat == 'minuman' || mainCat == 'minuman dingin' ||
          mainCat.contains('drink') || mainCat.contains('coffee') ||
          mainCat.contains('tea')) {
        return 'Minuman';
      } else if (mainCat == 'makanan' || mainCat.contains('food')) {
        return 'Makanan';
      }
    }

    String categoryName = '';
    if (product.category is Map && product.category['name'] != null) {
      categoryName = product.category['name'].toString();
    } else if (product.category is String) {
      categoryName = product.category;
    }

    if (categoryName.toLowerCase().contains('minuman') ||
        categoryName.toLowerCase().contains('drink') ||
        categoryName.toLowerCase().contains('coffee') ||
        categoryName.toLowerCase().contains('tea')) {
      return 'Minuman';
    } else if (categoryName.toLowerCase().contains('makanan') ||
        categoryName.toLowerCase().contains('food')) {
      return 'Makanan';
    }

    String productName = product.name.toLowerCase();
    if (productName.contains('es ') || productName.contains('teh ') ||
        productName.contains('kopi ') || productName.contains('jus ') ||
        productName.contains('minuman')) {
      return 'Minuman';
    }

    return 'Makanan';
  }

  void _generateCategoriesMap(List<Product> products) {
    try {
      Map<String, Set<String>> tempCategoriesMap = {};

      for (var product in products) {
        String mainCategory = _determineMainCategory(product);
        String subCategory = _extractSubCategory(product);

        if (!tempCategoriesMap.containsKey(mainCategory)) {
          tempCategoriesMap[mainCategory] = <String>{};
        }

        tempCategoriesMap[mainCategory]!.add(subCategory);
      }

      _categoriesMap = {};
      tempCategoriesMap.forEach((mainCategory, subCategories) {
        _categoriesMap[mainCategory] = subCategories
            .map((name) => Category(name: name))
            .toList();
      });

      debugPrint("Generated categories: $_categoriesMap");
    } catch (e) {
      debugPrint("Error in _generateCategoriesMap: $e");
      _categoriesMap = {
        'Makanan': [Category(name: 'Nasi Goreng')],
        'Minuman': [Category(name: 'Minuman Dingin')]
      };
    }
  }

  List<Product> _getFilteredProducts() {
    return _allProducts.where((product) {
      String productMainCategory = _determineMainCategory(product);

      if (productMainCategory != selectedMenu) {
        return false;
      }

      if (selectedSubMenu.isEmpty) {
        return true;
      }

      String productSubCategory = _extractSubCategory(product);
      return productSubCategory == selectedSubMenu;
    }).toList();
  }

  String _extractSubCategory(Product product) {
    if (product.subCategory != null && product.subCategory!.isNotEmpty) {
      return product.subCategory!;
    }

    if (product.category is Map && product.category['name'] != null) {
      return product.category['name'];
    } else if (product.category is String) {
      return product.category;
    }

    return 'Lainnya';
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
        selectedSubMenu = _categoriesMap[selectedMenu]![0].name;
      }
    }
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
    if (widget.isReservation) {
      return 'Menu Reservasi';
    } else if (widget.isDineIn) {
      return 'Menu Dine In';
    } else {
      return 'Menu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> subMenuList = _categoriesMap[selectedMenu] ?? [];
    final List<Product> filteredProducts = _isLoading
        ? _getDummyProducts()
        : _getFilteredProducts();

    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: '/main',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ClassicAppBar(title: _getAppBarTitle()),
        body: SafeArea(
          child: _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
            children: [
              _buildReservationInfo(),
              _buildOpenBillInfo(),
              _buildDineInInfo(),

              MenuSelector(
                selectedMenu: selectedMenu,
                onMenuSelected: (menu) {
                  setState(() {
                    selectedMenu = menu;
                    if (_categoriesMap[menu]!.isNotEmpty) {
                      selectedSubMenu = _categoriesMap[menu]![0].name;
                    }
                  });
                },
              ),

              SubMenuSlider(
                subMenus: subMenuList,
                selectedSubMenu: selectedSubMenu,
                onSubMenuSelected: (subMenu) {
                  setState(() {
                    selectedSubMenu = subMenu;
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
        ),
      ),
    );
  }
}