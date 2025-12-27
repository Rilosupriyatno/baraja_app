import 'package:flutter/material.dart';
import '../../../models/order_type.dart';
import '../../../widgets/checkout/order_type_selector.dart';

class OrderTypeSelectorWithValidation extends StatelessWidget {
  final OrderType selectedType;
  final Function(OrderType) onChanged;
  final String tableNumber;
  final Function(String) onTableNumberChanged;
  final String deliveryAddress;
  final Function(String) onDeliveryAddressChanged;
  final TimeOfDay? pickupTime;
  final Function(TimeOfDay?) onPickupTimeChanged;
  final Map<String, String> validationErrors;
  final bool hasAttemptedSubmit;
  final bool isGroMode; // ✅ NEW: GRO Mode flag

  const OrderTypeSelectorWithValidation({
    super.key,
    required this.selectedType,
    required this.onChanged,
    required this.tableNumber,
    required this.onTableNumberChanged,
    required this.deliveryAddress,
    required this.onDeliveryAddressChanged,
    required this.pickupTime,
    required this.onPickupTimeChanged,
    required this.validationErrors,
    required this.hasAttemptedSubmit,
    this.isGroMode = false, // ✅ NEW: Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrderTypeSelector(
          selectedType: selectedType,
          onChanged: onChanged,
          tableNumber: tableNumber,
          onTableNumberChanged: onTableNumberChanged,
          deliveryAddress: deliveryAddress,
          onDeliveryAddressChanged: onDeliveryAddressChanged,
          pickupTime: pickupTime,
          onPickupTimeChanged: onPickupTimeChanged,
          hideDineInOption: false,
          isGroMode: isGroMode, // ✅ NEW: Pass isGroMode to OrderTypeSelector
        ),
        if (selectedType == OrderType.delivery)
          _buildErrorMessage(validationErrors['deliveryAddress']),
        if (selectedType == OrderType.pickup)
          _buildErrorMessage(validationErrors['pickupTime']),
        if (selectedType == OrderType.dineIn)
          _buildErrorMessage(validationErrors['tableNumber']),
      ],
    );
  }

  Widget _buildErrorMessage(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Text(error, style: const TextStyle(color: Colors.red, fontSize: 12));
  }
}
