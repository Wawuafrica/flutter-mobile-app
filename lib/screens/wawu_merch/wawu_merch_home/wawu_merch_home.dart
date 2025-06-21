import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
// import 'package:wawu_mobile/utils/error_utils.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';

class WawuMerchHome extends StatefulWidget {
  const WawuMerchHome({super.key});

  @override
  State<WawuMerchHome> createState() => _WawuMerchHomeState();
}

class _WawuMerchHomeState extends State<WawuMerchHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch ads for carousel
      Provider.of<AdProvider>(context, listen: false).fetchAds();

      // Fetch featured products for merch section
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      if (productProvider.featuredProducts.isEmpty &&
          !productProvider.isLoading) {
        productProvider.fetchFeaturedProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdProvider, ProductProvider>(
      builder: (context, adProvider, productProvider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                SizedBox(height: 20),
                CustomIntroText(text: 'Updates'),
                SizedBox(height: 20),
                // Ads Carousel Section
                Consumer<AdProvider>(
                  builder: (context, adProvider, child) {
                    if (adProvider.isLoading) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: wawuColors.borderPrimary.withAlpha(50),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (adProvider.errorMessage != null) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: wawuColors.borderPrimary.withAlpha(50),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading ads: ${adProvider.errorMessage}',
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                adProvider.fetchAds(); // Retry fetching ads
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (adProvider.ads.isEmpty) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: wawuColors.borderPrimary.withAlpha(50),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Center(child: Text('No Ads available')),
                      );
                    }

                    final List<Widget> carouselItems =
                        adProvider.ads.map((ad) {
                          return Image.network(
                            ad.media.link,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: wawuColors.borderPrimary.withAlpha(50),
                                child: Center(
                                  child: Text('Failed to load image'),
                                ),
                              );
                            },
                          );
                        }).toList();
                    return FadingCarousel(height: 250, children: carouselItems);
                  },
                ),
                SizedBox(height: 20),
                CustomIntroText(
                  text: 'Wawu-Merch',
                  isRightText: true,
                  navFunction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WawuEcommerceScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                // Products Grid Section
                Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    if (productProvider.isLoading) {
                      return SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (productProvider.errorMessage != null) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading products',
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  productProvider.fetchFeaturedProducts();
                                },
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (productProvider.featuredProducts.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }

                    // Create a vertical list layout for products
                    final products =
                        productProvider.featuredProducts.take(10).toList();
                    return Column(
                      children:
                          products
                              .map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: ECard(
                                    product: product,
                                    isMargin: false,
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
