// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/categories/categories_screen.dart';
import 'package:wawu_mobile/screens/categories/sub_categories_and_services_screen.dart/sub_categories_and_services.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/fading_carousel/fading_carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wawu_mobile/widgets/image_text_card/image_text_card.dart';
import 'package:wawu_mobile/widgets/gig_card/gig_card.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';
import 'package:wawu_mobile/screens/search/search_screen.dart'; // Import the new search screen

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
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
    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);


    // Initialize categories
    if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
      categoryProvider.fetchCategories();
    }

    // Initialize ads - this will also set up real-time listeners
    if (adProvider.ads.isEmpty && !adProvider.isLoading) {
      adProvider.fetchAds();
    }

    // Fetch recently viewed gigs only if user is logged in
    if (userProvider.currentUser != null) {
      if (gigProvider.recentlyViewedGigs.isEmpty &&
          !gigProvider.isRecentlyViewedLoading) {
        gigProvider.fetchRecentlyViewedGigs();
      }
    } else {
      // If no user, ensure recently viewed gigs are cleared locally
      gigProvider.clearRecentlyViewedGigs();
    }


    // Fetch suggested gigs
    if (gigProvider.suggestedGigs.isEmpty &&
        !gigProvider.isSuggestedGigsLoading) {
      gigProvider.fetchSuggestedGigs();
    }
  }

  Future<void> _refreshData() async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final gigProvider = Provider.of<GigProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);


      // Create a list of futures to run in parallel
      final futures = <Future>[
        categoryProvider.fetchCategories(),
        adProvider.refresh(),
        gigProvider.fetchSuggestedGigs(), // Refresh suggested gigs
      ];

      // Refresh recently viewed gigs only if user is logged in
      if (userProvider.currentUser != null) {
        futures.add(gigProvider.fetchRecentlyViewedGigs());
      } else {
        // Clear if not logged in
        gigProvider.clearRecentlyViewedGigs();
      }

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
    GigProvider gigProvider,
    UserProvider userProvider,
  ) {
    // Categories and Suggested Gigs are always critical if empty and errored
    if ((categoryProvider.hasError &&
            categoryProvider.categories.isEmpty &&
            !categoryProvider.isLoading) ||
        (gigProvider.hasError &&
            gigProvider.suggestedGigs.isEmpty &&
            !gigProvider.isSuggestedGigsLoading)) {
      return true;
    }
    // Recently Viewed Gigs are only critical if user is logged in AND they are empty and errored
    if (userProvider.currentUser != null &&
        gigProvider.hasError &&
        gigProvider.recentlyViewedGigs.isEmpty &&
        !gigProvider.isRecentlyViewedLoading) {
      return true;
    }
    return false;
  }

  /// Get the primary error message and retry function
  Map<String, dynamic> _getPrimaryError(
    CategoryProvider categoryProvider,
    AdProvider adProvider,
    GigProvider gigProvider,
    UserProvider userProvider,
  ) {
    // Priority: Categories > Suggested Gigs > Recently Viewed Gigs (if logged in)
    if (categoryProvider.hasError &&
        categoryProvider.categories.isEmpty &&
        !categoryProvider.isLoading) {
      return {
        'message': categoryProvider.errorMessage ?? 'Failed to load categories',
        'retry': () => categoryProvider.fetchCategories(),
      };
    }

    if (gigProvider.hasError &&
        gigProvider.suggestedGigs.isEmpty &&
        !gigProvider.isSuggestedGigsLoading) {
      return {
        'message': gigProvider.errorMessage ?? 'Failed to load suggested gigs',
        'retry': () => gigProvider.fetchSuggestedGigs(),
      };
    }

    if (userProvider.currentUser != null &&
        gigProvider.hasError &&
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
    GigProvider gigProvider,
    UserProvider userProvider,
  ) {
    bool loadingCategories =
        (categoryProvider.isLoading && categoryProvider.categories.isEmpty);
    bool loadingAds = (adProvider.isLoading && adProvider.ads.isEmpty);
    bool loadingSuggestedGigs =
        (gigProvider.isSuggestedGigsLoading && gigProvider.suggestedGigs.isEmpty);
    bool loadingRecentlyViewedGigs = (userProvider.currentUser != null &&
        gigProvider.isRecentlyViewedLoading &&
        gigProvider.recentlyViewedGigs.isEmpty);

    return loadingCategories ||
        loadingAds ||
        loadingSuggestedGigs ||
        loadingRecentlyViewedGigs;
  }

  /// Build ads section with inline error handling
  Widget _buildAdsSection(AdProvider adProvider) {
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

  /// Build horizontal gigs section with inline error handling for Recently Viewed
  Widget _buildRecentlyViewedGigsSection(GigProvider gigProvider, UserProvider userProvider) {
    // If no user is logged in, don't show the section at all
    if (userProvider.currentUser == null) {
      return const SizedBox.shrink(); // Use SizedBox.shrink to hide the widget
    }

    if (gigProvider.isRecentlyViewedLoading &&
        gigProvider.recentlyViewedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (gigProvider.recentlyViewedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No recently viewed gigs yet',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 250, // Fixed height for horizontal scroll
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        itemCount: gigProvider.recentlyViewedGigs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final gig = gigProvider.recentlyViewedGigs[index];
          return SizedBox(
            width: 280, // Fixed width for each card
            child: GigCard(gig: gig),
          );
        },
      ),
    );
  }

  /// Build horizontal gigs section with inline error handling for Suggested Gigs
  Widget _buildSuggestedGigsSection(GigProvider gigProvider) {
    if (gigProvider.isSuggestedGigsLoading &&
        gigProvider.suggestedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (gigProvider.suggestedGigs.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No suggested gigs available at the moment',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 250, // Fixed height for horizontal scroll
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        itemCount: gigProvider.suggestedGigs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final gig = gigProvider.suggestedGigs[index];
          return SizedBox(
            width: 280, // Fixed width for each card
            child: GigCard(gig: gig),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<CategoryProvider, UserProvider, GigProvider, AdProvider>(
      builder: (
        context,
        categoryProvider,
        userProvider,
        gigProvider,
        adProvider,
        child,
      ) {
        // Check for critical errors that should show full screen error
        bool hasCriticalError = _hasCriticalError(
          categoryProvider,
          adProvider,
          gigProvider,
          userProvider, // Pass userProvider
        );

        bool isLoading = _isAnyProviderLoading(
          categoryProvider,
          adProvider,
          gigProvider,
          userProvider, // Pass userProvider
        );

        // Show full screen error if there's a critical error
        if (hasCriticalError) {
          final errorInfo = _getPrimaryError(
            categoryProvider,
            adProvider,
            gigProvider,
            userProvider, // Pass userProvider
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
                // Search Bar Section - now scrolls with content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0), // Added top padding
                    child: Hero(
                      tag: 'searchBar', // Unique tag for the Hero animation
                      child: Material( // Material is needed for Hero to work correctly with Textfield
                        color: Colors.transparent, // Keep background transparent
                        child: TextField(
                          readOnly: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 300),
                                pageBuilder: (context, animation, secondaryAnimation) => const SearchScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for gigs...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Less border radius
                              borderSide: BorderSide(
                                color: wawuColors.borderPrimary.withOpacity(0.5), // Border color
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Less border radius
                              borderSide: BorderSide(
                                color: wawuColors.borderPrimary.withOpacity(0.5), // Border color
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0), // Less border radius
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor, // Focused border color
                                width: 2.0,
                              ),
                            ),
                            filled: false, // Not filled
                            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
                // Suggested Gigs Section - Horizontal Scroll (TOP PRIORITY!)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: CustomIntroText(text: 'Gigs You May Like'),
                      ),
                      const SizedBox(height: 20),
                      _buildSuggestedGigsSection(gigProvider),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Updates Section
                      const CustomIntroText(text: 'Updates'),
                      const SizedBox(height: 20),
                      _buildAdsSection(adProvider),
                      const SizedBox(height: 30),
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
                    ]),
                  ),
                ),
                // Recently Viewed Gigs Section - Horizontal Scroll
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only show the header if a user is logged in
                      if (userProvider.currentUser != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: CustomIntroText(text: 'Recently Viewed'),
                        ),
                      if (userProvider.currentUser != null)
                        const SizedBox(height: 20),
                      _buildRecentlyViewedGigsSection(gigProvider, userProvider),
                      if (userProvider.currentUser != null)
                        const SizedBox(height: 30),
                    ],
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