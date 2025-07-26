import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/single_gig_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GigCard extends StatelessWidget {
  final Gig gig;

  const GigCard({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          final gigProvider = Provider.of<GigProvider>(context, listen: false);

          if (gig.uuid.isEmpty) {
            debugPrint('[GigCard][ERROR] Gig has empty UUID, skipping navigation');
            return;
          }

          debugPrint('[GigCard] Tapped gig: uuid=${gig.uuid}, title=${gig.title}');

          gigProvider.selectGig(gig);
          gigProvider.addRecentlyViewedGig(gig);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SingleGigScreen()),
          );
        } catch (e, stackTrace) {
          debugPrint('[GigCard][ERROR] Exception in onTap: $e');
          debugPrint('[GigCard][ERROR] Stack trace: $stackTrace');

          try {
            final gigProvider = Provider.of<GigProvider>(context, listen: false);
            gigProvider.selectGig(gig);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SingleGigScreen()),
            );
          } catch (navError) {
            debugPrint('[GigCard][ERROR] Navigation also failed: $navError');
          }
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220, // Fixed shorter height
            child: Stack(
              children: [
                // Gig Image (Full card height)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: gig.assets.photos.isNotEmpty && gig.assets.photos[0].link.isNotEmpty
                        ? gig.assets.photos[0].link
                        : '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholderImage(),
                  ),
                ),
              
              // Gradient Overlay (Full height)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Top Section - Seller Info
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _buildSellerImage(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        gig.seller.fullName.isNotEmpty
                            ? gig.seller.fullName
                            : 'Unknown Seller',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            gig.averageRating > 0
                                ? gig.averageRating.toStringAsFixed(1)
                                : '4.7',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Section - Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gig Title
                      Text(
                        gig.title.isNotEmpty ? gig.title : 'Untitled Gig',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Price and Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Starting from',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getPriceText(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          
                          // Action Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: wawuColors.primary,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: wawuColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildSellerImage() {
    if (gig.seller.profileImage != null && gig.seller.profileImage!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: gig.seller.profileImage!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 1),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/other/avatar.webp',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset('assets/images/other/avatar.webp', fit: BoxFit.cover);
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriceText() {
    if (gig.pricings.isNotEmpty && gig.pricings[0].package.amount.isNotEmpty) {
      try {
        final amount = gig.pricings[0].package.amount;
        return '₦$amount';
      } catch (e) {
        debugPrint('[GigCard] Error parsing price: $e');
      }
    }
    return '₦300,000';
  }
}