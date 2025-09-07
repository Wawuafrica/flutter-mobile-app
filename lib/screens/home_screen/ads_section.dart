import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class AdsSection extends StatelessWidget {
  const AdsSection({super.key});

  Future<void> _handleAdTap(BuildContext context, String adLink) async {
    if (adLink.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'This ad has no link',
        isError: false,
      );
      return;
    }

    try {
      final uri = Uri.parse(adLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open the ad link',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error opening link: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);

    if (adProvider.isLoading && adProvider.ads.isEmpty) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.borderPrimary.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (adProvider.ads.isEmpty && !adProvider.hasError) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: wawuColors.borderPrimary.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.announcement_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                'No ads available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (adProvider.ads.isNotEmpty) {
      final List<Widget> carouselItems = adProvider.ads.map((ad) {
        return GestureDetector(
          onTap: () => _handleAdTap(context, ad.link),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: ad.media.link,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: wawuColors.borderPrimary.withAlpha(50),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: wawuColors.borderPrimary.withAlpha(50),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList();

      return FadingCarousel(height: 220, children: carouselItems);
    }

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: wawuColors.borderPrimary.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'No updates available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
