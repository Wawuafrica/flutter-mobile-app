import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/categories/filtered_gigs/filtered_gigs.dart';
import 'package:wawu_mobile/screens/categories/categories_screen.dart';
import 'package:wawu_mobile/screens/wawu_ecommerce_screen/wawu_ecommerce_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
// import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, UserProvider>(
      builder: (context, categoryProvider, userProvider, child) {
        // Asset paths to map to the first three categories (in order)
        final List<String> assetPaths = [
          'assets/images/section/photography.png',
          'assets/images/section/programming.png',
          'assets/images/section/video.png',
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
                        child: Center(
                          child: Text('No Ads available'),
                        ),
                      );
                    }

                    final List<Widget> carouselItems = adProvider.ads.map((ad) {
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
                  text: 'Popular Services',
                  isRightText: true,
                  navFunction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoriesScreen()),
                    );
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: categoryProvider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : categoryProvider.categories.isEmpty
                          ? Center(child: Text('No categories available'))
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              children: categoryProvider.categories
                                  .take(3)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final category = entry.value;
                                    return ImageTextCard(
                                      function: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FilteredGigs(),
                                          ),
                                        );
                                      },
                                      text: category.name, // Use category name
                                      asset: assetPaths[index], // Map asset by index
                                    );
                                  }).toList(),
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
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [ECard(), ECard(), ECard()],
                  ),
                ),
                SizedBox(height: 40),
                CustomIntroText(text: 'Recently Viewed'),
                SizedBox(height: 20),
                // GigCard(),
            Text('GigCards'),

                SizedBox(height: 10),
                // GigCard(),
            Text('GigCards'),

                SizedBox(height: 10),
                // GigCard(),
            Text('GigCards'),

                SizedBox(height: 10),
                // GigCard(),
            Text('GigCards'),

                SizedBox(height: 10),
                // GigCard(),
            Text('GigCards'),

                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}