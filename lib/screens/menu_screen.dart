import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../widgets/detail_product/checkout_button.dart';
import '../widgets/menu/menu_selector.dart';
import '../widgets/menu/product_grid.dart';
import '../widgets/menu/sub_menu_slider.dart';
import '../widgets/utils/classic_app_bar.dart';
import '../services/product_service.dart'; // Import ProductService

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

  late Future<List<Product>> _productFuture;  // To hold the future for products
  late Future<List<Category>> _categoryFuture;  // To hold the future for categories

  @override
  void initState() {
    super.initState();
    // Fetch products and categories when the screen is initialized
    _productFuture = ProductService.fetchMenuItems();
    _categoryFuture = _fetchCategories();  // Method to get categories
  }

  // Method to fetch categories dynamically, you can modify it if needed
  Future<List<Category>> _fetchCategories() async {
    // Just a mock for categories, you can replace with dynamic data fetching logic if necessary
    return [
      Category(id: 'coffee', name: 'Coffee'),
      Category(id: 'tea', name: 'Tea'),
      Category(id: 'juice', name: 'Juice'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ClassicAppBar(title: 'Menu'),
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_productFuture, _categoryFuture]), // Wait for both data
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // Loading state
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}')); // Error handling
            }

            final List<Product> products = snapshot.data![0]; // List of products
            final List<Category> categories = snapshot.data![1]; // List of categories

            // Filter products based on selected menu and sub-menu
            final List<Product> filteredProducts = products.where((product) =>
            product.mainCategory == selectedMenu &&
                product.category == selectedSubMenu
            ).toList();

            return Column(
              children: [
                // Menu selector (Makanan/Minuman)
                MenuSelector(
                  selectedMenu: selectedMenu,
                  onMenuSelected: (menu) {
                    setState(() {
                      selectedMenu = menu;
                      selectedSubMenu = categories.firstWhere((cat) => cat.name == menu).name; // Reset sub-menu
                    });
                  },
                ),

                // Sub-menu slider
                SubMenuSlider(
                  subMenus: categories,
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
            );
          },
        ),
      ),
      floatingActionButton: const CheckoutButton(),
    );
  }
}
