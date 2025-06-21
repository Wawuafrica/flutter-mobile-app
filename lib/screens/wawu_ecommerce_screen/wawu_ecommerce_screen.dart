import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';
import 'package:wawu_mobile/utils/error_utils.dart';

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

  // void _navigateToProduct(Product product) {
  //   final productProvider = Provider.of<ProductProvider>(
  //     context,
  //     listen: false,
  //   );

  //   // Select the product
  //   productProvider.selectProduct(product.id);

  //   // Navigate to SinglePackage screen
  //   Navigator.pushNamed(context, '/single-package').then((_) {
  //     // Optional: Refresh products when returning from product detail
  //     // This ensures any changes are reflected
  //     if (mounted) {
  //       setState(() {});
  //     }
  //   });
  // }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wawu E-commerce'),
        actions: [
          Container(
            decoration: BoxDecoration(
              color:
                  _isSearchOpen
                      ? wawuColors.primary.withAlpha(80)
                      : wawuColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            margin: EdgeInsets.only(right: 10),
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
            SizedBox(height: 20),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading &&
                      productProvider.products.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (productProvider.hasError &&
                      productProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${productProvider.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              productProvider.fetchProducts();
                            },
                            child: const Text('Retry'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.mail_outline),
                            label: const Text('Contact Support'),
                            onPressed: () {
                              showErrorSupportDialog(
                                context: context,
                                title: 'Contact Support',
                                message:
                                    'If this problem persists, please contact our support team. We are here to help!',
                              );
                            },
                          ),
                        ],
                      ),
                    );
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
                          SizedBox(height: 16),
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
                            SizedBox(height: 12),
                            TextButton(
                              onPressed: _clearSearch,
                              child: Text('Clear Search'),
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
                      if (index < (productsToShow.length / 2).ceil()) {
                        return _buildProductRow(productsToShow, index);
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
    final baseCount = (products.length / 2).ceil(); // Number of rows
    // Add loading indicator if loading more and not searching
    return baseCount +
        (provider.isLoading && provider.hasMoreProducts && !_isSearching
            ? 1
            : 0);
  }

  Widget _buildProductRow(List<Product> products, int rowIndex) {
    final firstIndex = rowIndex * 2;
    final secondIndex = firstIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ECard(
              product: products[firstIndex],
              isMargin: false,
              // onTap: () => _navigateToProduct(products[firstIndex]),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child:
                secondIndex < products.length
                    ? ECard(
                      product: products[secondIndex],
                      isMargin: false,
                      // onTap: () => _navigateToProduct(products[secondIndex]),
                    )
                    : SizedBox(), // Empty space if odd number of products
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ProductProvider provider) {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text(
            'Loading more products...',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
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
              child: Text(
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
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearchOpen ? 55 : 0,
      child: ClipRRect(
        child: SizedBox(
          height: _isSearchOpen ? 55 : 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
            child:
                _isSearchOpen
                    ? TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: "Search products, brands, categories...",
                        hintStyle: TextStyle(fontSize: 12),
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
                                  icon: Icon(Icons.clear, size: 18),
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
