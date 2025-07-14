import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';
// import 'package:wawu_mobile/utils/error_utils.dart'; // This utility might be replaced or integrated
import 'package:wawu_mobile/widgets/custom_snackbar.dart'; // Import CustomSnackBar
import 'package:wawu_mobile/widgets/full_ui_error_display.dart';

class WawuEcommerceScreen extends StatefulWidget {
  const WawuEcommerceScreen({super.key});

  @override
  State<WawuEcommerceScreen> createState() => _WawuEcommerceScreenState();
}

class _WawuEcommerceScreenState extends State<WawuEcommerceScreen> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  // Flag to prevent showing multiple snackbars for the same error
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      productProvider.fetchProducts(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      if (productProvider.hasMoreProducts &&
          !productProvider.isLoading &&
          !_isSearching) {
        productProvider.fetchProducts();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredProducts = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final allProducts = productProvider.products;

    // Enhanced search functionality
    _filteredProducts =
        allProducts.where((product) {
          final searchLower = query.toLowerCase();
          return product.name.toLowerCase().contains(searchLower) ||
              product.description.toLowerCase().contains(searchLower) ||
              product.shortDescription.toLowerCase().contains(searchLower) ||
              product.manufacturerBrand.toLowerCase().contains(searchLower) ||
              product.category.toLowerCase().contains(searchLower) ||
              product.tags.any(
                (tag) => tag.toLowerCase().contains(searchLower),
              ) ||
              // Search in variants
              product.variants.any(
                (variant) =>
                    variant.name.toLowerCase().contains(searchLower) ||
                    variant.value.toLowerCase().contains(searchLower),
              );
        }).toList();

    // Sort search results by relevance
    _filteredProducts.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final queryLower = query.toLowerCase();

      // Exact matches first
      if (aName == queryLower && bName != queryLower) return -1;
      if (bName == queryLower && aName != queryLower) return 1;

      // Starts with query second
      if (aName.startsWith(queryLower) && !bName.startsWith(queryLower))
        return -1;
      if (bName.startsWith(queryLower) && !aName.startsWith(queryLower))
        return 1;

      // Alphabetical order for the rest
      return aName.compareTo(bName);
    });

    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredProducts = [];
      _isSearchOpen = false;
    });

    // Hide keyboard
    FocusScope.of(context).unfocus();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('WAWUAfrica E-commerce'),
        actions: [
          Container(
            decoration: BoxDecoration(
              color:
                  _isSearchOpen
                      ? wawuColors.primary.withAlpha(80)
                      : wawuColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 10),
            height: 36,
            width: 36,
            child: IconButton(
              icon: Icon(
                _isSearchOpen ? Icons.close : Icons.search,
                size: 17,
                color: wawuColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                  if (!_isSearchOpen) {
                    _clearSearch();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            _buildInPageSearchBar(),
            if (_isSearching) _buildSearchResultsHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  // Listen for errors from ProductProvider and display SnackBar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (productProvider.hasError &&
                        productProvider.errorMessage != null &&
                        !_hasShownError) {
                      CustomSnackBar.show(
                        context,
                        message: productProvider.errorMessage!,
                        isError: true,
                        actionLabel: 'RETRY',
                        onActionPressed: () {
                          productProvider.fetchProducts();
                        },
                      );
                      _hasShownError = true;
                      // It's crucial to clear the error state in the provider
                      // after it has been displayed to the user.
                      productProvider
                          .clearError(); // Assuming resetState() or clearError()
                    } else if (!productProvider.hasError && _hasShownError) {
                      _hasShownError = false;
                    }
                  });

                  // Display full error screen for critical loading failures
                  if (productProvider.hasError &&
                      productProvider.products.isEmpty &&
                      !productProvider.isLoading) {
                    return FullErrorDisplay(
                      errorMessage:
                          productProvider.errorMessage ??
                          'Failed to load products. Please try again.',
                      onRetry: () {
                        productProvider.fetchProducts(refresh: true);
                      },
                      onContactSupport: () {
                        _showErrorSupportDialog(
                          context,
                          'If this problem persists, please contact our support team. We are here to help!',
                        );
                      },
                    );
                  }

                  if (productProvider.isLoading &&
                      productProvider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final productsToShow =
                      _isSearching
                          ? _filteredProducts
                          : productProvider.products;

                  if (productsToShow.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSearching
                                ? Icons.search_off
                                : Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching
                                ? 'No products found for "${_searchController.text}"'
                                : 'No products available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_isSearching) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Clear Search'),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _getItemCount(productsToShow, productProvider),
                    itemBuilder: (context, index) {
                      if (index < productsToShow.length) {
                        // Display products in rows of two
                        if (index % 2 == 0) {
                          return _buildProductRow(productsToShow, index ~/ 2);
                        }
                        return const SizedBox.shrink(); // Hide odd indices as they are handled by the even index row
                      } else {
                        // Loading indicator at the bottom
                        return _buildLoadingIndicator(productProvider);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getItemCount(List<Product> products, ProductProvider provider) {
    // Each row has 2 products, so we need ceil(products.length / 2) rows.
    // If products.length is odd, the last row will have one product and one SizedBox.
    final baseRowCount = (products.length / 2).ceil();
    // Add an extra item for the loading indicator if loading more and not searching.
    return (baseRowCount *
            2) + // Total items if laid out linearly, including placeholders
        (provider.isLoading && provider.hasMoreProducts && !_isSearching
            ? 1
            : 0);
  }

  Widget _buildProductRow(List<Product> products, int rowIndex) {
    final firstProductIndex = rowIndex * 2;
    final secondProductIndex = firstProductIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ECard(
              product: products[firstProductIndex],
              isMargin: false,
              // onTap: () => _navigateToProduct(products[firstIndex]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                secondProductIndex < products.length
                    ? ECard(
                      product: products[secondProductIndex],
                      isMargin: false,
                      // onTap: () => _navigateToProduct(products[secondIndex]),
                    )
                    : const SizedBox(), // Empty space if odd number of products
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ProductProvider provider) {
    // Only show loading indicator if there are more products to load
    if (provider.isLoading && provider.hasMoreProducts && !_isSearching) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Loading more products...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // Hide if not loading more
  }

  Widget _buildSearchResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredProducts.length} result${_filteredProducts.length != 1 ? 's' : ''} found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: _clearSearch,
              child: const Text(
                'Clear',
                style: TextStyle(color: wawuColors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearchOpen ? 55 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 55 : 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 0.0,
              vertical: 10.0,
            ),
            child:
                _isSearchOpen
                    ? TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: "Search products, brands, categories...",
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: wawuColors.primary.withAlpha(30),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: wawuColors.primary.withAlpha(60),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: wawuColors.primary),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: wawuColors.primary,
                          size: 18,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                                : null,
                      ),
                    )
                    : null,
          ),
        ),
      ),
    );
  }
}
