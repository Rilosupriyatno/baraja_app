import 'package:flutter/material.dart';
import '../data/product_data.dart';
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
  final ProductService _productService = ProductService();

  String selectedMenu = 'Minuman';
  String selectedSubMenu = 'Coffee';

  List<Product> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Category> subMenuList = ProductData.subMenus[selectedMenu] ?? [];

    final List<Product> filteredProducts = _allProducts.where((product) =>
    product.mainCategory.toLowerCase() == selectedMenu.toLowerCase() &&
        product.category.toLowerCase() == selectedSubMenu.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Menu'),
      body: SafeArea(
        child: Column(
          children: [
            MenuSelector(
              selectedMenu: selectedMenu,
              onMenuSelected: (menu) {
                setState(() {
                  selectedMenu = menu;
                  selectedSubMenu = ProductData.subMenus[menu]![0].name;
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ProductGrid(products: filteredProducts),
            ),
          ],
        ),
      ),
      floatingActionButton: const CheckoutButton(),
    );
  }
}


// class _MenuScreenState extends State<MenuScreen> {
//   // Selected menu (Makanan atau Minuman)
//   String selectedMenu = 'Minuman';
//
//   // Selected sub-menu
//   String selectedSubMenu = 'Coffee';
//
//   @override
//   Widget build(BuildContext context) {
//     // Ambil daftar sub-menu berdasarkan menu yang dipilih
//     final List<Category> subMenuList = ProductData.subMenus[selectedMenu] ?? [];
//     // Ambil produk yang sesuai dengan menu dan sub-menu yang dipilih
//     final List<Product> filteredProducts = ProductData.getProducts().where((product) =>
//     product.mainCategory == selectedMenu &&
//         product.category == selectedSubMenu
//     ).toList();
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: const ClassicAppBar(title: 'Menu'),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Menu selector (Makanan/Minuman)
//             MenuSelector(
//               selectedMenu: selectedMenu,
//               onMenuSelected: (menu) {
//                 setState(() {
//                   selectedMenu = menu;
//                   selectedSubMenu = ProductData.subMenus[menu]![0].name; // Reset sub-menu
//                 });
//               },
//             ),
//
//             // Sub-menu slider
//             SubMenuSlider(
//               subMenus: subMenuList,
//               selectedSubMenu: selectedSubMenu,
//               onSubMenuSelected: (subMenu) {
//                 setState(() {
//                   selectedSubMenu = subMenu;
//                 });
//               },
//             ),
//
//             // Product grid (scrollable)
//             Expanded(
//               child: ProductGrid(products: filteredProducts),
//             ),
//
//           ],
//         ),
//       ),
//       floatingActionButton: const CheckoutButton(),
//     );
//   }
// }
