import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'star_rating_widget.dart';

class RatingSection extends StatelessWidget {
  final int selectedRating;
  final TextEditingController reviewController;
  final Map<String, dynamic>? existingRating;
  final Function(int) onRatingChanged;

  const RatingSection({
    super.key,
    required this.selectedRating,
    required this.reviewController,
    required this.existingRating,
    required this.onRatingChanged,
  });

  String _getRatingText() {
    switch (selectedRating) {
      case 1:
        return 'Sangat Kurang';
      case 2:
        return 'Kurang';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return 'Pilih Rating';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rating Title
          _buildRatingTitle(),
          const SizedBox(height: 32),

          // Star Rating
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: StarRatingWidget(
              selectedRating: selectedRating,
              onRatingChanged: onRatingChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Rating Text
          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: selectedRating > 0
                  ? AppTheme.barajaPrimary.primaryColor
                  : Colors.grey.shade500,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 32),

          // Review Text Field
          _buildReviewTextField(),
        ],
      ),
    );
  }

  Widget _buildRatingTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.15),
                Colors.amber.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            existingRating != null
                ? 'Perbarui rating Anda'
                : 'Bagaimana pengalaman Anda?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTextField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: reviewController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: '✍️ Ceritakan pengalaman Anda... (opsional)',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}