import 'package:flutter/material.dart';

class CoffeeAnimationWidget extends StatelessWidget {
  const CoffeeAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.white, // Background putih saja
      ),
      child: Stack(
        children: [
          // Decorative circles - bulat sempurna
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -1,
            // left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/animations/waiting2.gif',
                width: 400,
                height: 500,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.brown.shade100,
                          Colors.brown.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.coffee,
                            size: 40,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Making Coffee...',
                          style: TextStyle(
                            color: Colors.brown.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}