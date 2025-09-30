import 'package:flutter/material.dart';
import '../../models/order_type.dart';
import '../../services/table_Service.dart';

class OrderTypeSelector extends StatefulWidget {
  final OrderType selectedType;
  final Function(OrderType) onChanged;
  final String tableNumber;
  final Function(String) onTableNumberChanged;
  final String deliveryAddress;
  final Function(String) onDeliveryAddressChanged;
  final TimeOfDay? pickupTime;
  final Function(TimeOfDay?) onPickupTimeChanged;
  final bool hideDineInOption;

  const OrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    required this.tableNumber,
    required this.onTableNumberChanged,
    required this.deliveryAddress,
    required this.onDeliveryAddressChanged,
    required this.pickupTime,
    required this.onPickupTimeChanged,
    this.hideDineInOption = false,
  });

  @override
  State<OrderTypeSelector> createState() => _OrderTypeSelectorState();
}

class _OrderTypeSelectorState extends State<OrderTypeSelector> {
  final TableService _tableService = TableService();
  bool _isCheckingTable = false;
  String? _tableError;

  @override
  void initState() {
    super.initState();
  }

  TimeOfDay _getMinimumPickupTime() {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));
    return TimeOfDay.fromDateTime(minimumTime);
  }

  bool _isValidPickupTime(TimeOfDay selectedTime) {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
  }

  void _showPickupTimeError(BuildContext context) {
    final minimumTime = _getMinimumPickupTime();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Waktu pickup minimal ${minimumTime.format(context)} (5 menit dari sekarang)',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab-style Order Type Selector
        _buildTabSelector(),

        const SizedBox(height: 16),

        // Content based on selected type
        _buildSelectedContent(),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Row pertama: Dine-In, Take Away
          Row(
            children: [
              // Dine In Tab
              if (!widget.hideDineInOption)
                Expanded(
                  child: _buildTab(
                    type: OrderType.dineIn,
                    label: 'Dine-In',
                    subtitle: 'Makan Ditempat',
                    isSelected: widget.selectedType == OrderType.dineIn,
                  ),
                ),

              // Take Away Tab
              Expanded(
                child: _buildTab(
                  type: OrderType.takeAway,
                  label: 'Take Away',
                  subtitle: 'Beli dan bawa pulang',
                  isSelected: widget.selectedType == OrderType.takeAway,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row kedua: Pickup, Delivery
          Row(
            children: [
              // Pickup Tab
              Expanded(
                child: _buildTab(
                  type: OrderType.pickup,
                  label: 'Pickup',
                  subtitle: 'Pesan dulu, ambil nanti',
                  isSelected: widget.selectedType == OrderType.pickup,
                ),
              ),

              // Delivery Tab - DISABLED
              Expanded(
                child: _buildTab(
                  type: OrderType.delivery,
                  label: 'Delivery',
                  subtitle: 'Segera Datang',
                  isSelected: widget.selectedType == OrderType.delivery,
                  isDisabled: true, // ✅ DISABLED
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required OrderType type,
    required String label,
    required String subtitle,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    final Color backgroundColor = isSelected
        ? Colors.white
        : Colors.transparent;

    final Color textColor = isDisabled
        ? Colors.grey.shade400
        : (isSelected ? const Color(0xFF0E9658) : Colors.grey.shade700);

    return GestureDetector(
      onTap: isDisabled ? null : () {
        widget.onChanged(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (widget.selectedType) {
      case OrderType.dineIn:
        return _buildDineInContent();
      case OrderType.delivery:
        return _buildDeliveryContent();
      case OrderType.pickup:
        return _buildPickupContent();
      case OrderType.takeAway:
        return _buildTakeAwayContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDineInContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Meja',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.tableNumber,
          decoration: InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Masukkan nomor meja',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            errorText: _tableError,
            suffixIcon: _isCheckingTable
                ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : _tableError == null && widget.tableNumber.isNotEmpty
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          onChanged: (value) {
            widget.onTableNumberChanged(value);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (value == widget.tableNumber) {
                _validateTableNumber(value);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTakeAwayContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: Colors.green.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take Away',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesanan akan disiapkan dan dapat langsung dibawa pulang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED - Delivery Content dengan status disabled
  Widget _buildDeliveryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitur Delivery Segera Datang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Layanan pengantaran sedang dalam tahap persiapan dan akan segera tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Disabled Delivery Address Field
        const Text(
          'Informasi Pengiriman',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: false, // ✅ DISABLED
          initialValue: widget.deliveryAddress,
          decoration: InputDecoration(
            labelText: 'Alamat Pengantaran',
            hintText: 'Fitur belum tersedia',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade200, // ✅ Abu-abu untuk menunjukkan disabled
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey.shade500,
            ),
          ),
          maxLines: 3,
          onChanged: widget.onDeliveryAddressChanged,
        ),
      ],
    );
  }

  Widget _buildPickupContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Pickup',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay minimumTime = _getMinimumPickupTime();
            final TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: widget.pickupTime ?? minimumTime,
            );
            if (time != null) {
              if (_isValidPickupTime(time)) {
                widget.onPickupTimeChanged(time);
              } else {
                widget.onPickupTimeChanged(null);
                _showPickupTimeError(context);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.pickupTime != null && _isValidPickupTime(widget.pickupTime!)
                    ? Colors.grey.shade300
                    : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
              color: widget.pickupTime != null && !_isValidPickupTime(widget.pickupTime!)
                  ? Colors.red.shade50
                  : Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Pengambilan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.pickupTime != null
                            ? widget.pickupTime!.format(context)
                            : 'Pilih waktu (min. 5 menit dari sekarang)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.pickupTime != null
                              ? (_isValidPickupTime(widget.pickupTime!)
                              ? Colors.black
                              : Colors.red.shade700)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.access_time, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _validateTableNumber(String tableNumber) async {
    if (tableNumber.isEmpty) {
      setState(() {
        _tableError = null;
      });
      return;
    }

    setState(() {
      _isCheckingTable = true;
      _tableError = null;
    });

    try {
      final result = await _tableService.checkTableAvailability(tableNumber);

      if (!result['isAvailable']) {
        setState(() {
          _tableError = result['message'] ?? 'Meja tidak tersedia';
        });
      }
    } catch (e) {
      setState(() {
        _tableError = 'Gagal mengecek ketersediaan meja';
      });
    } finally {
      setState(() {
        _isCheckingTable = false;
      });
    }
  }
}