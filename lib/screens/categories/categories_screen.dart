import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/screens/categories/sub_categories_and_services_screen.dart/sub_categories_and_services.dart';
import 'package:wawu_mobile/screens/search/search_screen.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late ScrollController _scrollController;
  bool _isAppBarOpaque = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
        categoryProvider.fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    const scrollThreshold = 200.0; // Point at which the app bar title appears
    final isOpaque =
        _scrollController.hasClients &&
        _scrollController.offset > scrollThreshold;
    if (isOpaque != _isAppBarOpaque) {
      setState(() {
        _isAppBarOpaque = isOpaque;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;
    final categoryCount = categories.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC), // Light purple background
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0, // Increased height for the results text
            pinned: true,
            backgroundColor:
                _isAppBarOpaque ? const Color(0xFFF8F5FC) : Colors.transparent,
            elevation: _isAppBarOpaque ? 1 : 0,
            iconTheme: IconThemeData(
              color: _isAppBarOpaque ? Colors.black : Colors.white,
            ),
            // Title that appears on scroll
            title: AnimatedOpacity(
              opacity: _isAppBarOpaque ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Text(
                'Categories', // Renamed
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    // Prevents the zoomed image from overflowing
                    child: Transform.scale(
                      scale:
                          1.5, // Zoom factor. 1.0 is normal, 1.5 is 50% zoom.
                      child: Image.asset(
                        'assets/background_wawu.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFFF8F5FC),
                          const Color(0xFFF8F5FC).withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.9],
                      ),
                    ),
                  ),
                  // Content within the scrollable header
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 60,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories', // Renamed
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            readOnly: true,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(),
                                  ),
                                ),
                            decoration: InputDecoration(
                              hintText: 'Search Service',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // **Results count is now part of the header**
                          Text(
                            '$categoryCount Results',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conditional display for loading, error, or the list
          if (categoryProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (categoryProvider.hasError && categories.isEmpty)
            SliverFillRemaining(
              child: FullErrorDisplay(
                errorMessage:
                    categoryProvider.errorMessage ??
                    'Failed to load categories',
                onRetry: () => categoryProvider.fetchCategories(),
                onContactSupport: () {},
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    shadowColor: Colors.purple.withOpacity(0.1),
                    child: ListTile(
                      title: Text(category.name),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        categoryProvider.selectCategory(category);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const SubCategoriesAndServices(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }, childCount: categoryCount),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement "Become a Seller" logic
        },
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.store, color: Colors.white),
        label: const Text(
          'Become a Seller',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
