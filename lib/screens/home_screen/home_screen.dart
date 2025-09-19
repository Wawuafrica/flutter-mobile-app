import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/providers/ad_provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/providers/wawu_africa_provider.dart';
import 'package:wawu_mobile/providers/gig_provider.dart';
import 'package:wawu_mobile/screens/categories/categories_screen.dart';
import 'package:wawu_mobile/screens/home_screen/home_header.dart';
import 'package:wawu_mobile/screens/home_screen/popular_service_section.dart';
import 'package:wawu_mobile/screens/home_screen/recently_viewed_gigs_section.dart';
import 'package:wawu_mobile/screens/home_screen/suggested_gigs_section.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/custom_intro_text/custom_intro_text.dart';
import 'package:wawu_mobile/widgets/custom_snackbar.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<double>? onScroll;

  const HomeScreen({super.key, this.onScroll});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late ScrollController _internalScrollController;

  @override
  void initState() {
    super.initState();
    _internalScrollController = ScrollController();
    _internalScrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _internalScrollController.removeListener(_handleScroll);
    _internalScrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.onScroll != null) {
      widget.onScroll!(_internalScrollController.offset);
    }
  }

  void _initializeData() {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final gigProvider = Provider.of<GigProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final wawuAfricProvider = Provider.of<WawuAfricaProvider>(
      context,
      listen: false,
    );

    userProvider.fetchCurrentUser();

    if (wawuAfricProvider.categories.isEmpty && !wawuAfricProvider.isLoading) {
      wawuAfricProvider.fetchCategories();
    }

    if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
      categoryProvider.fetchCategories();
    }

    if (adProvider.ads.isEmpty && !adProvider.isLoading) {
      adProvider.fetchAds();
    }

    if (userProvider.currentUser != null) {
      if (gigProvider.recentlyViewedGigs.isEmpty &&
          !gigProvider.isRecentlyViewedLoading) {
        gigProvider.fetchRecentlyViewedGigs();
      }
    } else {
      gigProvider.clearRecentlyViewedGigs();
    }

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
      final wawuAfricProvider = Provider.of<WawuAfricaProvider>(
        context,
        listen: false,
      );
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      final gigProvider = Provider.of<GigProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final futures = <Future>[
        userProvider.fetchCurrentUser(),
        categoryProvider.fetchCategories(),
        wawuAfricProvider.fetchCategories(),
        adProvider.refresh(),
        gigProvider.fetchSuggestedGigs(),
      ];

      if (userProvider.currentUser != null) {
        futures.add(gigProvider.fetchRecentlyViewedGigs());
      } else {
        gigProvider.clearRecentlyViewedGigs();
      }

      await Future.wait(futures);

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Data refreshed successfully',
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to refresh data: $error',
          isError: true,
        );
      }
    }
  }

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

  bool _hasCriticalError(
    CategoryProvider categoryProvider,
    GigProvider gigProvider,
    UserProvider userProvider,
    WawuAfricaProvider wawuAfricaProvider,
  ) {
    if ((wawuAfricaProvider.hasError &&
            wawuAfricaProvider.categories.isEmpty &&
            !wawuAfricaProvider.isLoading) ||
        (categoryProvider.hasError &&
            categoryProvider.categories.isEmpty &&
            !categoryProvider.isLoading) ||
        (gigProvider.hasError &&
            gigProvider.suggestedGigs.isEmpty &&
            !gigProvider.isSuggestedGigsLoading)) {
      return true;
    }
    if (userProvider.currentUser != null &&
        gigProvider.hasError &&
        gigProvider.recentlyViewedGigs.isEmpty &&
        !gigProvider.isRecentlyViewedLoading) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> _getPrimaryError(
    CategoryProvider categoryProvider,
    WawuAfricaProvider wawuAfricaProvider,
    GigProvider gigProvider,
    UserProvider userProvider,
  ) {
    if (wawuAfricaProvider.hasError &&
        wawuAfricaProvider.categories.isEmpty &&
        !wawuAfricaProvider.isLoading) {
      return {
        'message':
            wawuAfricaProvider.errorMessage ?? 'Failed to load +HER categories',
        'retry': () => wawuAfricaProvider.fetchCategories(),
      };
    }

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

  bool _isAnyProviderLoading(
    CategoryProvider categoryProvider,
    WawuAfricaProvider wawuAfricaProvider,
    GigProvider gigProvider,
    UserProvider userProvider,
  ) {
    bool loadingCategories =
        (categoryProvider.isLoading && categoryProvider.categories.isEmpty);
    bool loadingHERCategories =
        (wawuAfricaProvider.isLoading && wawuAfricaProvider.categories.isEmpty);
    bool loadingSuggestedGigs =
        (gigProvider.isSuggestedGigsLoading &&
            gigProvider.suggestedGigs.isEmpty);
    bool loadingRecentlyViewedGigs =
        (userProvider.currentUser != null &&
            gigProvider.isRecentlyViewedLoading &&
            gigProvider.recentlyViewedGigs.isEmpty);

    return loadingHERCategories ||
        loadingCategories ||
        loadingSuggestedGigs ||
        loadingRecentlyViewedGigs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      WawuAfricaProvider,
      CategoryProvider,
      UserProvider,
      GigProvider
    >(
      builder: (
        context,
        wawuAfricaProvider,
        categoryProvider,
        userProvider,
        gigProvider,
        child,
      ) {
        bool hasCriticalError = _hasCriticalError(
          categoryProvider,
          gigProvider,
          userProvider,
          wawuAfricaProvider,
        );

        bool isLoading = _isAnyProviderLoading(
          categoryProvider,
          wawuAfricaProvider,
          gigProvider,
          userProvider,
        );

        if (hasCriticalError) {
          final errorInfo = _getPrimaryError(
            categoryProvider,
            wawuAfricaProvider,
            gigProvider,
            userProvider,
          );

          return Scaffold(
            body: FullErrorDisplay(
              errorMessage: errorInfo['message'] ?? 'An error occurred',
              onRetry: errorInfo['retry'] ?? () {},
              onContactSupport: () {
                _showErrorSupportDialog(
                  context,
                  'If this problem persists, please contact our support team. We are here to help!',
                );
              },
            ),
          );
        }

        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refreshData,
            color: Theme.of(context).primaryColor,
            backgroundColor: Colors.white,
            displacement: 40.0,
            strokeWidth: 2.0,
            child: CustomScrollView(
              controller: _internalScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // const CustomIntroText(text: 'Updates'),
                      // const SizedBox(height: 20),
                      // const AdsSection(),
                      const SizedBox(height: 30),
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
                      const SizedBox(
                        width: double.infinity,
                        height: 160,
                        child: PopularServicesSection(),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: CustomIntroText(text: 'Gigs You May Like'),
                      ),
                      SizedBox(height: 20),
                      SuggestedGigsSection(),
                      SizedBox(height: 30),
                    ],
                  ),
                ),

                // Recently Viewed Gigs Section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userProvider.currentUser != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: CustomIntroText(text: 'Recently Viewed'),
                        ),
                      if (userProvider.currentUser != null)
                        const SizedBox(height: 20),
                      const RecentlyViewedGigsSection(),
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
