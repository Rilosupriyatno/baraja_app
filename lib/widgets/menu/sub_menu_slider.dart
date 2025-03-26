import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../theme/app_theme.dart';

/// Widget untuk slider horizontal sub-menu
class SubMenuSlider extends StatelessWidget {
  final List<Category> subMenus;
  final String selectedSubMenu;
  final Function(String) onSubMenuSelected;

  const SubMenuSlider({
    super.key,
    required this.subMenus,
    required this.selectedSubMenu,
    required this.onSubMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subMenus.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final subMenu = subMenus[index];
          return _buildSubMenuButton(subMenu.name, context);
        },
      ),
    );
  }

  /// Membangun tombol sub-menu dengan status selected/unselected
  Widget _buildSubMenuButton(String subMenuName, BuildContext context) {
    final isSelected = selectedSubMenu == subMenuName;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () => onSubMenuSelected(subMenuName),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          subMenuName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}