import 'package:flutter/material.dart';
import '../../models/order_type.dart';

class OrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final Function(OrderType) onChanged;
  final String tableNumber;
  final Function(String) onTableNumberChanged;
  final String deliveryAddress;
  final Function(String) onDeliveryAddressChanged;
  final TimeOfDay? pickupTime;
  final Function(TimeOfDay?) onPickupTimeChanged;
  final bool hideDineInOption; // Parameter baru untuk menyembunyikan dine-in

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
    this.hideDineInOption = false, // Default false untuk backward compatibility
  });

  // Method untuk mendapatkan waktu minimum pickup (5 menit dari sekarang)
  TimeOfDay _getMinimumPickupTime() {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));
    return TimeOfDay.fromDateTime(minimumTime);
  }

  // Method untuk mengecek apakah waktu yang dipilih valid
  bool _isValidPickupTime(TimeOfDay selectedTime) {
    final now = DateTime.now();
    final minimumTime = now.add(const Duration(minutes: 5));

    // Convert TimeOfDay to DateTime untuk perbandingan
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    return selectedDateTime.isAfter(minimumTime) || selectedDateTime.isAtSameMomentAs(minimumTime);
  }

  // Method untuk menampilkan pesan error waktu pickup
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
    // Buat list order types berdasarkan parameter hideDineInOption
    List<OrderType> availableOrderTypes = [];

    if (!hideDineInOption) {
      availableOrderTypes.add(OrderType.dineIn);
    }
    availableOrderTypes.addAll([OrderType.delivery, OrderType.pickup]);

    return Column(
      children: [
        // Order Type Selection
        ...availableOrderTypes.map((type) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: RadioListTile<OrderType>(
              value: type,
              groupValue: selectedType,
              onChanged: (OrderType? value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              title: Text(_getOrderTypeTitle(type)),
              subtitle: Text(_getOrderTypeSubtitle(type)),
              activeColor: Theme.of(context).primaryColor,
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selectedType == type
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }),

        // Additional Input Fields Based on Selected Type
        if (!hideDineInOption && selectedType == OrderType.dineIn) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: tableNumber,
            decoration: const InputDecoration(
              labelText: 'Nomor Meja',
              hintText: 'Masukkan nomor meja',
              border: OutlineInputBorder(),
            ),
            onChanged: onTableNumberChanged,
          ),
        ],

        if (selectedType == OrderType.delivery) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: deliveryAddress,
            decoration: const InputDecoration(
              labelText: 'Alamat Pengantaran',
              hintText: 'Masukkan alamat lengkap',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: onDeliveryAddressChanged,
          ),
        ],

        if (selectedType == OrderType.pickup) ...[
          const SizedBox(height: 8),
          // Info box untuk minimum waktu pickup
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waktu pickup minimal ${_getMinimumPickupTime().format(context)} (5 menit dari sekarang)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () async {
              final TimeOfDay minimumTime = _getMinimumPickupTime();

              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: pickupTime ?? minimumTime,
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  );
                },
              );

              if (time != null) {
                // Validasi waktu yang dipilih
                if (_isValidPickupTime(time)) {
                  onPickupTimeChanged(time);
                } else {
                  // Reset ke null jika waktu tidak valid
                  onPickupTimeChanged(null);
                  _showPickupTimeError(context);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: pickupTime != null && _isValidPickupTime(pickupTime!)
                      ? Colors.grey.shade300
                      : Colors.red.shade300,
                ),
                borderRadius: BorderRadius.circular(4),
                color: pickupTime != null && !_isValidPickupTime(pickupTime!)
                    ? Colors.red.shade50
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupTime != null
                              ? 'Waktu: ${pickupTime!.format(context)}'
                              : 'Pilih waktu pengambilan',
                          style: TextStyle(
                            color: pickupTime != null
                                ? (_isValidPickupTime(pickupTime!) ? Colors.black : Colors.red.shade700)
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (pickupTime != null && !_isValidPickupTime(pickupTime!))
                          Text(
                            'Waktu terlalu dekat, minimal ${_getMinimumPickupTime().format(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    color: pickupTime != null && !_isValidPickupTime(pickupTime!)
                        ? Colors.red.shade600
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getOrderTypeTitle(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Dine In';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Pickup';
      case OrderType.reservation:
        return 'Reservation';
    }
  }

  String _getOrderTypeSubtitle(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di tempat';
      case OrderType.delivery:
        return 'Antar ke alamat Anda';
      case OrderType.pickup:
        return 'Ambil sendiri di resto (min. 5 menit dari sekarang)';
      case OrderType.reservation:
        return 'Reservasi meja untuk kunjungan Anda';
    }
  }
}