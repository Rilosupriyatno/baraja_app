import 'package:flutter/material.dart';

class ReservationSectionWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const ReservationSectionWidget({
    super.key,
    required this.orderData,
  });

  // Reservation helper methods
  static const Map<String, String> _reservationStatusMap = {
    'confirmed': 'Dikonfirmasi',
    'pending': 'Menunggu',
    'cancelled': 'Dibatalkan',
    'completed': 'Selesai',
  };

  static const Map<String, Color> _reservationStatusColors = {
    'confirmed': Colors.green,
    'pending': Colors.orange,
    'cancelled': Colors.red,
    'completed': Colors.blue,
  };

  String _getReservationStatusText(String? status) =>
      _reservationStatusMap[status?.toLowerCase()] ?? 'Unknown';

  Color _getReservationStatusColor(String? status) =>
      _reservationStatusColors[status?.toLowerCase()] ?? Colors.grey;

  String _getReservationTypeText(String? type) {
    const typeMap = {
      'non-blocking': 'Non-Blocking',
      'blocking': 'Blocking',
    };
    return typeMap[type?.toLowerCase()] ?? type ?? 'Unknown';
  }

  String _getTableTypeText(String? type) {
    const typeMap = {
      'regular': 'Regular',
      'vip': 'VIP',
      'outdoor': 'Outdoor',
    };
    return typeMap[type?.toLowerCase()] ?? type ?? 'Regular';
  }

  int _calculateTotalSeats(List tables) =>
      tables.fold(0, (total, table) => total + ((table['seats'] as int?) ?? 0));

  @override
  Widget build(BuildContext context) {
    final reservation = orderData['reservation'] as Map<String, dynamic>?;
    if (reservation == null) return const SizedBox.shrink();

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
              color: Colors.blue.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_seat_rounded, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Reservasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation['reservationCode'] ?? '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getReservationStatusColor(reservation['status']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getReservationStatusColor(reservation['status']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getReservationStatusText(reservation['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getReservationStatusColor(reservation['status']),
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
                ..._buildReservationDetails(reservation),
                if (reservation['tables'] != null && (reservation['tables'] as List).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),
                  _buildTablesSection(reservation['tables'] as List),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReservationDetails(Map<String, dynamic> reservation) {
    final details = [
      {
        'icon': Icons.calendar_today_rounded,
        'color': Colors.orange,
        'title': 'Tanggal & Waktu',
        'value': '${reservation['reservationDate']} • ${reservation['reservationTime']}',
      },
      {
        'icon': Icons.people_rounded,
        'color': Colors.green,
        'title': 'Jumlah Tamu',
        'value': '${reservation['guestCount']} orang',
      },
      {
        'icon': Icons.location_on_rounded,
        'color': Colors.purple,
        'title': 'Area',
        'value': reservation['area']?['name'] ?? 'Area tidak tersedia',
      },
      {
        'icon': Icons.bookmark_rounded,
        'color': Colors.indigo,
        'title': 'Tipe Reservasi',
        'value': _getReservationTypeText(reservation['reservationType']),
      },
    ];

    if (reservation['notes']?.toString().isNotEmpty == true) {
      details.add({
        'icon': Icons.note_rounded,
        'color': Colors.amber,
        'title': 'Catatan',
        'value': reservation['notes'],
      });
    }

    return details.map((detail) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildReservationDetailRow(
        icon: detail['icon'] as IconData,
        iconColor: detail['color'] as Color,
        title: detail['title'] as String,
        value: detail['value'] as String,
      ),
    )).toList();
  }

  Widget _buildReservationDetailRow({
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

  Widget _buildTablesSection(List tables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.table_restaurant_rounded, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Text(
              'Meja yang Dipesan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tables.length} meja',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) => _buildTableCard(tables[index]),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_seat_rounded, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Total Kapasitas: ${_calculateTotalSeats(tables)} kursi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final isValidTable = (table['isAvailable'] ?? true) && (table['isActive'] ?? true);
    final color = isValidTable ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  table['tableNumber'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isValidTable ? Colors.green[700] : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${table['seats'] ?? 0} kursi • ${_getTableTypeText(table['tableType'])}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}