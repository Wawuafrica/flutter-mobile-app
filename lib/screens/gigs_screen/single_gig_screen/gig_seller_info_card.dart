import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart';

class GigSellerInfoCard extends StatelessWidget {
  final Gig gig;
  final VoidCallback onMessageTap;

  const GigSellerInfoCard(
      {super.key, required this.gig, required this.onMessageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.8), // Light purple background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          SizedBox(
            height: 50,
            width: 50,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: gig.seller.profileImage ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.purple.shade100),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/other/avatar.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Seller Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gig.seller.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Verified Seller',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Message Button
          GestureDetector(
            onTap: onMessageTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple,
              ),
              child: const Icon(Icons.message_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
