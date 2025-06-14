import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final int selectedRating;
  final Function(int) onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isSelected = index < selectedRating;
        return GestureDetector(
          onTap: () {
            onRatingChanged(index + 1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 42,
              color: isSelected
                  ? Colors.amber
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}