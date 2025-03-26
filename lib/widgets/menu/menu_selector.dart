import 'package:flutter/material.dart';
import 'package:baraja_app/theme/app_theme.dart';

/// Widget untuk memilih menu utama (Makanan atau Minuman)
class MenuSelector extends StatelessWidget {
  final String selectedMenu;
  final Function(String) onMenuSelected;

  const MenuSelector({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMenuButton('Makanan', context),
          const SizedBox(width: 10),
          _buildMenuButton('Minuman', context),
        ],
      ),
    );
  }

  /// Membangun tombol menu dengan status selected/unselected
  Widget _buildMenuButton(String menuName, BuildContext context) {
    final isSelected = selectedMenu == menuName;

    return Expanded(
      child: ElevatedButton(
        onPressed: () => onMenuSelected(menuName),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          // shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          menuName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
    );
  }
}