import 'package:flutter/material.dart';

class SearchMenuWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback? onClearSearch;

  const SearchMenuWidget({
    super.key,
    required this.onSearchChanged,
    this.onClearSearch,
  });

  @override
  State<SearchMenuWidget> createState() => _SearchMenuWidgetState();
}

class _SearchMenuWidgetState extends State<SearchMenuWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
    });
    widget.onSearchChanged('');
    if (widget.onClearSearch != null) {
      widget.onClearSearch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchActive ? Colors.orange.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _isSearchActive = value.isNotEmpty;
          });
          widget.onSearchChanged(value);
        },
        decoration: InputDecoration(
          hintText: 'Cari menu...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isSearchActive ? Colors.orange.shade700 : Colors.grey.shade500,
            size: 22,
          ),
          suffixIcon: _isSearchActive
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: _clearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}