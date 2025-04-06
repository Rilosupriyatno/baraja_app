import 'package:baraja_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PointButtons extends StatelessWidget {
  final String? points;
  final int vouchers;

  const PointButtons({
    super.key,
    this.points,
    this.vouchers = 3,
  });

  @override
  Widget build(BuildContext context) {
    // Use the provided points or default to 0
    final userPoints = points != null ? points! : '0';
    final userVouchers = vouchers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.stars,
              label: 'Point',
              value: '$userPoints Poin',
              route: '/point',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.card_giftcard,
              label: 'Voucher',
              value: '$userVouchers Voucher',
              route: '/voucher',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    String? value,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          ElevatedButton(
            onPressed: () {
              context.go(route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Decorative circle
          Positioned(
            top: -14,
            right: -14,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}