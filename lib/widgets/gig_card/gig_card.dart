import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/single_gig_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class GigCard extends StatelessWidget {
  final Gig gig;

  const GigCard({super.key, required this.gig});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          final gigProvider = Provider.of<GigProvider>(context, listen: false);

          // Validate gig before processing
          if (gig.uuid.isEmpty) {
            debugPrint(
              '[GigCard][ERROR] Gig has empty UUID, skipping navigation',
            );
            return;
          }

          debugPrint(
            '[GigCard] Tapped gig: uuid=${gig.uuid}, title=${gig.title}',
          );

          // Select the gig
          gigProvider.selectGig(gig);

          // Add to recently viewed
          debugPrint(
            '[GigCard] About to addRecentlyViewedGig for gig: uuid=${gig.uuid}',
          );
          gigProvider.addRecentlyViewedGig(gig);
          debugPrint('[GigCard] addRecentlyViewedGig completed successfully');

          // Navigate to single gig screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SingleGigScreen()),
          );
        } catch (e, stackTrace) {
          debugPrint('[GigCard][ERROR] Exception in onTap: $e');
          debugPrint('[GigCard][ERROR] Stack trace: $stackTrace');

          // Still try to navigate even if recently viewed fails
          try {
            final gigProvider = Provider.of<GigProvider>(
              context,
              listen: false,
            );
            gigProvider.selectGig(gig);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SingleGigScreen()),
            );
          } catch (navError) {
            debugPrint('[GigCard][ERROR] Navigation also failed: $navError');
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color.fromARGB(255, 216, 216, 216),
            width: 0.5,
          ),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 110,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildGigImage(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gig.title.isNotEmpty ? gig.title : 'Untitled Gig',
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 35,
                          height: 35,
                          clipBehavior: Clip.hardEdge,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: _buildSellerImage(),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gig.seller.fullName.isNotEmpty
                                    ? gig.seller.fullName
                                    : 'Unknown Seller',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getPriceText(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 15,
                              color: wawuColors.primary.withAlpha(50),
                            ),
                            Text(
                              gig.averageRating > 0
                                  ? gig.averageRating.toStringAsFixed(1)
                                  : '0.0',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGigImage() {
    if (gig.assets.photos.isNotEmpty && gig.assets.photos[0].link.isNotEmpty) {
      return Image.network(
        gig.assets.photos[0].link,
        width: 100,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[GigCard] Error loading gig image: $error');
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 110,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildSellerImage() {
    if (gig.seller.profileImage != null &&
        gig.seller.profileImage!.isNotEmpty) {
      return Image.network(
        gig.seller.profileImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/other/avatar.webp',
            fit: BoxFit.cover,
          );
        },
      );
    }
    return Image.asset('assets/images/other/avatar.webp', fit: BoxFit.cover);
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 110,
      width: 100,
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
    );
  }

  String _getPriceText() {
    if (gig.pricings.isNotEmpty && gig.pricings[0].package.amount.isNotEmpty) {
      try {
        final amount = gig.pricings[0].package.amount;
        return 'From ₦$amount';
      } catch (e) {
        debugPrint('[GigCard] Error parsing price: $e');
      }
    }
    return 'Price unavailable';
  }
}
