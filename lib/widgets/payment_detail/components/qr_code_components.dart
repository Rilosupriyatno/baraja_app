import 'package:flutter/material.dart';

class QRCodeError extends StatelessWidget {
  const QRCodeError({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Color(0xFFFF4757),
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'QR Code tidak tersedia',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF4757),
            ),
          ),
        ],
      ),
    );
  }
}

class QRCodeLoading extends StatelessWidget {
  const QRCodeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
        ),
      ),
    );
  }
}