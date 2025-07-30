// widgets/reservation/area_selector.dart - Updated with real-time availability
import 'package:flutter/material.dart';
import '../../models/area.dart';
import '../../theme/app_theme.dart';

class AreaSelector extends StatelessWidget {
  final List<Area> areas;
  final String? selectedAreaId;
  final Function(Area) onAreaChanged;
  final bool isLoading;

  const AreaSelector({
    super.key,
    required this.areas,
    required this.selectedAreaId,
    required this.onAreaChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Pilih Area',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (areas.isEmpty)
            const Center(
              child: Text(
                'Tidak ada area tersedia',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final area = areas[index];
                return _buildAreaOption(area);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAreaOption(Area area) {
    final isSelected = selectedAreaId == area.id;
    final hasAvailability = area.hasAvailability;
    final isFullyBooked = area.isFullyBooked;

    // Determine colors based on availability
    Color borderColor;
    Color backgroundColor;
    Color circleColor;
    Color textColor;

    if (isSelected) {
      borderColor = AppTheme.barajaPrimary.primaryColor;
      backgroundColor = Colors.white;
      circleColor = AppTheme.barajaPrimary.primaryColor;
      textColor = AppTheme.barajaPrimary.primaryColor;
    } else if (!area.isActive) {
      borderColor = Colors.grey.shade200;
      backgroundColor = Colors.grey.shade50;
      circleColor = Colors.grey.shade200;
      textColor = Colors.grey;
    } else if (isFullyBooked) {
      borderColor = Colors.red.shade200;
      backgroundColor = Colors.red.shade50;
      circleColor = Colors.red.shade200;
      textColor = Colors.red.shade700;
    } else if (!hasAvailability) {
      borderColor = Colors.orange.shade200;
      backgroundColor = Colors.orange.shade50;
      circleColor = Colors.orange.shade200;
      textColor = Colors.orange.shade700;
    } else {
      borderColor = Colors.grey.shade300;
      backgroundColor = Colors.white;
      circleColor = Colors.grey.shade300;
      textColor = Colors.black87;
    }

    return InkWell(
      onTap: area.isActive && hasAvailability ? () => onAreaChanged(area) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Area Code Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: Center(
                child: Text(
                  area.areaCode,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Area Name
            Text(
              area.areaName,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Capacity Info
            Text(
              '${area.availableCapacity}/${area.capacity} kursi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),

            // Tables Info
            if (area.totalTables > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 10,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${area.availableTables}/${area.totalTables}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),

            // Availability Status
            _buildAvailabilityStatus(area),

            // Occupancy Rate (if area has reservations)
            if (area.totalReservedGuests > 0) ...[
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: area.capacityUsage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  area.capacityUsage > 0.8
                      ? Colors.red
                      : area.capacityUsage > 0.6
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatus(Area area) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!area.isActive) {
      statusText = 'Tidak Aktif';
      statusColor = Colors.grey;
      statusIcon = Icons.block;
    } else if (area.isFullyBooked) {
      statusText = 'Penuh';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (area.availableTables == 0) {
      statusText = 'Meja Habis';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (area.availableCapacity <= 0) {
      statusText = 'Kapasitas Penuh';
      statusColor = Colors.orange;
      statusIcon = Icons.people;
    } else {
      statusText = 'Tersedia';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: 8,
            color: statusColor,
          ),
          const SizedBox(width: 2),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}