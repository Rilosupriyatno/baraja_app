import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/menu/menu_selector.dart';
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
  String selectedSubMenu = 'Chocolate';

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
    }
  }

  // Normalisasi produk - pindahkan Uncategorized ke Makanan
  List<Product> _normalizeProducts(List<Product> products) {
    return products.map((product) {
      // Salin produk untuk menghindari mutasi objek asli
      Product normalizedProduct = product;

      // Jika mainCategory adalah Uncategorized, ubah ke Makanan
      if (product.mainCategory == 'Uncategorized') {
        // Gunakan constructor dengan parameter yang diperlukan
        // Asumsikan bahwa Product memiliki constructor yang sesuai
        normalizedProduct = Product(
          id: product.id,
          name: product.name,
          category: product.category,
          mainCategory: 'Makanan', // Ganti Uncategorized dengan Makanan
          imageUrl: product.imageUrl,
          originalPrice: product.originalPrice,
          discountPrice: product.discountPrice,
          description: product.description,
          discountPercentage: product.discountPercentage,
          toppings: product.toppings,
          addons: product.addons,
          imageColor: product.imageColor,
        );
      }

      return normalizedProduct;
    }).toList();
  }

  // Membuat map kategori dari produk
  void _generateCategoriesMap(List<Product> products) {
    // Temporary map untuk menyimpan kategori yang unik
    Map<String, Set<String>> tempCategoriesMap = {};

    // Kumpulkan semua kategori dari produk
    for (var product in products) {
      final String mainCategory = product.mainCategory;

      if (!tempCategoriesMap.containsKey(mainCategory)) {
        tempCategoriesMap[mainCategory] = <String>{};
      }

      // Ekstrak kategori dari produk
      List<String> categories = _extractCategories(product);

      // Tambahkan semua kategori ke map
      for (var cat in categories) {
        tempCategoriesMap[mainCategory]!.add(cat);
      }
    }

    // Konversi Set menjadi List<Category>
    _categoriesMap = {};
    tempCategoriesMap.forEach((mainCategory, categories) {
      _categoriesMap[mainCategory] = categories
          .map((name) => Category(
        name: name,// Gunakan icon yang sesuai
      ))
          .toList();
    });
  }

  // Ekstrak kategori dari produk
  List<String> _extractCategories(Product product) {
    if (product.category is List) {
      return List<String>.from(product.category as Iterable);
    } else {
      return [product.category.toString()];
    }


  }

  // Helper untuk mendapatkan icon kategori
  // IconData _getCategoryIcon(String categoryName) {
  //   // Anda bisa mengubah ini sesuai kebutuhan
  //   switch (categoryName.toLowerCase()) {
  //     case 'coffee':
  //     case 'coffee flavour':
  //       return Icons.coffee;
  //     case 'recommended':
  //       return Icons.thumb_up;
  //     case 'chocolate':
  //       return Icons.bakery_dining;
  //     case 'mie':
  //       return Icons.ramen_dining;
  //     default:
  //       return Icons.category;
  //   }
  // }

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

      // Ekstrak kategori produk
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
      floatingActionButton: const CheckoutButton(),
    );
  }
}