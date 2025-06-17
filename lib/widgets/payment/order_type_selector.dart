import 'package:flutter/material.dart';
import '../../models/order_type.dart';

class OrderTypeSelector extends StatefulWidget {
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
  State<OrderTypeSelector> createState() => _OrderTypeSelectorState();
}

class _OrderTypeSelectorState extends State<OrderTypeSelector> {
  // Controllers for text fields to avoid rebuilding during typing
  late TextEditingController _tableNumberController;
  late TextEditingController _deliveryAddressController;

  // Flag to track if fields should be shown
  bool _showFields = false;

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(text: widget.tableNumber);
    _deliveryAddressController = TextEditingController(text: widget.deliveryAddress);

    // Set initial show fields state
    _showFields = true;
  }

  @override
  void didUpdateWidget(OrderTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update controllers when values change externally
    if (oldWidget.tableNumber != widget.tableNumber &&
        _tableNumberController.text != widget.tableNumber) {
      _tableNumberController.text = widget.tableNumber;
    }

    if (oldWidget.deliveryAddress != widget.deliveryAddress &&
        _deliveryAddressController.text != widget.deliveryAddress) {
      _deliveryAddressController.text = widget.deliveryAddress;
    }
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab-style selector
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

        // Only show additional fields if _showFields is true
        if (_showFields) _buildAdditionalFields(context),
      ],
    );
  }

  Widget _buildTypeTab(BuildContext context, OrderType type, String label, IconData icon) {
    final isSelected = widget.selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Set _showFields to false before changing type to hide animations
          setState(() {
            _showFields = false;
          });

          // Change the type
          widget.onChanged(type);

          // Show fields after a short delay
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _showFields = true;
              });
            }
          });
        },
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
    return AnimatedOpacity(
      opacity: _showFields ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: _buildFieldsForSelectedType(context),
    );
  }

  Widget _buildFieldsForSelectedType(BuildContext context) {
    switch (widget.selectedType) {
      case OrderType.dineIn:
        return _buildDineInFields();
      case OrderType.delivery:
        return _buildDeliveryFields();
      case OrderType.pickup:
        return _buildPickupFields(context);
    }
  }

  Widget _buildDineInFields() {
    // Using the controller and avoiding recreating it on each build
    return TextField(
      decoration: const InputDecoration(
        labelText: "Nomor meja",
        hintText: "Masukkan nomor meja",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: TextInputType.text,
      controller: _tableNumberController,
      onChanged: widget.onTableNumberChanged,
    );
  }

  Widget _buildDeliveryFields() {
    // Using the controller and avoiding recreating it on each build
    return TextField(
      decoration: const InputDecoration(
        labelText: "Alamat pengantaran",
        hintText: "Masukkan alamat pengantaran",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLines: 3,
      controller: _deliveryAddressController,
      onChanged: widget.onDeliveryAddressChanged,
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
              initialTime: widget.pickupTime ?? TimeOfDay.now(),
            );

            if (time != null) {
              widget.onPickupTimeChanged(time);
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
                  widget.pickupTime != null
                      ? "Penjemputan di: ${widget.pickupTime!.format(context)}"
                      : "Pilih waktu penjemputan",
                  style: TextStyle(
                    color: widget.pickupTime != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
        if (widget.pickupTime != null) ...[
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