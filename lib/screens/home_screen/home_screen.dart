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
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for CachedNetworkImage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  /// Initialize all data providers
  void _initializeData() {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    // final gigProvider = Provider.of<GigProvider>(context, listen: false); // Uncommmented as per request

    // Initialize categories
    if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
      categoryProvider.fetchCategories();
    }

    // Initialize ads - this will also set up real-time listeners
    if (adProvider.ads.isEmpty && !adProvider.isLoading) {
      adProvider.fetchAds();
    }

    // Initialize featured products
    if (productProvider.featuredProducts.isEmpty &&
        !productProvider.isLoading) {
      productProvider.fetchFeaturedProducts();
    }

    // Fetch recently viewed gigs
    // if (gigProvider.recentlyViewedGigs.isEmpty && !gigProvider.isRecentlyViewedLoading) {
    //   gigProvider.fetchRecentlyViewedGigs();
    // }
  }

  Future<void> _refreshData() async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      // final gigProvider = Provider.of<GigProvider>(context, listen: false); // Uncommmented as per request

      // Create a list of futures to run in parallel
      final futures = <Future>[
        categoryProvider.fetchCategories(),
        adProvider
            .refresh(), // Use refresh() instead of fetchAds() to reset state
        productProvider.fetchFeaturedProducts(),
        // gigProvider.fetchRecentlyViewedGigs(), // Uncommmented as per request
      ];

      // Wait for all futures to complete
      await Future.wait(futures);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle ad tap with improved error handling
  Future<void> _handleAdTap(String adLink) async {
    if (adLink.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This ad has no link')));
      return;
    }

    try {
      final uri = Uri.parse(adLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the ad link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: ${e.toString()}')),
        );
      }
    }
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
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshData,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            displacement: 40.0,
            strokeWidth: 2.0,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      const CustomIntroText(text: 'Updates'),

                      // Real-time Ads Section
                      Consumer<AdProvider>(
                        builder: (context, adProvider, child) {
                          // Loading state
                          if (adProvider.isLoading) {
                            return Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                color: wawuColors.borderPrimary.withAlpha(50),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Error state
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
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error loading ads',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    adProvider.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      adProvider.fetchAds();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Empty state
                          if (adProvider.ads.isEmpty) {
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
                                    Icon(
                                      Icons.announcement_outlined,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No ads available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Success state - Show ads carousel
                          final List<Widget> carouselItems =
                              adProvider.ads.map((ad) {
                                return GestureDetector(
                                  onTap: () => _handleAdTap(ad.link),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      // Replaced Image.network with CachedNetworkImage
                                      imageUrl: ad.media.link,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color: wawuColors.borderPrimary
                                                .withAlpha(50),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: wawuColors.borderPrimary
                                                .withAlpha(50),
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 48,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Failed to load image',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              }).toList();

                          return FadingCarousel(
                            height: 220,
                            children: carouselItems,
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      CustomIntroText(
                        text: 'Popular Services',
                        isRightText: true,
                        navFunction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoriesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 160,
                        child:
                            categoryProvider.isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : categoryProvider.categories.isEmpty
                                ? const Center(
                                  child: Text('No categories available'),
                                )
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
                                                            const SubCategoriesAndServices(),
                                                  ),
                                                );
                                              },
                                              text: category.name,
                                              asset: assetPaths[index],
                                            );
                                          })
                                          .toList(),
                                ),
                      ),
                      const SizedBox(height: 30),
                      CustomIntroText(
                        text: 'WAWUAfrica E-commerce',
                        isRightText: true,
                        navFunction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WawuEcommerceScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 180,
                        child:
                            productProvider.isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : productProvider.errorMessage != null
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Error loading products',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          productProvider
                                              .fetchFeaturedProducts();
                                        },
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                                : productProvider.featuredProducts.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No products available',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )
                                : ListView(
                                  scrollDirection: Axis.horizontal,
                                  children:
                                      productProvider.featuredProducts
                                          .take(5)
                                          .map(
                                            (product) =>
                                                ECard(product: product),
                                          )
                                          .toList(),
                                ),
                      ),
                      const SizedBox(height: 40),
                      const CustomIntroText(text: 'Recently Viewed'),
                      const SizedBox(height: 20),
                      Consumer<GigProvider>(
                        builder: (context, gigProvider, child) {
                          debugPrint(
                            '[HomeScreen] Recently Viewed section built. isLoading: ${gigProvider.isRecentlyViewedLoading}, count: ${gigProvider.recentlyViewedGigs.length}',
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: gigProvider.recentlyViewedGigs.length,
                              itemBuilder: (context, index) {
                                final gig =
                                    gigProvider.recentlyViewedGigs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GigCard(gig: gig),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
