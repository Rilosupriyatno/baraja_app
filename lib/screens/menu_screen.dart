import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/detail_product/checkout_button.dart';
// import '../widgets/menu/menu_selector.dart';
import '../widgets/menu/product_grid.dart';
import '../widgets/menu/sub_menu_slider.dart';
import '../widgets/utils/classic_app_bar.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

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
  String selectedMenu = 'Minuman';

  // Selected sub-menu
  String selectedSubMenu = 'Coffee';

  // Loading state
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

      // Normalisasi produk - pindahkan Uncategorized ke Makanan
      final normalizedProducts = _normalizeProducts(products);

      setState(() {
        _allProducts = normalizedProducts;

        // Buat map kategori dari produk yang diterima
        _generateCategoriesMap(normalizedProducts);

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

  // Normalisasi produk - pindahkan Uncategorized ke Makanan
  List<Product> _normalizeProducts(List<Product> products) {
    return products;  // Simply return the products as-is for now
  }

  // Extracting individual categories from product
  List<String> _extractCategories(Product product) {
    List<String> categories = [];

    if (product.category is List) {
      // Process each category in the list
      for (var cat in product.category as List) {
        if (cat != null && cat is String && !_isMongoDbId(cat) && cat.isNotEmpty) {
          categories.add(cat);
        }
      }
    }
    else if (product.category is String) {
      String categoryStr = product.category.toString();
      // Split by comma if it contains commas
      if (categoryStr.contains(',')) {
        List<String> splitCategories = categoryStr.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !_isMongoDbId(e))
            .toList();
        categories.addAll(splitCategories);
      } else if (!_isMongoDbId(categoryStr)) {
        // Single category string
        categories.add(categoryStr);
      }
    }

    // If no valid categories found, add a default
    if (categories.isEmpty) {
      categories.add('General');
    }

    return categories;
  }

  // Helper to check if a string looks like a MongoDB ObjectId
  bool _isMongoDbId(String str) {
    // MongoDB ObjectIds are 24 character hex strings
    return str.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(str);
  }

  // Membuat map kategori dari produk
  void _generateCategoriesMap(List<Product> products) {
    try {
      // Temporary map untuk menyimpan kategori yang unik
      Map<String, Set<String>> tempCategoriesMap = {};

      // Kumpulkan semua kategori dari produk
      for (var product in products) {
        final String mainCategory = product.mainCategory;

        if (!tempCategoriesMap.containsKey(mainCategory)) {
          tempCategoriesMap[mainCategory] = <String>{};
        }

        // Ekstrak kategori dari produk - now as individual items
        List<String> categories = _extractCategories(product);

        // Tambahkan semua kategori ke map
        tempCategoriesMap[mainCategory]!.addAll(categories);
      }

      // Konversi Set menjadi List<Category>
      _categoriesMap = {};
      tempCategoriesMap.forEach((mainCategory, categories) {
        _categoriesMap[mainCategory] = categories
            .map((name) => Category(
          name: name,
        ))
            .toList();
      });

      debugPrint("Generated categories: $_categoriesMap");
    } catch (e) {
      debugPrint("Error in _generateCategoriesMap: $e");
      // Fallback to default categories if there's an error
      _categoriesMap = {
        'Minuman': [Category(name: 'Coffee'), Category(name: 'Tea')],
        'Makanan': [Category(name: 'Snack'), Category(name: 'Meal')]
      };
    }
  }

  // Set pilihan awal berdasarkan data yang tersedia
  void _setInitialSelections() {
    // Pastikan ada main kategori
    if (_categoriesMap.isNotEmpty) {
      selectedMenu = _categoriesMap.keys.first;

      // Pastikan ada sub kategori
      if (_categoriesMap[selectedMenu]!.isNotEmpty) {
        selectedSubMenu = _categoriesMap[selectedMenu]![0].name;
      }
    }
  }

  // Filter produk berdasarkan kategori yang dipilih
  List<Product> _getFilteredProducts() {
    return _allProducts.where((product) {
      // Cek main category
      if (product.mainCategory != selectedMenu) {
        return false;
      }

      // Ekstrak kategori produk as separate items
      List<String> productCategories = _extractCategories(product);

      // Cek apakah selectedSubMenu ada dalam kategori produk
      return productCategories.contains(selectedSubMenu);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Ambil daftar sub-menu berdasarkan menu yang dipilih
    final List<Category> subMenuList = _categoriesMap[selectedMenu] ?? [];
    // Ambil produk yang sesuai dengan menu dan sub-menu yang dipilih
    final List<Product> filteredProducts = _getFilteredProducts();

// Menampilkan jumlah produk
    print('Filtered products count: ${filteredProducts.length}');

// Menampilkan detail setiap produk
    for (var product in filteredProducts) {
      print('Product: ${product.name}, Categories: ${product.category}, Main Category: ${product.averageRating}');
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Menu'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : Column(
          children: [
            // Menu selector (Makanan/Minuman)
            // MenuSelector(
            //   selectedMenu: selectedMenu,
            //   onMenuSelected: (menu) {
            //     setState(() {
            //       selectedMenu = menu;
            //       if (_categoriesMap[menu]!.isNotEmpty) {
            //         selectedSubMenu = _categoriesMap[menu]![0].name; // Reset sub-menu
            //       }
            //     });
            //   },
            // ),

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
      floatingActionButton: const CheckoutButton(),
    );
  }
}