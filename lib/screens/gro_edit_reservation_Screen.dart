import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/gro_service.dart';
import '../models/cart_item.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _canEdit = false;

  // Form controllers
  late int _guestCount;
  late String _notes;
  late List<CartItem> _menuItems;
  late List<Map<String, dynamic>> _customAmountItems;

  @override
  void initState() {
    super.initState();
    _initializeData();
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

        _menuItems.add(CartItem(
          id: menuItem is Map ? (menuItem['_id'] ?? '') : menuItem ?? '',
          name: menuItem is Map ? (menuItem['name'] ?? 'Unknown Item') : 'Unknown Item',
          imageUrl: menuItem is Map ? (menuItem['imageURL'] ?? '') : '',
          price: menuItem is Map ? (menuItem['price'] ?? 0) : 0,
          quantity: item['quantity'] ?? 1,
          addons: addonsList,
          toppings: toppingsList,
          notes: item['notes'] ?? '',
          totalprice: item['subtotal'] ?? 0,
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
    } else {
      _customAmountItems = [];
    }
  }

  Future<void> _addMenuItem() async {
    // Navigate ke menu screen untuk tambah item
    final result = await context.push('/menu', extra: {
      'isGroMode': true,
      'isEditMode': true,
    });

    if (result != null && result is CartItem) {
      setState(() {
        _menuItems.add(result);
      });
    }
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
            Text('Total Pesanan: ${formatCurrency(_calculateTotal())}'),
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

            // Total Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E8B57)),
              ),
              child: Row(
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
                    formatCurrency(_calculateTotal()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'Note: Total belum termasuk pajak dan service charge',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
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