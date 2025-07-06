import 'package:flutter/material.dart';

class TrackingStatesWidget {
  static Widget buildLoadingState({
    required Color statusColor,
  }) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.05),
                  ),
                ),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                Icon(Icons.coffee_rounded, color: statusColor, size: 20),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Memuat data pesanan...',
              style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState({
    required String? errorMessage,
    required Color statusColor,
    required VoidCallback onRetry,
  }) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, size: 36, color: Colors.red[400]),
              ),
              const SizedBox(height: 32),
              Text(
                'Gagal Memuat Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Coba Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildRatingLoadingIndicator({
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Mengecek rating...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}