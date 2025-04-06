import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? email;
  final String? profilePicture;
  final String? consumerType;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.profilePicture,
    this.consumerType,
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
              child: profilePicture != null && profilePicture!.isNotEmpty
                  ? Image.network(
                profilePicture!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.black87,
                ),
              )
                  : const Icon(
                Icons.person,
                size: 60,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Name with Consumer Type Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (consumerType != null && consumerType!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getConsumerTypeColor(consumerType!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  consumerType!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
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

        // Email (if available)
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }

  Color _getConsumerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return const Color(0xFFCD7F32);
    }
  }
}