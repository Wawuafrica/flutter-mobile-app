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
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart'; // Import FullErrorDisplay

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Flags to prevent showing multiple snackbars for the same error
  bool _hasShownAdError = false;
  bool _hasShownCategoryError = false;
  bool _hasShownProductError = false;
  bool _hasShownGigError = false;

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
    final gigProvider = Provider.of<GigProvider>(
      context,
      listen: false,
    ); // Uncommented

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
      // final gigProvider = Provider.of<GigProvider>(
      //   context,
      //   listen: false,
      // ); // Uncommented

      // Create a list of futures to run in parallel
      final futures = <Future>[
        categoryProvider.fetchCategories(),
        adProvider
            .refresh(), // Use refresh() instead of fetchAds() to reset state
        productProvider.fetchFeaturedProducts(),
        // gigProvider.fetchRecentlyViewedGigs(), // Uncommented
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
        isError: false, // Informative, not an error
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

  // Function to show the support dialog (can be reused)
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

  @override
  Widget build(BuildContext context) {
    return Consumer5<
      CategoryProvider,
      UserProvider,
      ProductProvider,
      GigProvider,
      AdProvider
    >(
      builder: (
        context,
        categoryProvider,
        userProvider,
        productProvider,
        gigProvider,
        adProvider,
        child,
      ) {
        // Listen for errors from AdProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (adProvider.hasError &&
              adProvider.errorMessage != null &&
              !_hasShownAdError) {
            CustomSnackBar.show(
              context,
              message: adProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                adProvider.fetchAds();
              },
            );
            _hasShownAdError = true;
            adProvider.clearError(); // Clear error state
          } else if (!adProvider.hasError && _hasShownAdError) {
            _hasShownAdError = false;
          }
        });

        // Listen for errors from CategoryProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (categoryProvider.hasError &&
              categoryProvider.errorMessage != null &&
              !_hasShownCategoryError) {
            CustomSnackBar.show(
              context,
              message: categoryProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                categoryProvider.fetchCategories();
              },
            );
            _hasShownCategoryError = true;
            categoryProvider.clearError(); // Clear error state
          } else if (!categoryProvider.hasError && _hasShownCategoryError) {
            _hasShownCategoryError = false;
          }
        });

        // Listen for errors from ProductProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (productProvider.hasError &&
              productProvider.errorMessage != null &&
              !_hasShownProductError) {
            CustomSnackBar.show(
              context,
              message: productProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                productProvider.fetchFeaturedProducts();
              },
            );
            _hasShownProductError = true;
            productProvider.clearError(); // Clear error state
          } else if (!productProvider.hasError && _hasShownProductError) {
            _hasShownProductError = false;
          }
        });

        // Listen for errors from GigProvider and display SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (gigProvider.hasError &&
              gigProvider.errorMessage != null &&
              !_hasShownGigError) {
            CustomSnackBar.show(
              context,
              message: gigProvider.errorMessage!,
              isError: true,
              actionLabel: 'RETRY',
              onActionPressed: () {
                gigProvider.fetchRecentlyViewedGigs();
              },
            );
            _hasShownGigError = true;
            gigProvider.clearError(); // Clear error state
          } else if (!gigProvider.hasError && _hasShownGigError) {
            _hasShownGigError = false;
          }
        });

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
                      const SizedBox(height: 10),
                      // Real-time Ads Section
                      Consumer<AdProvider>(
                        builder: (context, adProvider, child) {
                          // Loading state
                          if (adProvider.isLoading && adProvider.ads.isEmpty) {
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

                          // Error state with FullErrorDisplay
                          if (adProvider.hasError &&
                              adProvider.ads.isEmpty &&
                              !adProvider.isLoading) {
                            return FullErrorDisplay(
                              errorMessage:
                                  adProvider.errorMessage ??
                                  'Failed to load ads. Please try again.',
                              onRetry: () {
                                adProvider.fetchAds();
                              },
                              onContactSupport: () {
                                _showErrorSupportDialog(
                                  context,
                                  'If this problem persists, please contact our support team. We are here to help!',
                                );
                              },
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
                            categoryProvider.isLoading &&
                                    categoryProvider.categories.isEmpty
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : categoryProvider.hasError &&
                                    categoryProvider.categories.isEmpty &&
                                    !categoryProvider.isLoading
                                ? FullErrorDisplay(
                                  errorMessage:
                                      categoryProvider.errorMessage ??
                                      'Failed to load categories. Please try again.',
                                  onRetry: () {
                                    categoryProvider.fetchCategories();
                                  },
                                  onContactSupport: () {
                                    _showErrorSupportDialog(
                                      context,
                                      'If this problem persists, please contact our support team. We are here to help!',
                                    );
                                  },
                                )
                                : categoryProvider.categories.isEmpty
                                ? const Center(
                                  child: Text('No categories available'),
                                )
                                : ListView.separated(
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox(width: 10),
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      categoryProvider.categories
                                          .take(3)
                                          .length,
                                  itemBuilder: (context, index) {
                                    final category =
                                        categoryProvider.categories[index];
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
                                  },
                                  // children:
                                  //     categoryProvider.categories
                                  //         .take(3)
                                  //         .toList()
                                  //         .asMap()
                                  //         .entries
                                  //         .map((entry) {
                                  //           final index = entry.key;
                                  //           final category = entry.value;
                                  //           return ImageTextCard(
                                  //             function: () {
                                  //               categoryProvider.selectCategory(
                                  //                 category,
                                  //               );
                                  //               Navigator.push(
                                  //                 context,
                                  //                 MaterialPageRoute(
                                  //                   builder:
                                  //                       (context) =>
                                  //                           const SubCategoriesAndServices(),
                                  //                 ),
                                  //               );
                                  //             },
                                  //             text: category.name,
                                  //             asset: assetPaths[index],
                                  //           );
                                  //         })
                                  //         .toList(),
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
                            productProvider.isLoading &&
                                    productProvider.featuredProducts.isEmpty
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : productProvider.hasError &&
                                    productProvider.featuredProducts.isEmpty &&
                                    !productProvider.isLoading
                                ? FullErrorDisplay(
                                  errorMessage:
                                      productProvider.errorMessage ??
                                      'Failed to load products. Please try again.',
                                  onRetry: () {
                                    productProvider.fetchFeaturedProducts();
                                  },
                                  onContactSupport: () {
                                    _showErrorSupportDialog(
                                      context,
                                      'If this problem persists, please contact our support team. We are here to help!',
                                    );
                                  },
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
                          if (gigProvider.isRecentlyViewedLoading &&
                              gigProvider.recentlyViewedGigs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (gigProvider.hasError &&
                              gigProvider.recentlyViewedGigs.isEmpty &&
                              !gigProvider.isRecentlyViewedLoading) {
                            return FullErrorDisplay(
                              errorMessage:
                                  gigProvider.errorMessage ??
                                  'Failed to load recently viewed gigs. Please try again.',
                              onRetry: () {
                                gigProvider.fetchRecentlyViewedGigs();
                              },
                              onContactSupport: () {
                                _showErrorSupportDialog(
                                  context,
                                  'If this problem persists, please contact our support team. We are here to help!',
                                );
                              },
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
                          return Column(
                            children:
                                gigProvider.recentlyViewedGigs.map((gig) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GigCard(gig: gig),
                                  );
                                }).toList(),
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
