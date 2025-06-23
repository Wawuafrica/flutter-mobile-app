import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/screens/categories/categories_screen.dart';
import 'package:wawu_mobile/screens/categories/sub_categories_and_services_screen.dart/sub_categories_and_services.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        categoryProvider.fetchCategories();
      }

      Provider.of<AdProvider>(context, listen: false).fetchAds();

      // Fetch featured products for e-commerce section
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
    return Consumer3<CategoryProvider, UserProvider, ProductProvider>(
      builder: (
        context,
        categoryProvider,
        userProvider,
        productProvider,
        child,
      ) {
        // Asset paths to map to the first three categories (in order)
        final List<String> assetPaths = [
          'assets/images/section/programming.png',
          'assets/images/section/photography.png',
          'assets/images/section/sales.png',
        ];

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: [
                SizedBox(height: 20),
                CustomIntroText(text: 'Updates'),
                Consumer<AdProvider>(
                  builder: (context, adProvider, child) {
                    if (adProvider.isLoading) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: wawuColors.borderPrimary.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading ads',
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('No Ads available')),
                      );
                    }

                    final List<Widget> carouselItems =
                        adProvider.ads.map((ad) {
                          return GestureDetector(
                            onTap: () async {
                              final url = ad.link;
                              if (url.isNotEmpty) {
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open the ad link',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Image.network(
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
                            ),
                          );
                        }).toList();
                    return FadingCarousel(height: 220, children: carouselItems);
                  },
                ),
                SizedBox(height: 20),
                CustomIntroText(
                  text: 'Popular Services',
                  isRightText: true,
                  navFunction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoriesScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child:
                      categoryProvider.isLoading
                          ? Center(child: CircularProgressIndicator())
                          : categoryProvider.categories.isEmpty
                          ? Center(child: Text('No categories available'))
                          : ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                categoryProvider.categories
                                    .take(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final category = entry.value;
                                      return ImageTextCard(
                                        function: () {
                                          categoryProvider.selectCategory(
                                            category,
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      SubCategoriesAndServices(),
                                            ),
                                          );
                                        },
                                        text:
                                            category.name, // Use category name
                                        asset:
                                            assetPaths[index], // Map asset by index
                                      );
                                    })
                                    .toList(),
                          ),
                ),
                SizedBox(height: 30),
                CustomIntroText(
                  text: 'Wawu E-commerce',
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
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child:
                      productProvider.isLoading
                          ? Center(child: CircularProgressIndicator())
                          : productProvider.errorMessage != null
                          ? Center(
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
                          )
                          : productProvider.featuredProducts.isEmpty
                          ? Center(
                            child: Text(
                              'No products available',
                              style: TextStyle(fontSize: 14),
                            ),
                          )
                          : ListView(
                            scrollDirection: Axis.horizontal,
                            children:
                                productProvider.featuredProducts
                                    .take(5) // Show only first 5 products
                                    .map((product) => ECard(product: product))
                                    .toList(),
                          ),
                ),
                SizedBox(height: 40),
                CustomIntroText(text: 'Recently Viewed'),
                SizedBox(height: 20),
                Consumer<GigProvider>(
                  builder: (context, gigProvider, child) {
                    debugPrint(
                      '[HomeScreen] Recently Viewed section built. isLoading: \\${gigProvider.isRecentlyViewedLoading}, count: \\${gigProvider.recentlyViewedGigs.length}',
                    );
                    if (gigProvider.isRecentlyViewedLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (gigProvider.recentlyViewedGigs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No recently viewed gigs yet',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: gigProvider.recentlyViewedGigs.length,
                        itemBuilder: (context, index) {
                          final gig = gigProvider.recentlyViewedGigs[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GigCard(gig: gig),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
