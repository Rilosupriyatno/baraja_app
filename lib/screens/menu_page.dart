import 'package:baraja_app/widgets/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../data/product_data.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/menu_selector.dart';
import '../widgets/product_grid.dart';
import '../widgets/sub_menu_slider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Selected menu (Makanan atau Minuman)
  String selectedMenu = 'Minuman';

  // Selected sub-menu
  String selectedSubMenu = 'Coffee';

  @override
  Widget build(BuildContext context) {
    // Ambil daftar sub-menu berdasarkan menu yang dipilih
    final List<Category> subMenuList = ProductData.subMenus[selectedMenu] ?? [];
    // Ambil produk yang sesuai dengan menu dan sub-menu yang dipilih
    final List<Product> filteredProducts = ProductData.getProducts().where((product) =>
    product.mainCategory == selectedMenu &&
        product.category == selectedSubMenu
    ).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Menu'),
      body: SafeArea(
        child: Column(
          children: [
            // Menu selector (Makanan/Minuman)
            MenuSelector(
              selectedMenu: selectedMenu,
              onMenuSelected: (menu) {
                setState(() {
                  selectedMenu = menu;
                  selectedSubMenu = ProductData.subMenus[menu]![0].name; // Reset sub-menu
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

            // Checkout button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  // Tambahkan logika checkout di sini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF076A3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Produk yang mau di checkout',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
