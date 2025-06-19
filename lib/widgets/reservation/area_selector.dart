// widgets/reservation/area_selector.dart
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
                childAspectRatio: 1.0,
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

    return InkWell(
      onTap: area.isActive ? () => onAreaChanged(area) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppTheme.barajaPrimary.primaryColor
                : area.isActive
                ? Colors.grey.shade300
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: area.isActive ? Colors.white : Colors.grey.shade50,
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
                color: isSelected
                    ? AppTheme.barajaPrimary.primaryColor
                    : area.isActive
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
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
                color: isSelected
                    ? AppTheme.barajaPrimary.primaryColor
                    : area.isActive
                    ? Colors.black87
                    : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Capacity and Tables Info
            Text(
              '${area.capacity} kursi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),

            // Show table availability if tables data is available
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

            // Availability indicator
            if (area.totalTables > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: area.availableTables > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      area.availableTables > 0 ? 'Tersedia' : 'Penuh',
                      style: TextStyle(
                        color: area.availableTables > 0
                            ? Colors.green
                            : Colors.red,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}