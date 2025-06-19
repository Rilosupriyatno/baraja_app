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
          InkWell(
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: pickupTime ?? TimeOfDay.now(),
              );
              onPickupTimeChanged(time);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pickupTime != null
                        ? 'Waktu: ${pickupTime!.format(context)}'
                        : 'Pilih waktu pengambilan',
                    style: TextStyle(
                      color: pickupTime != null ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.access_time),
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
    }
  }

  String _getOrderTypeSubtitle(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di tempat';
      case OrderType.delivery:
        return 'Antar ke alamat Anda';
      case OrderType.pickup:
        return 'Ambil sendiri di resto';
    }
  }
}