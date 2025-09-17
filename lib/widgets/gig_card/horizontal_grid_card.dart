import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/single_gig_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wawu_mobile/utils/helpers/cache_manager.dart';

class HorizontalGigCard extends StatelessWidget {
  final Gig gig;

  const HorizontalGigCard({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    // Navigate to the single gig screen on tap
    void navigateToGig() {
      try {
        final gigProvider = Provider.of<GigProvider>(context, listen: false);
        gigProvider.selectGig(gig);
        gigProvider.addRecentlyViewedGig(gig);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SingleGigScreen()),
        );
      } catch (e) {
        debugPrint('[HorizontalGigCard][ERROR] Navigation failed: $e');
      }
    }

    return GestureDetector(
      onTap: navigateToGig,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          // Subtle background color as seen in the design
          color: const Color(0xFFF8F5FC),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Gig Image
            _buildGigImage(),

            const SizedBox(width: 12),

            // Right Side: Gig Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVerifiedBadge(),
                  const SizedBox(height: 6),
                  _buildGigTitle(),
                  const SizedBox(height: 4),
                  _buildSellerName(),
                  const SizedBox(height: 12),
                  _buildPriceAndRating(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the image widget on the left side of the card.
  Widget _buildGigImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        width: 100,
        height: 120, // A fixed height often works well in list items
        child: CachedNetworkImage(
          cacheManager: CustomCacheManager.instance,

          imageUrl:
              gig.assets.photos.isNotEmpty ? gig.assets.photos[0].link : '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[200]),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
              ),
        ),
      ),
    );
  }

  /// Builds the purple "Verified Seller" badge.
  Widget _buildVerifiedBadge() {
    // You can add a condition here, e.g., if (gig.seller.isVerified)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7A28A9), // Purple color from design
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'Verified Seller',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the gig title text.
  Widget _buildGigTitle() {
    return Text(
      gig.title.isNotEmpty ? gig.title : 'Untitled Gig',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black87,
      ),
    );
  }

  /// Builds the seller's name text.
  Widget _buildSellerName() {
    return Text(
      gig.seller.fullName.isNotEmpty ? gig.seller.fullName : 'Unknown Seller',
      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
    );
  }

  /// Builds the bottom row containing price and rating.
  Widget _buildPriceAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Price Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starting from',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              // In Nigeria, you should display the price in Naira (₦)
              // The design shows $, so I'll keep it for visual consistency.
              // Use _getPriceText() if you prefer your original logic.
              '₦${gig.pricings.isNotEmpty ? gig.pricings[0].package.amount : '100'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Roboto',
                fontFamilyFallback: ['sans-serif'],
              ),
            ),
          ],
        ),

        // Rating Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                gig.averageRating > 0
                    ? gig.averageRating.toStringAsFixed(1)
                    : '4.4',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
