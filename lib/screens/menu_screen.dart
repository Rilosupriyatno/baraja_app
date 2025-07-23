import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  const MenuScreen({
    super.key,
    this.isReservation = false,
    this.reservationData,
    this.isDineIn = false,
    this.tableNumber,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Instance ProductService
  final ProductService _productService = ProductService();

  // Data produk dan kategori
  List<Product> _allProducts = [];
  Map<String, List<Category>> _categoriesMap = {};

  // Selected menu (Makanan atau Minuman)
  String selectedMenu = 'Makanan';

  // Selected sub-menu
  String selectedSubMenu = '';

  // Loading state
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    print(widget.reservationData);

    // Set context in cart provider when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (widget.isReservation && widget.reservationData != null) {
        cartProvider.setReservationData(widget.isReservation, widget.reservationData);
      } else if (widget.isDineIn && widget.tableNumber != null) {
        cartProvider.setDineInData(widget.isDineIn, widget.tableNumber);
      }
    });
  }

  // Fungsi untuk memuat produk dari API
  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Ambil semua produk dari service
      final products = await _productService.getProducts();

      setState(() {
        _allProducts = products;

        // Buat map kategori dari produk yang diterima
        _generateCategoriesMap(products);

        // Set default selection berdasarkan data yang tersedia
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

  // SOLUSI 1: Ubah fungsi _determineMainCategory untuk menerima Product object
  String _determineMainCategory(Product product) {
    // Prioritas 1: Gunakan mainCategory dari JSON jika ada
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

    // Prioritas 2: Gunakan category field jika mainCategory tidak membantu
    String categoryName = '';
    if (product.category is Map && product.category['name'] != null) {
      categoryName = product.category['name'].toString();
    } else if (product.category is String) {
      categoryName = product.category;
    }

    // Klasifikasi berdasarkan nama kategori
    if (categoryName.toLowerCase().contains('minuman') ||
        categoryName.toLowerCase().contains('drink') ||
        categoryName.toLowerCase().contains('coffee') ||
        categoryName.toLowerCase().contains('tea')) {
      return 'Minuman';
    } else if (categoryName.toLowerCase().contains('makanan') ||
        categoryName.toLowerCase().contains('food')) {
      return 'Makanan';
    }

    // Prioritas 3: Klasifikasi berdasarkan nama produk
    String productName = product.name.toLowerCase();
    if (productName.contains('es ') || productName.contains('teh ') ||
        productName.contains('kopi ') || productName.contains('jus ') ||
        productName.contains('minuman')) {
      return 'Minuman';
    }

    return 'Makanan'; // Default fallback
  }

// UPDATE: Fungsi _generateCategoriesMap menggunakan SOLUSI 1
  void _generateCategoriesMap(List<Product> products) {
    try {
      // Temporary map untuk menyimpan kategori yang unik
      Map<String, Set<String>> tempCategoriesMap = {};

      // Kumpulkan semua subCategory berdasarkan mainCategory
      for (var product in products) {
        // Gunakan fungsi yang sudah diperbaiki - langsung pass product object
        String mainCategory = _determineMainCategory(product);

        // Ambil subCategory dari product service response
        String subCategory = _extractSubCategory(product);

        if (!tempCategoriesMap.containsKey(mainCategory)) {
          tempCategoriesMap[mainCategory] = <String>{};
        }

        // Tambahkan subCategory ke mainCategory
        tempCategoriesMap[mainCategory]!.add(subCategory);
      }

      // Konversi Set menjadi List<Category>
      _categoriesMap = {};
      tempCategoriesMap.forEach((mainCategory, subCategories) {
        _categoriesMap[mainCategory] = subCategories
            .map((name) => Category(name: name))
            .toList();
      });

      debugPrint("Generated categories: $_categoriesMap");
    } catch (e) {
      debugPrint("Error in _generateCategoriesMap: $e");
      // Fallback to default categories if there's an error
      _categoriesMap = {
        'Makanan': [Category(name: 'Nasi Goreng')],
        'Minuman': [Category(name: 'Minuman Dingin')]
      };
    }
  }

// UPDATE: Fungsi _getFilteredProducts juga menggunakan product object
  List<Product> _getFilteredProducts() {
    return _allProducts.where((product) {
      // Gunakan fungsi yang sudah diperbaiki
      String productMainCategory = _determineMainCategory(product);

      // Cek main category
      if (productMainCategory != selectedMenu) {
        return false;
      }

      // Jika selectedSubMenu kosong, tampilkan semua produk dari mainCategory
      if (selectedSubMenu.isEmpty) {
        return true;
      }

      // Cek sub category
      String productSubCategory = _extractSubCategory(product);
      return productSubCategory == selectedSubMenu;
    }).toList();
  }

  // Ekstrak subCategory dari product
  String _extractSubCategory(Product product) {
    // Prioritas: gunakan subCategory dari backend response jika ada
    if (product.mainCategory.isNotEmpty && product.mainCategory != 'Makanan' && product.mainCategory != 'Minuman') {
      return product.mainCategory; // mainCategory sudah diisi dengan subCategory di service
    }

    // Fallback: gunakan category name
    if (product.category is Map && product.category['name'] != null) {
      return product.category['name'];
    } else if (product.category is String) {
      return product.category;
    }

    return 'Lainnya';
  }

  // Set pilihan awal berdasarkan data yang tersedia
  void _setInitialSelections() {
    // Pastikan ada main kategori
    if (_categoriesMap.isNotEmpty) {
      // Prioritas: Makanan dulu, baru Minuman
      if (_categoriesMap.containsKey('Makanan')) {
        selectedMenu = 'Makanan';
      } else if (_categoriesMap.containsKey('Minuman')) {
        selectedMenu = 'Minuman';
      } else {
        selectedMenu = _categoriesMap.keys.first;
      }

      // Pastikan ada sub kategori
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
    print(data);

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

  // Widget untuk menampilkan info dine-in
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

  // Get dynamic app bar title
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
    // Ambil daftar sub-menu berdasarkan menu yang dipilih
    final List<Category> subMenuList = _categoriesMap[selectedMenu] ?? [];
    // Ambil produk yang sesuai dengan menu dan sub-menu yang dipilih
    final List<Product> filteredProducts = _getFilteredProducts();

    return BaseScreenWrapper(
      canPop: false,
      customBackRoute: '/main', // Always go back to main for menu
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: ClassicAppBar(title: _getAppBarTitle()),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
            children: [
              // Reservation info (only shown if isReservation is true)
              _buildReservationInfo(),

              // Dine-in info (only shown if isDineIn is true)
              _buildDineInInfo(),

              // Menu selector (Makanan/Minuman)
              MenuSelector(
                selectedMenu: selectedMenu,
                onMenuSelected: (menu) {
                  setState(() {
                    selectedMenu = menu;
                    if (_categoriesMap[menu]!.isNotEmpty) {
                      selectedSubMenu = _categoriesMap[menu]![0].name; // Reset sub-menu
                    }
                  });
                },
              ),

              // Sub-menu slider
              SubMenuSlider(
                subMenus: subMenuList,
                selectedSubMenu: selectedSubMenu,
                onSubMenuSelected: (subMenu) {
                  setState(() {
                    selectedSubMenu = subMenu;
                  });
                },
              ),

              // Product grid (scrollable)
              Expanded(
                child: ProductGrid(products: filteredProducts),
              ),
            ],
          ),
        ),
        floatingActionButton: CheckoutButton(
          isReservation: widget.isReservation,
          reservationData: widget.reservationData,
          isDineIn: widget.isDineIn,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }
}