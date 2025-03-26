import 'package:flutter/material.dart';
import '../../models/order_type.dart';

class OrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final Function(OrderType) onChanged;

  // Dine-in properties
  final String tableNumber;
  final Function(String) onTableNumberChanged;

  // Delivery properties
  final String deliveryAddress;
  final Function(String) onDeliveryAddressChanged;

  // Pickup properties
  final TimeOfDay? pickupTime;
  final Function(TimeOfDay) onPickupTimeChanged;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab-style selector instead of radio buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTypeTab(
                context,
                OrderType.dineIn,
                "Dine-in",
                Icons.restaurant,
              ),
              _buildTypeTab(
                context,
                OrderType.delivery,
                "Delivery",
                Icons.delivery_dining,
              ),
              _buildTypeTab(
                context,
                OrderType.pickup,
                "Pickup",
                Icons.store,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Additional fields based on selected order type
        _buildAdditionalFields(context),
      ],
    );
  }

  Widget _buildTypeTab(BuildContext context, OrderType type, String label, IconData icon) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalFields(BuildContext context) {
    switch (selectedType) {
      case OrderType.dineIn:
        return _buildDineInFields();
      case OrderType.delivery:
        return _buildDeliveryFields();
      case OrderType.pickup:
        return _buildPickupFields(context);
    }
  }

  Widget _buildDineInFields() {
    return TextField(
      decoration: const InputDecoration(
        labelText: "Nomor meja",
        hintText: "Masukkan nomor meja",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: tableNumber),
      onChanged: onTableNumberChanged,
    );
  }

  Widget _buildDeliveryFields() {
    return TextField(
      decoration: const InputDecoration(
        labelText: "Alamat pengantaran",
        hintText: "Masukkan alamat pengantaran",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLines: 3,
      controller: TextEditingController(text: deliveryAddress),
      onChanged: onDeliveryAddressChanged,
    );
  }

  Widget _buildPickupFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: pickupTime ?? TimeOfDay.now(),
            );

            if (time != null) {
              onPickupTimeChanged(time);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pickupTime != null
                      ? "Penjemputan di: ${pickupTime!.format(context)}"
                      : "Pilih waktu penjemputan",
                  style: TextStyle(
                    color: pickupTime != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
        if (pickupTime != null) ...[
          const SizedBox(height: 12),
          Text(
            "* Harap tiba 10-15 menit sebelum waktu penjemputan",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// Catatan: Extension ini tidak digunakan di kode ini
// karena kita langsung menggunakan TextEditingController
// Contoh implementasi extension yang benar jika diperlukan:
/*
extension TextFieldExtension on TextField {
  TextField copyWith({TextEditingController? controller, Function(String)? onChanged}) {
    return TextField(
      controller: controller ?? this.controller,
      decoration: decoration,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged ?? this.onChanged,
    );
  }
}
*/