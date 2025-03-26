import 'package:baraja_app/widgets/classic_app_bar.dart';
import 'package:flutter/material.dart';
import '../data/product_data.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/checkout_button.dart';
import '../widgets/menu_selector.dart';
import '../widgets/product_grid.dart';
import '../widgets/sub_menu_slider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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

          ],
        ),
      ),
      floatingActionButton: const CheckoutButton(),
    );
  }
}
