import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/gro_service.dart';
import '../services/tax_service.dart';
import '../services/product_service.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../widgets/cart/cart_item_edit_dialog.dart';
import '../theme/app_theme.dart';

class GroEditReservationScreen extends StatefulWidget {
  final String reservationId;
  final Map<String, dynamic> reservationData;

  const GroEditReservationScreen({
    super.key,
    required this.reservationId,
    required this.reservationData,
  });

  @override
  State<GroEditReservationScreen> createState() => _GroEditReservationScreenState();
}

class _GroEditReservationScreenState extends State<GroEditReservationScreen> {
  final GROService _groService = GROService();
  final TaxService _taxService = TaxService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _canEdit = false;

  // Form controllers
  late int _guestCount;
  late String _notes;
  late List<CartItem> _menuItems;
  late List<Map<String, dynamic>> _customAmountItems;

  // Tax calculation
  String? _outletId;
  TaxCalculationResult? _taxCalculation;
  bool _taxesLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeTaxData();
  }

  void _initializeData() {
    final reservation = widget.reservationData;

    // ✅ Check if reservation can be edited
    final status = reservation['status']?.toString().toLowerCase() ?? '';
    final hasCheckedIn = reservation['check_in_time'] != null;

    _canEdit = !hasCheckedIn && (status == 'pending' || status == 'confirmed');

    if (!_canEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  hasCheckedIn
                      ? 'Tidak dapat mengedit reservasi yang sudah dimulai'
                      : 'Tidak dapat mengedit reservasi dengan status $status'
              ),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      });
      return;
    }

    // Initialize form data
    _guestCount = reservation['guest_count'] ?? 1;
    _notes = reservation['notes'] ?? '';

    // ✅ Initialize menu items from order
    _menuItems = [];
    if (reservation['order_id'] != null && reservation['order_id'] is Map) {
      final order = reservation['order_id'] as Map<String, dynamic>;
      final items = order['items'] as List? ?? [];

      for (var item in items) {
        final menuItem = item['menuItem'];

        // Parse addons
        List<Map<String, dynamic>> addonsList = [];
        if (item['addons'] != null && item['addons'] is List) {
          for (var addon in item['addons']) {
            addonsList.add({
              'name': addon['name'] ?? '',
              'label': addon['label'] ?? addon['name'] ?? '',
              'price': addon['price'] ?? 0,
            });
          }
        }

        // Parse toppings
        List<Map<String, dynamic>> toppingsList = [];
        if (item['toppings'] != null && item['toppings'] is List) {
          for (var topping in item['toppings']) {
            toppingsList.add({
              'name': topping['name'] ?? '',
              'price': topping['price'] ?? 0,
            });
          }
        }

        // ✅ FIX: totalprice harus harga per item (base + addon + topping)
        // subtotal dari API sudah termasuk quantity, jadi perlu dibagi
        final int subtotal = item['subtotal'] ?? 0;
        final int qty = item['quantity'] ?? 1;
        final int pricePerItem = qty > 0 ? (subtotal / qty).round() : subtotal;

        _menuItems.add(CartItem(
          id: menuItem is Map ? (menuItem['_id'] ?? '') : menuItem ?? '',
          name: menuItem is Map ? (menuItem['name'] ?? 'Unknown Item') : 'Unknown Item',
          imageUrl: menuItem is Map ? (menuItem['imageURL'] ?? '') : '',
          price: menuItem is Map ? (menuItem['price'] ?? 0) : 0,
          quantity: qty,
          addons: addonsList,
          toppings: toppingsList,
          notes: item['notes'] ?? '',
          totalprice: pricePerItem, // harga per item, bukan subtotal
        ));
      }

      // ✅ Initialize custom amount items
      final customItems = order['customAmountItems'] as List? ?? [];
      _customAmountItems = customItems.map((item) => {
        'amount': item['amount'] ?? 0,
        'name': item['name'] ?? 'Penyesuaian Pembayaran',
        'description': item['description'] ?? '',
        'dineType': item['dineType'] ?? 'Dine-In',
      }).toList();

      // ✅ Extract outlet ID from order for tax calculation
      if (order['outletId'] != null) {
        if (order['outletId'] is Map) {
          _outletId = order['outletId']['_id']?.toString();
        } else {
          _outletId = order['outletId']?.toString();
        }
      }
    } else {
      _customAmountItems = [];
    }

    // Try to get outlet from tables if not found in order
    if (_outletId == null && reservation['tables'] != null) {
      final tables = reservation['tables'] as List?;
      if (tables != null && tables.isNotEmpty) {
        final firstTable = tables.first;
        if (firstTable is Map && firstTable['outletId'] != null) {
          if (firstTable['outletId'] is Map) {
            _outletId = firstTable['outletId']['_id']?.toString();
          } else {
            _outletId = firstTable['outletId']?.toString();
          }
        }
      }
    }
  }

  Future<void> _initializeTaxData() async {
    try {
      await _taxService.getTaxesAndServices();
      setState(() {
        _taxesLoaded = true;
      });
      _calculateTaxes();
    } catch (e) {
      debugPrint('Error loading tax data: $e');
      setState(() {
        _taxesLoaded = true; // Still mark as loaded to avoid blocking
      });
    }
  }

  void _calculateTaxes() {
    if (!_taxesLoaded || _outletId == null) return;

    final subtotal = _calculateTotal();

    final taxCalculation = _taxService.calculateTaxes(
      subtotal: subtotal.toDouble(),
      outletId: _outletId!,
      isReservation: true,
      isOpenBill: false,
    );

    setState(() {
      _taxCalculation = taxCalculation;
    });
  }

  int _getGrandTotal() {
    final subtotal = _calculateTotal();
    final taxAmount = _taxCalculation?.totalTaxAmount.round() ?? 0;
    return subtotal + taxAmount;
  }

  Future<void> _addMenuItem() async {
    // Tampilkan dialog pemilihan produk
    showDialog(
      context: context,
      builder: (context) => _ProductSelectionDialog(
        outletId: _outletId,
        onProductSelected: (CartItem item) {
          setState(() {
            _menuItems.add(item);
          });
          _calculateTaxes();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} ditambahkan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // ✅ EDIT MENU ITEM - Sama seperti CartItemEditDialog
  void _editMenuItem(int index) {
    final item = _menuItems[index];

    showDialog(
      context: context,
      builder: (context) => CartItemEditDialog(
        item: item,
        onSave: (updatedItem) {
          setState(() {
            _menuItems[index] = updatedItem;
          });
          _calculateTaxes(); // Recalculate taxes

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item berhasil diubah'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _removeMenuItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Apakah Anda yakin ingin menghapus "${_menuItems[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _menuItems.removeAt(index);
              });
              Navigator.pop(context);
              _calculateTaxes(); // Recalculate taxes

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item berhasil dihapus'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addCustomAmount() {
    showDialog(
      context: context,
      builder: (context) => _CustomAmountDialog(
        onAdd: (customAmount) {
          setState(() {
            _customAmountItems.add(customAmount);
          });
          _calculateTaxes(); // Recalculate taxes
        },
      ),
    );
  }

  void _removeCustomAmount(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penyesuaian'),
        content: Text('Apakah Anda yakin ingin menghapus "${_customAmountItems[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customAmountItems.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  int _calculateTotal() {
    // totalprice = harga per item (base + addon + topping), dikali quantity
    int menuTotal = _menuItems.fold(0, (sum, item) => sum + (item.totalprice * item.quantity));
    int customTotal = _customAmountItems.fold(0, (sum, item) => sum + (item['amount'] as int));
    return menuTotal + customTotal;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Konfirmasi sebelum save
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Perubahan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menyimpan perubahan?'),
            const SizedBox(height: 16),
            Text('Subtotal: ${formatCurrency(_calculateTotal())}'),
            if (_taxCalculation != null && _taxCalculation!.taxDetails.isNotEmpty)
              Text('Pajak: ${formatCurrency(_taxCalculation!.totalTaxAmount.round())}'),
            Text('Total Estimasi: ${formatCurrency(_getGrandTotal())}'),
            Text('Jumlah Menu: ${_menuItems.length} item'),
            Text('Penyesuaian Biaya: ${_customAmountItems.length} item'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Convert menu items to API format
      final items = _menuItems.map((item) => {
        'productId': item.id,
        'productName': item.name,
        'quantity': item.quantity,
        'price': item.price,
        'totalprice': item.totalprice,
        'addons': item.addons,
        'toppings': item.toppings,
        'notes': item.notes,
      }).toList();

      final result = await _groService.editReservation(
        reservationId: widget.reservationId,
        guestCount: _guestCount,
        notes: _notes,
        items: items,
        customAmountItems: _customAmountItems,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservasi berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal memperbarui reservasi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canEdit) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Edit Reservasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E8B57),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Guest Count
            _buildSectionHeader('Informasi Tamu'),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _guestCount.toString(),
              decoration: InputDecoration(
                labelText: 'Jumlah Tamu',
                prefixIcon: Icon(Icons.people, color: AppTheme.barajaPrimary.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tamu harus diisi';
                }
                final count = int.tryParse(value);
                if (count == null || count < 1) {
                  return 'Jumlah tamu minimal 1';
                }
                return null;
              },
              onChanged: (value) {
                _guestCount = int.tryParse(value) ?? _guestCount;
              },
            ),

            const SizedBox(height: 24),

            // Menu Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Menu Pesanan'),
                Text(
                  '${_menuItems.length} item',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_menuItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada menu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                // Build addons text
                String addonsText = '';
                if (item.addons.isNotEmpty) {
                  addonsText = item.addons
                      .map((addon) => addon['label'] ?? addon['name'])
                      .join(', ');
                }

                // Build toppings text
                String toppingsText = '';
                if (item.toppings is List && (item.toppings as List).isNotEmpty) {
                  toppingsText = (item.toppings as List)
                      .map((topping) => topping['name'])
                      .join(', ');
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity}x - ${formatCurrency(item.totalprice * item.quantity)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2E8B57),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF2E8B57)),
                              onPressed: () => _editMenuItem(index),
                              tooltip: 'Edit',
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeMenuItem(index),
                              tooltip: 'Hapus',
                            ),
                          ],
                        ),

                        // Show addons if any
                        if (addonsText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    addonsText,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show toppings if any
                        if (toppingsText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_pizza_outlined, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    toppingsText,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show notes if any
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.note_outlined, size: 16, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.notes!,
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addMenuItem,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Menu'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: const Color(0xFF2E8B57),
              ),
            ),

            const SizedBox(height: 24),

            // Custom Amount Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Penyesuaian Biaya'),
                Text(
                  '${_customAmountItems.length} item',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_customAmountItems.isNotEmpty)
              ..._customAmountItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payment, color: Colors.purple),
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: item['description']?.isNotEmpty == true
                        ? Text(item['description'], style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrency(item['amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2E8B57),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeCustomAmount(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            OutlinedButton.icon(
              onPressed: _addCustomAmount,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Penyesuaian Biaya'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: const Color(0xFF2E8B57),
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            _buildSectionHeader('Catatan'),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _notes,
              decoration: InputDecoration(
                labelText: 'Catatan Tambahan',
                prefixIcon: Icon(Icons.note_outlined, color: AppTheme.barajaPrimary.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (value) {
                _notes = value;
              },
            ),

            const SizedBox(height: 32),

            // Total Summary with Tax Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E8B57)),
              ),
              child: Column(
                children: [
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        formatCurrency(_calculateTotal()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tax items
                  if (_taxCalculation != null && _taxCalculation!.taxDetails.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._taxCalculation!.taxDetails.map((tax) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${tax['name']} (${(tax['percentage'] as num).toStringAsFixed(0)}%):',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '+${formatCurrency((tax['amount'] as num).round())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ] else if (!_taxesLoaded) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Menghitung pajak...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  
                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Estimasi:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency(_getGrandTotal()),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E8B57),
      ),
    );
  }
}

// Custom Amount Dialog
class _CustomAmountDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _CustomAmountDialog({required this.onAdd});

  @override
  State<_CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<_CustomAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Penyesuaian Biaya'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  hintText: 'e.g., Biaya Dekorasi',
                  prefixIcon: Icon(Icons.label, color: AppTheme.barajaPrimary.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Rp)',
                  hintText: 'e.g., 500000',
                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.barajaPrimary.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah harus diisi';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  prefixIcon: Icon(Icons.description, color: AppTheme.barajaPrimary.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.barajaPrimary.primaryColor),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd({
                'name': _nameController.text,
                'amount': int.parse(_amountController.text),
                'description': _descriptionController.text,
                'dineType': 'Dine-In',
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B57),
          ),
          child: const Text('Tambah', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Product Selection Dialog untuk menambah menu langsung
class _ProductSelectionDialog extends StatefulWidget {
  final String? outletId;
  final Function(CartItem) onProductSelected;

  const _ProductSelectionDialog({
    required this.outletId,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  int _quantity = 1;
  bool _isLoading = true;
  
  // Addon & Topping states
  Map<String, AddonOption?> _selectedAddonOptions = {};
  List<Topping> _selectedToppings = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading products: $e');
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
    } else {
      setState(() {
        _filteredProducts = _allProducts.where((product) {
          final name = product.name.toLowerCase();
          final category = product.category?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || category.contains(searchQuery);
        }).toList();
      });
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _quantity = 1;
      _selectedAddonOptions.clear();
      _selectedToppings.clear();
      _notesController.clear();
      
      // Init default addons
      if (product.addons != null) {
        for (var addon in product.addons!) {
          if (addon.options.isNotEmpty) {
            var defaultOption = addon.options.where((o) => o.isDefault).firstOrNull;
            defaultOption ??= addon.options.first;
            _selectedAddonOptions[addon.id] = defaultOption;
          }
        }
      }
    });
  }

  int _calculateItemPrice() {
    if (_selectedProduct == null) return 0;
    
    int basePrice = (_selectedProduct!.discountPrice ?? _selectedProduct!.originalPrice ?? 0).toInt();
    int toppingsTotal = _selectedToppings.fold(0, (sum, topping) => sum + topping.price.toInt());
    
    int addonOptionsTotal = 0;
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null) {
        addonOptionsTotal += option.price.toInt();
      }
    });

    return basePrice + toppingsTotal + addonOptionsTotal;
  }

  void _addToMenu() {
    if (_selectedProduct == null) return;

    // Prepare toppings list
    List<Map<String, dynamic>> toppingsList = _selectedToppings
        .map((topping) => {
              'name': topping.name,
              'price': topping.price.toInt(),
            })
        .toList();

    // Prepare addons list
    List<Map<String, dynamic>> addonList = [];
    _selectedAddonOptions.forEach((addonId, option) {
      if (option != null && _selectedProduct!.addons != null) {
        final addon = _selectedProduct!.addons!.firstWhere((a) => a.id == addonId);
        addonList.add({
          'name': addon.name,
          'label': option.label,
          'price': option.price.toInt(),
        });
      }
    });

    final cartItem = CartItem(
      id: _selectedProduct!.id,
      name: _selectedProduct!.name,
      imageUrl: _selectedProduct!.imageUrl,
      price: (_selectedProduct!.originalPrice ?? _selectedProduct!.discountPrice ?? 0).toInt(),
      totalprice: _calculateItemPrice(),
      addons: addonList,
      toppings: toppingsList,
      quantity: _quantity,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    widget.onProductSelected(cartItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tambah Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_selectedProduct == null)
              // Product list
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: _filterProducts,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final price = product.discountPrice ?? product.originalPrice ?? 0;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood),
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              product.category ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Text(
                              formatCurrency(price.toInt()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E8B57),
                              ),
                            ),
                            onTap: () => _selectProduct(product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              // Product detail form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button and product name
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setState(() => _selectedProduct = null),
                          ),
                          Expanded(
                            child: Text(
                              _selectedProduct!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Quantity
                      const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            icon: Icon(
                              Icons.remove_circle,
                              color: _quantity > 1 ? Colors.red : Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                          ),
                        ],
                      ),

                      // Toppings
                      if (_selectedProduct!.toppings != null && _selectedProduct!.toppings!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Topping', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._selectedProduct!.toppings!.map((topping) => CheckboxListTile(
                              title: Text(topping.name),
                              subtitle: Text(formatCurrency(topping.price.toInt())),
                              value: _selectedToppings.contains(topping),
                              onChanged: (_) {
                                setState(() {
                                  if (_selectedToppings.contains(topping)) {
                                    _selectedToppings.remove(topping);
                                  } else {
                                    _selectedToppings.add(topping);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            )),
                      ],

                      // Addons
                      if (_selectedProduct!.addons != null && _selectedProduct!.addons!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Tambahan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._selectedProduct!.addons!.map((addon) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(addon.name, style: const TextStyle(fontSize: 14)),
                                ),
                                ...addon.options.map((option) => RadioListTile<AddonOption>(
                                      title: Text(option.label),
                                      subtitle: Text(formatCurrency(option.price.toInt())),
                                      value: option,
                                      groupValue: _selectedAddonOptions[addon.id],
                                      onChanged: (value) {
                                        setState(() => _selectedAddonOptions[addon.id] = value);
                                      },
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    )),
                              ],
                            )),
                      ],

                      // Notes
                      const SizedBox(height: 16),
                      const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 2,
                      ),

                      // Total
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              formatCurrency(_calculateItemPrice() * _quantity),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E8B57),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Footer (only show when product selected)
            if (_selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addToMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Tambahkan ke Pesanan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}