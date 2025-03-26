import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String phoneNumber;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Picture
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipOval(
            child: Container(
              color: Colors.white,
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.black87,
              ),
              // You can replace the Icon with an Image widget to use a custom image:
              // Image.asset('assets/images/profile.png', fit: BoxFit.cover),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Phone Number
        Text(
          phoneNumber,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}