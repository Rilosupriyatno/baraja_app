import 'package:flutter/material.dart';

/// ✅ PROFESSIONAL GRO MODE BADGE WIDGET
/// Widget badge yang konsisten untuk menampilkan mode GRO di seluruh aplikasi
class GroModeBadge extends StatelessWidget {
  final BadgeSize size;
  final BadgeStyle style;
  final bool showIcon;

  const GroModeBadge({
    super.key,
    this.size = BadgeSize.medium,
    this.style = BadgeStyle.filled,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: style == BadgeStyle.outlined
            ? Border.all(color: const Color(0xFF2E8B57), width: 1.5)
            : null,
        boxShadow: style == BadgeStyle.elevated
            ? [
          BoxShadow(
            color: const Color(0xFF2E8B57).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.admin_panel_settings_rounded,
              color: _getTextColor(),
              size: _getIconSize(),
            ),
            SizedBox(width: _getSpacing()),
          ],
          Text(
            'GRO MODE',
            style: TextStyle(
              color: _getTextColor(),
              fontSize: _getFontSize(),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 20;
    }
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 11;
      case BadgeSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 14;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 18;
    }
  }

  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  Color _getBackgroundColor() {
    switch (style) {
      case BadgeStyle.filled:
        return const Color(0xFF2E8B57);
      case BadgeStyle.outlined:
        return Colors.transparent;
      case BadgeStyle.soft:
        return const Color(0xFF2E8B57).withOpacity(0.15);
      case BadgeStyle.elevated:
        return const Color(0xFF2E8B57);
    }
  }

  Color _getTextColor() {
    switch (style) {
      case BadgeStyle.filled:
      case BadgeStyle.elevated:
        return Colors.white;
      case BadgeStyle.outlined:
      case BadgeStyle.soft:
        return const Color(0xFF2E8B57);
    }
  }
}

enum BadgeSize { small, medium, large }
enum BadgeStyle { filled, outlined, soft, elevated }

/// ✅ WIDGET UNTUK APPBAR
class GroModeAppBarBadge extends StatelessWidget {
  const GroModeAppBarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroModeBadge(
      size: BadgeSize.small,
      style: BadgeStyle.filled,
      showIcon: true,
    );
  }
}


/// ✅ WIDGET UNTUK FLOATING INDICATOR
class GroModeFloatingIndicator extends StatelessWidget {
  const GroModeFloatingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2E8B57),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              'GRO MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
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