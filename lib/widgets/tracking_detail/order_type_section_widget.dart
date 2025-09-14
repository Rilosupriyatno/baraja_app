import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderTypeSectionWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderTypeSectionWidget({
    super.key,
    required this.orderData,
  });

  String _formatPickupTime(String rawTime) {
    try {
      // Contoh input: "Sun Sep 14 2025 17:54:00 GMT+0700 (Waktu Indonesia Barat)"
      final index = rawTime.indexOf(' GMT');
      final cleaned = index != -1 ? rawTime.substring(0, index) : rawTime;

      // Parsing dengan format bahasa Inggris
      final formatterInput = DateFormat('EEE MMM dd yyyy HH:mm:ss', 'en_US');
      final dateTime = formatterInput.parse(cleaned);

      // Format output dengan hari, tanggal, bulan singkat, tahun dan jam:menit dalam bahasa Indonesia
      final formatterOutput = DateFormat('EEEE, dd MMM yyyy HH:mm', 'id_ID');
      return formatterOutput.format(dateTime);
    } catch (e) {
      return rawTime; // fallback jika gagal parsing
    }
  }

  // Helper method to get order type from data
  String _getOrderType() {
    if (orderData['dineInData'] != null) {
      return 'Dine-In';
    } else if (orderData['pickupData'] != null) {
      return 'Pickup';
    } else if (orderData['takeAwayData'] != null) {
      return 'Take Away';
    } else if (orderData['deliveryData'] != null) {
      return 'Delivery';
    } else {
      return 'Unknown';
    }
  }

  // Helper method to determine if we should show this widget
  bool _shouldShowOrderTypeSection() {
    final orderType = _getOrderType();
    print("ini adalah isi orderData di section: $orderData");
    return orderType != 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowOrderTypeSection()) {
      return const SizedBox.shrink();
    }

    final orderType = _getOrderType();

    switch (orderType) {
      case 'Dine-In':
        return _buildDineInSection();
      case 'Pickup':
        return _buildPickupSection();
      case 'Take Away':
        return _buildTakeAwaySection();
      case 'Delivery':
        return _buildDeliverySection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDineInSection() {
    final dineInData = orderData['dineInData'] as Map<String, dynamic>?;
    if (dineInData == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Dine In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Makan di tempat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Dine In',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.table_restaurant_rounded,
                  iconColor: Colors.orange,
                  title: 'Nomor Meja',
                  value: dineInData['tableNumber']?.toString() ?? 'Belum ditentukan',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'Keterangan',
                  value: 'Pesanan akan disajikan langsung ke meja Anda',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSection() {
    final pickupData = orderData['pickupData'] as Map<String, dynamic>?;
    if (pickupData == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store_rounded, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Pickup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ambil di lokasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Pickup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (pickupData['pickupTime'] != null) ...[
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    iconColor: Colors.green,
                    title: 'Waktu Pickup',
                    value: _formatPickupTime(pickupData['pickupTime'].toString()),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.purple,
                  title: 'Lokasi Pickup',
                  value: 'Ambil pesanan di kasir outlet',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'Keterangan',
                  value: 'Tunjukkan nomor pesanan saat mengambil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeAwaySection() {
    final takeAwayData = orderData['takeAwayData'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.takeout_dining_rounded, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Take Away',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dibawa pulang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Take Away',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.shopping_bag_rounded,
                  iconColor: Colors.teal,
                  title: 'Kemasan',
                  value: 'Pesanan dikemas untuk dibawa pulang',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.purple,
                  title: 'Pengambilan',
                  value: 'Ambil pesanan di kasir outlet',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'Keterangan',
                  value: takeAwayData?['note']?.toString() ?? 'Pesanan siap dibawa pulang',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDeliverySection() {
    final deliveryData = orderData['deliveryData'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Antar ke alamat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.indigo.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Delivery',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.indigo,
                  title: 'Alamat Pengiriman',
                  value: deliveryData?['deliveryAddress']?.toString() ?? 'Alamat tidak tersedia',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.local_shipping_rounded,
                  iconColor: Colors.purple,
                  title: 'Metode Pengiriman',
                  value: 'Kurir akan mengantar ke alamat Anda',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'Keterangan',
                  value: 'Pastikan alamat dan nomor telepon dapat dihubungi',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}