import 'package:flutter/material.dart';
import '../../../models/reservation_data.dart';
import '../../screens/checkout_page.dart';

class ReservationTypeSelectorWidget extends StatelessWidget {
  final ReservationData data;
  final int finalTotal;
  final ReservationType selectedReservationType;
  final bool hasAttemptedSubmit;
  final Map<String, String> validationErrors;
  final Function(ReservationType) onChanged;

  const ReservationTypeSelectorWidget({
    super.key,
    required this.data,
    required this.finalTotal,
    required this.selectedReservationType,
    required this.hasAttemptedSubmit,
    required this.validationErrors,
    required this.onChanged,
  });

  // apakah area code butuh pilihan reservation type
  bool _shouldShowReservationType(String? areaCode) {
    return areaCode == 'A' || areaCode == 'B';
  }

  // cek apakah blocking bisa dipilih
  bool _canSelectBlocking(String? areaCode, int totalAmount) {
    if (areaCode == 'A') {
      return totalAmount >= 3000000;
    } else if (areaCode == 'B') {
      return totalAmount >= 2000000;
    }
    return false;
  }

  // minimum amount untuk blocking
  int _getMinimumAmountForBlocking(String? areaCode) {
    if (areaCode == 'A') {
      return 3000000;
    } else if (areaCode == 'B') {
      return 2000000;
    }
    return 0;
  }

  // format rupiah sederhana
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.');
  }

  Widget _buildErrorMessage(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowReservationType(data.areaCode)) {
      return const SizedBox.shrink();
    }

    final bool canSelectBlocking = _canSelectBlocking(data.areaCode, finalTotal);
    final int minAmount = _getMinimumAmountForBlocking(data.areaCode);
    final String? errorMessage = hasAttemptedSubmit ? validationErrors['reservationType'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorMessage != null ? Colors.red.shade300 : Colors.purple.shade200,
          width: errorMessage != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_seat, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Tipe Reservasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Non-Blocking
          GestureDetector(
            onTap: () => onChanged(ReservationType.nonBlocking),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: selectedReservationType == ReservationType.nonBlocking
                    ? Colors.purple.shade100
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedReservationType == ReservationType.nonBlocking
                      ? Colors.purple.shade400
                      : Colors.grey.shade300,
                  width: selectedReservationType == ReservationType.nonBlocking ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedReservationType == ReservationType.nonBlocking
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Non-Blocking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          'Meja bisa digunakan customer lain setelah waktu reservasi berakhir',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blocking
          GestureDetector(
            onTap: canSelectBlocking ? () => onChanged(ReservationType.blocking) : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canSelectBlocking
                    ? (selectedReservationType == ReservationType.blocking
                    ? Colors.purple.shade100
                    : Colors.white)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canSelectBlocking
                      ? (selectedReservationType == ReservationType.blocking
                      ? Colors.purple.shade400
                      : Colors.grey.shade300)
                      : Colors.grey.shade300,
                  width: selectedReservationType == ReservationType.blocking ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedReservationType == ReservationType.blocking
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: canSelectBlocking ? Colors.purple.shade700 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blocking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: canSelectBlocking ? Colors.purple.shade700 : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          canSelectBlocking
                              ? 'Meja tidak bisa digunakan customer lain sampai Anda datang'
                              : 'Minimum pembelian Rp${_formatCurrency(minAmount)} untuk area ${data.areaCode}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!canSelectBlocking) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tambahkan Rp${_formatCurrency(minAmount - finalTotal)} lagi untuk mengaktifkan opsi Blocking',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],

          _buildErrorMessage(errorMessage),
        ],
      ),
    );
  }
}
