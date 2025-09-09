import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/category_provider.dart';
import 'package:wawu_mobile/models/category.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/screens/categories/filtered_gigs/filtered_gigs.dart';
import 'package:wawu_mobile/screens/search/search_screen.dart';
import 'package:wawu_mobile/screens/wawu_africa/sign_up/sign_up.dart';

class SubCategoriesAndServices extends StatefulWidget {
  const SubCategoriesAndServices({super.key});

  @override
  State<SubCategoriesAndServices> createState() =>
      _SubCategoriesAndServicesState();
}

class _SubCategoriesAndServicesState extends State<SubCategoriesAndServices> {
  final Map<String, List<Service>> _subCategoryServices = {};
  final Map<String, bool> _loadingServices = {};
  bool _isInitialLoading = true;
  late ScrollController _scrollController;
  bool _isAppBarOpaque = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final selectedCategory = categoryProvider.selectedCategory;

    if (selectedCategory != null) {
      setState(() => _isInitialLoading = true);
      _subCategoryServices.clear();
      _loadingServices.clear();
      await _loadSubCategories();
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadSubCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final selectedCategory = categoryProvider.selectedCategory;
    if (selectedCategory != null) {
      await categoryProvider.fetchSubCategories(selectedCategory.uuid);
    }
  }

  Future<void> _loadServicesForSubCategory(String subCategoryId) async {
    if (_subCategoryServices.containsKey(subCategoryId)) return;
    if (mounted) setState(() => _loadingServices[subCategoryId] = true);

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    final services = await categoryProvider.fetchServices(subCategoryId);
    if (mounted) {
      setState(() {
        _subCategoryServices[subCategoryId] = services;
        _loadingServices[subCategoryId] = false;
      });
    }
  }

  void _onServiceTap(Service service) {
    Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).selectService(service);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilteredGigs()),
    );
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
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final userProvider = Provider.of<UserProvider>(context);

        final selectedCategory = categoryProvider.selectedCategory;
        final categoryName = selectedCategory?.name ?? 'Category';
        final subCategoryCount = categoryProvider.subCategories.length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F5FC),
          body: CustomScrollView(
            controller: _scrollController, // Assign the controller here
            slivers: [
              // ===== START OF CORRECTED CODE =====
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                // DYNAMIC: Changes color based on the scroll position
                backgroundColor: _isAppBarOpaque ? const Color(0xFFF8F5FC) : Colors.transparent,
                // DYNAMIC: Ensures the correct color tint in the collapsed state for Material 3
                surfaceTintColor: const Color(0xFFF8F5FC),
                elevation: 0,
                // DYNAMIC: Changes the back button color
                iconTheme: IconThemeData(color: _isAppBarOpaque ? Colors.black : Colors.white),
                title: AnimatedOpacity(
                  opacity: _isAppBarOpaque ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.black, // This is correct for the collapsed state
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
                        child: Container(color: Colors.black.withOpacity(0.4)),
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
                              Text(
                                categoryName,
                                style: const TextStyle(
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
                                    builder:
                                        (context) => const SearchScreen(),
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
                              Text(
                                '$subCategoryCount Results',
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
              // ===== END OF CORRECTED CODE =====
              
              if (_isInitialLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (categoryProvider.hasError && subCategoryCount == 0)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${categoryProvider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadSubCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final subCategory = categoryProvider.subCategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildSubCategoryExpansionTile(subCategory),
                      );
                    }, childCount: subCategoryCount),
                  ),
                ),
            ],
          ),
          floatingActionButton:
              userProvider.currentUser == null
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUp()),
                        );
                      },
                      backgroundColor: Colors.purple,
                      icon: const Icon(Icons.store, color: Colors.white),
                      label: const Text(
                        'Become a Seller',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : null,
        );
      },
    );
  }

  /// Builds the correctly styled ExpansionTile.
  Widget _buildSubCategoryExpansionTile(SubCategory subCategory) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Material(
        elevation: 2.0,
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            iconColor: Colors.black,
            collapsedIconColor: Colors.black,
            title: Text(
              subCategory.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            onExpansionChanged: (isExpanded) {
              if (isExpanded) _loadServicesForSubCategory(subCategory.uuid);
            },
            // This is the key: the children now have their own container that is clipped
            // to create the seamless-but-separate look.
            children: [_buildServicesContent(subCategory.uuid)],
          ),
        ),
      ),
    );
  }

  /// Builds the purple container that holds the list of services.
  Widget _buildServicesContent(String subCategoryId) {
    final bool isLoading = _loadingServices[subCategoryId] ?? false;
    final List<Service> services = _subCategoryServices[subCategoryId] ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 13.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Builder(
        builder: (context) {
          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (services.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No services available',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return Column(
            children:
                services.map((service) => _buildServiceItem(service)).toList(),
          );
        },
      ),
    );
  }

  /// Builds a single tappable service item row.
  Widget _buildServiceItem(Service service) {
    return InkWell(
      onTap: () => _onServiceTap(service),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.north_east,
              size: 16,
              color: Colors.black.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}