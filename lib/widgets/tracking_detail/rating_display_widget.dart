import 'package:flutter/material.dart';

class RatingDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> existingRating;

  const RatingDisplayWidget({
    super.key,
    required this.existingRating,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = (existingRating['rating'] ?? 0).toDouble();
    final comment = existingRating['comment'] ?? '';
    final ratingDate = existingRating['createdAt'] ?? existingRating['date'];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Rating Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) => Icon(
              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber,
              size: 28,
            )),
          ),
          const SizedBox(height: 8),
          Text(
            '${rating.toStringAsFixed(1)} dari 5',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          if (ratingDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Diberikan pada: ${_formatDate(ratingDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Komentar:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terima kasih atas rating dan feedback Anda!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}