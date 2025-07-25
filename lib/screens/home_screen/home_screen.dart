import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

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
    final gigProvider = Provider.of<GigProvider>(context, listen: false);

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
    if (gigProvider.recentlyViewedGigs.isEmpty &&
        !gigProvider.isRecentlyViewedLoading) {
      gigProvider.fetchRecentlyViewedGigs();
    }
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

      // Create a list of futures to run in parallel
      final futures = <Future>[
        categoryProvider.fetchCategories(),
        adProvider.refresh(),
        productProvider.fetchFeaturedProducts(),
      ];

      // Wait for all futures to complete
      await Future.wait(futures);

      // Show success message
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Data refreshed successfully',
          isError: false,
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to refresh data: $error',
          isError: true,
        );
      }
    }
  }

  /// Handle ad tap with improved error handling
  Future<void> _handleAdTap(String adLink) async {
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
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open the ad link',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Error opening link: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // Function to show the support dialog
  void _showErrorSupportDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wawuColors.primary,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: wawuColors.buttonSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Check if any provider has a critical error (empty data + error + not loading)
  bool _hasCriticalError(
    CategoryProvider categoryProvider,
    AdProvider adProvider,
    ProductProvider productProvider,
    GigProvider gigProvider,
  ) {
    return (categoryProvider.hasError &&
            categoryProvider.categories.isEmpty &&
            !categoryProvider.isLoading) ||
        // (adProvider.hasError &&
        //     adProvider.ads.isEmpty &&
        //     !adProvider.isLoading) ||
        (productProvider.hasError &&
            productProvider.featuredProducts.isEmpty &&
            !productProvider.isLoading) ||
        (gigProvider.hasError &&
            gigProvider.recentlyViewedGigs.isEmpty &&
            !gigProvider.isRecentlyViewedLoading);
  }

  /// Get the primary error message and retry function
  Map<String, dynamic> _getPrimaryError(
    CategoryProvider categoryProvider,
    AdProvider adProvider,
    ProductProvider productProvider,
    GigProvider gigProvider,
  ) {
    // Priority: Categories > Ads > Products > Gigs
    if (categoryProvider.hasError &&
        categoryProvider.categories.isEmpty &&
        !categoryProvider.isLoading) {
      return {
        'message': categoryProvider.errorMessage ?? 'Failed to load categories',
        'retry': () => categoryProvider.fetchCategories(),
      };
    }

    if (adProvider.hasError &&
        adProvider.ads.isEmpty &&
        !adProvider.isLoading) {
      return {
        'message': adProvider.errorMessage ?? 'Failed to load updates',
        'retry': () => adProvider.fetchAds(),
      };
    }

    if (productProvider.hasError &&
        productProvider.featuredProducts.isEmpty &&
        !productProvider.isLoading) {
      return {
        'message': productProvider.errorMessage ?? 'Failed to load products',
        'retry': () => productProvider.fetchFeaturedProducts(),
      };
    }

    if (gigProvider.hasError &&
        gigProvider.recentlyViewedGigs.isEmpty &&
        !gigProvider.isRecentlyViewedLoading) {
      return {
        'message':
            gigProvider.errorMessage ?? 'Failed to load recently viewed gigs',
        'retry': () => gigProvider.fetchRecentlyViewedGigs(),
      };
    }

    return {
      'message': 'Something went wrong',
      'retry': () => _initializeData(),
    };
  }

  /// Check if any provider is loading (for overall loading state)
  bool _isAnyProviderLoading(
    CategoryProvider categoryProvider,
    AdProvider adProvider,
    ProductProvider productProvider,
    GigProvider gigProvider,
  ) {
    return (categoryProvider.isLoading &&
            categoryProvider.categories.isEmpty) ||
        (adProvider.isLoading && adProvider.ads.isEmpty) ||
        (productProvider.isLoading &&
            productProvider.featuredProducts.isEmpty) ||
        (gigProvider.isRecentlyViewedLoading &&
            gigProvider.recentlyViewedGigs.isEmpty);
  }

  /// Build ads section with inline error handling
  Widget _buildAdsSection(AdProvider adProvider) {
    // Show loading placeholder if loading and no data
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

    // Show empty state if no ads and no error
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

    // Show ads carousel if data is available
    if (adProvider.ads.isNotEmpty) {
      final List<Widget> carouselItems =
          adProvider.ads.map((ad) {
            return GestureDetector(
              onTap: () => _handleAdTap(ad.link),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: ad.media.link,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: wawuColors.borderPrimary.withAlpha(50),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
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

    // Fallback empty container
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

  /// Build categories section with inline error handling
  Widget _buildCategoriesSection(CategoryProvider categoryProvider) {
    // Asset paths to map to the first three categories (in order)
    final List<String> assetPaths = [
      'assets/images/section/programming.png',
      'assets/images/section/photography.png',
      'assets/images/section/sales.png',
    ];

    if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categoryProvider.categories.isEmpty) {
      return const Center(child: Text('No categories available'));
    }

    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      scrollDirection: Axis.horizontal,
      itemCount: categoryProvider.categories.take(3).length,
      itemBuilder: (context, index) {
        final category = categoryProvider.categories[index];
        return ImageTextCard(
          function: () {
            categoryProvider.selectCategory(category);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubCategoriesAndServices(),
              ),
            );
          },
          text: category.name,
          asset: assetPaths[index],
        );
      },
    );
  }

  /// Build products section with inline error handling
  Widget _buildProductsSection(ProductProvider productProvider) {
    if (productProvider.isLoading && productProvider.featuredProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProvider.featuredProducts.isEmpty) {
      return const Center(
        child: Text('No products available', style: TextStyle(fontSize: 14)),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children:
          productProvider.featuredProducts
              .take(5)
              .map((product) => ECard(product: product))
              .toList(),
    );
  }

  /// Build gigs section with inline error handling
  Widget _buildGigsSection(GigProvider gigProvider) {
    if (gigProvider.isRecentlyViewedLoading &&
        gigProvider.recentlyViewedGigs.isEmpty) {
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

    return Column(
      children:
          gigProvider.recentlyViewedGigs.map((gig) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GigCard(gig: gig),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      CategoryProvider,
      // UserProvider,
      ProductProvider,
      GigProvider,
      AdProvider
    >(
      builder: (
        context,
        categoryProvider,
        // userProvider,
        productProvider,
        gigProvider,
        adProvider,
        child,
      ) {
        // Check for critical errors that should show full screen error
        bool hasCriticalError = _hasCriticalError(
          categoryProvider,
          adProvider,
          productProvider,
          gigProvider,
        );

        bool isLoading = _isAnyProviderLoading(
          categoryProvider,
          adProvider,
          productProvider,
          gigProvider,
        );

        // Show full screen error if there's a critical error
        if (hasCriticalError) {
          final errorInfo = _getPrimaryError(
            categoryProvider,
            adProvider,
            productProvider,
            gigProvider,
          );

          return Scaffold(
            body: FullErrorDisplay(
              errorMessage: errorInfo['message'],
              onRetry: errorInfo['retry'],
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'If this problem persists, please contact our support team. We are here to help!',
                );
              },
            ),
          );
        }

        // Show loading screen if critical data is still loading
        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show normal content with inline error handling for individual sections
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
                      const SizedBox(height: 10),
                      // Ads Section
                      _buildAdsSection(adProvider),
                      const SizedBox(height: 20),
                      // Categories Section
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
                        child: _buildCategoriesSection(categoryProvider),
                      ),
                      const SizedBox(height: 30),
                      // Products Section
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
                        child: _buildProductsSection(productProvider),
                      ),
                      const SizedBox(height: 40),
                      // Gigs Section
                      const CustomIntroText(text: 'Recently Viewed'),
                      const SizedBox(height: 20),
                      _buildGigsSection(gigProvider),
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
