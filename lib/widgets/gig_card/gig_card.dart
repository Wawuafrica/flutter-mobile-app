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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
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
        // Remove fixed width to make it responsive
        margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
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
          child: AspectRatio(
            // Use aspect ratio instead of fixed height for better responsiveness
            aspectRatio: isSmallScreen ? 0.85 : 0.9, // Slightly taller on small screens
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
                    errorWidget: (context, url, error) => _buildPlaceholderImage(isSmallScreen),
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
                          Colors.black.withOpacity(0.7),
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
                  top: isSmallScreen ? 8 : 12,
                  left: isSmallScreen ? 8 : 12,
                  right: isSmallScreen ? 8 : 12,
                  child: Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 28 : 32,
                        height: isSmallScreen ? 28 : 32,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _buildSellerImage(),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          gig.seller.fullName.isNotEmpty
                              ? gig.seller.fullName
                              : 'Unknown Seller',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: const [
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
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4 : 6,
                          vertical: isSmallScreen ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              gig.averageRating > 0
                                  ? gig.averageRating.toStringAsFixed(1)
                                  : '4.7',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 9,
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
                    padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gig Title
                        Text(
                          gig.title.isNotEmpty ? gig.title : 'Untitled Gig',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: isSmallScreen ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        // Price and Action Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Price Section
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Starting from',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 8 : 9,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getPriceText(),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Action Button
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: wawuColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: wawuColors.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isSmallScreen ? 'View' : 'View Details',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
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
      ),
    );
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

  Widget _buildPlaceholderImage(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: wawuColors.primary.withValues(alpha: 0.2)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            color: Colors.grey[600],
            size: isSmallScreen ? 32 : 40,
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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