// widgets/reservation/food_serving_selector.dart - Updated with default time
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class FoodServingSelector extends StatefulWidget {
  final String? selectedServingOption;
  final DateTime? selectedServingTime;
  final Function(String?, DateTime?) onServingChanged;

  const FoodServingSelector({
    super.key,
    required this.selectedServingOption,
    required this.selectedServingTime,
    required this.onServingChanged,
  });

  @override
  State<FoodServingSelector> createState() => _FoodServingSelectorState();
}

class _FoodServingSelectorState extends State<FoodServingSelector> {
  Future<void> _selectServingTime(BuildContext context) async {
    // PENTING: Gunakan selectedServingTime sebagai initial time
    // Jika selectedServingTime null, seharusnya tidak mungkin karena sudah di-set default
    final TimeOfDay initialTime = widget.selectedServingTime != null
        ? TimeOfDay(
      hour: widget.selectedServingTime!.hour,
      minute: widget.selectedServingTime!.minute,
    )
        : TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Ambil tanggal dari selectedServingTime, BUKAN dari DateTime.now()
      final baseDate = widget.selectedServingTime!;
      final selectedDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      widget.onServingChanged(widget.selectedServingOption, selectedDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan waktu default (dari time selector) jika ada
    final displayTime = widget.selectedServingTime;

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
          Row(
            children: [
              Icon(
                Icons.restaurant,
                color: AppTheme.barajaPrimary.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Waktu Penyajian Makanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.barajaPrimary.primaryColor,
                ),
              ),
          ],
          ),
          const SizedBox(height: 12),

          // Serving Options
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.onServingChanged('immediate', null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.selectedServingOption == 'immediate'
                          ? AppTheme.barajaPrimary.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.selectedServingOption == 'immediate'
                            ? AppTheme.barajaPrimary.primaryColor
                            : Colors.grey.shade300,
                        width: widget.selectedServingOption == 'immediate' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fast_forward,
                          size: 28,
                          color: widget.selectedServingOption == 'immediate'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Segera',
                          style: TextStyle(
                            color: widget.selectedServingOption == 'immediate'
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: widget.selectedServingOption == 'immediate'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saat tamu datang',
                          style: TextStyle(
                            color: widget.selectedServingOption == 'immediate'
                                ? Colors.white70
                                : Colors.grey.shade600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Gunakan waktu yang sudah ada atau null
                    widget.onServingChanged('scheduled', displayTime);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.selectedServingOption == 'scheduled'
                          ? AppTheme.barajaPrimary.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.selectedServingOption == 'scheduled'
                            ? AppTheme.barajaPrimary.primaryColor
                            : Colors.grey.shade300,
                        width: widget.selectedServingOption == 'scheduled' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 28,
                          color: widget.selectedServingOption == 'scheduled'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dijadwalkan',
                          style: TextStyle(
                            color: widget.selectedServingOption == 'scheduled'
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: widget.selectedServingOption == 'scheduled'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih waktu',
                          style: TextStyle(
                            color: widget.selectedServingOption == 'scheduled'
                                ? Colors.white70
                                : Colors.grey.shade600,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Time picker for scheduled option
          if (widget.selectedServingOption == 'scheduled') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectServingTime(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.barajaPrimary.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.barajaPrimary.primaryColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppTheme.barajaPrimary.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waktu Penyajian',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayTime != null
                                ? DateFormat('HH:mm').format(displayTime)
                                : 'Pilih waktu penyajian',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.barajaPrimary.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.barajaPrimary.primaryColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Default mengikuti waktu reservasi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}