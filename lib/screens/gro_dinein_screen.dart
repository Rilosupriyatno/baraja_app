// ============================================================================
// FILE 2: gro_dinein_screen.dart
// UPDATED: Multi-table support for dine-in
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class GroDineInGuestFormScreen extends StatefulWidget {
// ✅ UPDATED: Support multiple tables
  final String? tableNumber;
  final String? areaCode;
  final List<String>? tableNumbers;
  final int? totalSeats;
  final bool isMultiTable;

  const GroDineInGuestFormScreen({
    super.key,
    this.tableNumber,
    this.areaCode,
    this.tableNumbers,
    this.totalSeats,
    this.isMultiTable = false,
  }) : assert(
            (tableNumber != null && areaCode != null) ||
                (tableNumbers != null && tableNumbers.length > 0),
            'Either single table or multiple tables must be provided');

  @override
  State<GroDineInGuestFormScreen> createState() =>
      _GroDineInGuestFormScreenState();
}

class _GroDineInGuestFormScreenState extends State<GroDineInGuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late String _displayTableInfo;
  late bool _isMultiTable;

  @override
  void initState() {
    super.initState();
    _isMultiTable = widget.isMultiTable;

// Setup display info
    if (_isMultiTable && widget.tableNumbers != null) {
      _displayTableInfo = widget.tableNumbers!.join(', ');
    } else if (widget.tableNumber != null) {
      _displayTableInfo = widget.tableNumber!;
    } else {
      _displayTableInfo = 'N/A';
    }

    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  void _proceedToMenu() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

// Set guest data untuk GRO dine-in
    cartProvider.setGuestData(
      guestName: _nameController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

// Set dine-in context
    if (_isMultiTable && widget.tableNumbers != null) {
// Multi-table dine-in
      cartProvider.setDineInData(true, widget.tableNumbers!.join(', '));
    } else if (widget.tableNumber != null) {
// Single table dine-in
      cartProvider.setDineInData(true, widget.tableNumber!);
    }

// Navigate to menu
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          isDineIn: true,
          tableNumber: _displayTableInfo,
          isGroMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ TABLET DETECTION
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _isMultiTable ? 'Data Tamu Multi-Meja' : 'Data Tamu Dine-In',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Table Info Card at top
              _buildTableInfoCard(),

              const SizedBox(height: 24),

              // ✅ TWO COLUMN LAYOUT for form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN - Guest Information
                  Expanded(
                    child: _buildSectionCard(
                      title: 'Informasi Tamu',
                      icon: Icons.person,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nama Tamu',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tamu harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'No. Telepon',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'No. telepon harus diisi';
                            }
                            if (value.length < 10) {
                              return 'No. telepon minimal 10 digit';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // RIGHT COLUMN - Notes
                  Expanded(
                    child: _buildSectionCard(
                      title: 'Catatan (Opsional)',
                      icon: Icons.note_outlined,
                      children: [
                        _buildTextField(
                          controller: _notesController,
                          label: 'Catatan',
                          icon: Icons.note_outlined,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ✅ Proceed Button - Full Width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _proceedToMenu : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed
                        ? AppTheme.barajaPrimary.primaryColor
                        : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _canProceed ? 'Lanjut ke Menu' : 'Lengkapi Data Tamu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _canProceed ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              // ✅ Multi-table info banner
              if (_isMultiTable) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesanan akan terkait dengan ${widget.tableNumbers?.length ?? 0} meja'
                          '${widget.totalSeats != null ? " (Total kapasitas: ${widget.totalSeats} orang)" : ""}.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MOBILE LAYOUT (Original) ====================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ UPDATED: Table Info Card with multi-table support
          _buildTableInfoCard(),

          const SizedBox(height: 24),

          // Guest Information Section
          _buildSectionCard(
            title: 'Informasi Tamu',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nama Tamu',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tamu harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'No. Telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'No. telepon harus diisi';
                  }
                  if (value.length < 10) {
                    return 'No. telepon minimal 10 digit';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notes Section
          _buildSectionCard(
            title: 'Catatan (Opsional)',
            icon: Icons.note_outlined,
            children: [
              _buildTextField(
                controller: _notesController,
                label: 'Catatan',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProceed ? _proceedToMenu : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed
                    ? AppTheme.barajaPrimary.primaryColor
                    : Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _canProceed ? 'Lanjut ke Menu' : 'Lengkapi Data Tamu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _canProceed ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),

          // ✅ Multi-table info banner
          if (_isMultiTable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Dine-In Multi-Meja',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pesanan akan terkait dengan ${widget.tableNumbers?.length ?? 0} meja'
                    '${widget.totalSeats != null ? " (Total kapasitas: ${widget.totalSeats} orang)" : ""}.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

// ✅ NEW: Build table info card with multi-table support
  Widget _buildTableInfoCard() {
    if (_isMultiTable && widget.tableNumbers != null) {
// Multi-table display
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.tableNumbers!.length} Meja Dipilih',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.totalSeats != null)
                        Text(
                          'Total Kapasitas: ${widget.totalSeats} orang',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      if (widget.areaCode != null)
                        Text(
                          'Area ${widget.areaCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.totalSeats ?? 0} 👤',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tableNumbers!.map((tableNum) {
                return Chip(
                  label: Text('Meja $tableNum'),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.blue.shade700),
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

// Single table display
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.table_restaurant,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meja ${widget.tableNumber ?? _displayTableInfo}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.areaCode != null)
                  Text(
                    'Area ${widget.areaCode}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.barajaPrimary.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.barajaPrimary.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.barajaPrimary.primaryColor),
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
      validator: validator,
    );
  }
}
