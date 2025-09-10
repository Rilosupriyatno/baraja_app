import 'package:flutter/material.dart';
import '../../models/order_type.dart';

// Enum untuk sub-pilihan Take Away
enum TakeAwayType { delivery, pickup }

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
  TakeAwayType selectedTakeAwayType = TakeAwayType.delivery;

  @override
  void initState() {
    super.initState();
    // Set initial take away type based on current selected order type
    if (widget.selectedType == OrderType.pickup) {
      selectedTakeAwayType = TakeAwayType.pickup;
    }
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

  bool _isTakeAwaySelected() {
    return widget.selectedType == OrderType.delivery || widget.selectedType == OrderType.pickup;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dine In Option (jika tidak disembunyikan)
        if (!widget.hideDineInOption) ...[
          _buildOrderTypeOption(
            type: OrderType.dineIn,
            title: 'Dine In',
            subtitle: 'Makan di tempat',
          ),
        ],

        // Take Away Option
        _buildTakeAwayOption(),
      ],
    );
  }

  Widget _buildOrderTypeOption({
    required OrderType type,
    required String title,
    required String subtitle,
  }) {
    final isSelected = widget.selectedType == type;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<OrderType>(
            value: type,
            groupValue: widget.selectedType,
            onChanged: (OrderType? value) {
              if (value != null) {
                widget.onChanged(value);
              }
            },
            title: Text(title),
            subtitle: Text(subtitle),
            activeColor: Theme.of(context).primaryColor,
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),

        // Input fields untuk Dine In
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isSelected ? null : 0,
          child: isSelected && type == OrderType.dineIn
              ? Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _buildDineInInput(),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTakeAwayOption() {
    final isTakeAwaySelected = _isTakeAwaySelected();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              // Pilih take away type default (delivery) jika belum dipilih
              if (!isTakeAwaySelected) {
                selectedTakeAwayType = TakeAwayType.delivery;
                widget.onChanged(OrderType.delivery);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isTakeAwaySelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isTakeAwaySelected,
                    onChanged: (bool? value) {
                      if (value == true && !isTakeAwaySelected) {
                        selectedTakeAwayType = TakeAwayType.delivery;
                        widget.onChanged(OrderType.delivery);
                      }
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take Away',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Pesan untuk dibawa pulang',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sub-pilihan Take Away
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isTakeAwaySelected ? null : 0,
          child: isTakeAwaySelected
              ? Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _buildTakeAwaySubOptions(),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTakeAwaySubOptions() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Sub-pilihan Delivery
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: RadioListTile<TakeAwayType>(
            value: TakeAwayType.delivery,
            groupValue: selectedTakeAwayType,
            onChanged: (TakeAwayType? value) {
              if (value != null) {
                setState(() {
                  selectedTakeAwayType = value;
                });
                widget.onChanged(OrderType.delivery);
              }
            },
            title: const Text('Delivery'),
            subtitle: const Text('Antar ke alamat Anda'),
            activeColor: Theme.of(context).primaryColor,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selectedTakeAwayType == TakeAwayType.delivery
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),

        // Input untuk Delivery
        if (selectedTakeAwayType == TakeAwayType.delivery) ...[
          Padding(
            padding: const EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 12),
            child: TextFormField(
              initialValue: widget.deliveryAddress,
              decoration: InputDecoration(
                labelText: 'Alamat Pengantaran',
                hintText: 'Masukkan alamat lengkap',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              ),
              maxLines: 2,
              onChanged: widget.onDeliveryAddressChanged,
            ),
          ),
        ],

        // Sub-pilihan Pickup
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: RadioListTile<TakeAwayType>(
            value: TakeAwayType.pickup,
            groupValue: selectedTakeAwayType,
            onChanged: (TakeAwayType? value) {
              if (value != null) {
                setState(() {
                  selectedTakeAwayType = value;
                });
                widget.onChanged(OrderType.pickup);
              }
            },
            title: const Text('Pickup'),
            subtitle: const Text('Ambil sendiri di resto (min. 5 menit dari sekarang)'),
            activeColor: Theme.of(context).primaryColor,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selectedTakeAwayType == TakeAwayType.pickup
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),

        // Input untuk Pickup
        if (selectedTakeAwayType == TakeAwayType.pickup) ...[
          Padding(
            padding: const EdgeInsets.only(left: 22, right: 22, top: 8, bottom: 12),
            child: InkWell(
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.pickupTime != null && _isValidPickupTime(widget.pickupTime!)
                        ? Colors.grey.shade300
                        : Colors.red.shade300,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: widget.pickupTime != null && !_isValidPickupTime(widget.pickupTime!)
                      ? Colors.red.shade50
                      : Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.pickupTime != null
                            ? 'Waktu: ${widget.pickupTime!.format(context)}'
                            : 'Pilih waktu pengambilan',
                        style: TextStyle(
                          color: widget.pickupTime != null
                              ? (_isValidPickupTime(widget.pickupTime!) ? Colors.black : Colors.red.shade700)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Icon(Icons.access_time, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDineInInput() {
    return Column(
      children: [
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.tableNumber,
          decoration: InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Masukkan nomor meja',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          onChanged: widget.onTableNumberChanged,
        ),
      ],
    );
  }
}