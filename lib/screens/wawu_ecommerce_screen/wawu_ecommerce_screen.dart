import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:wawu_mobile/widgets/e_card/e_card.dart';
import 'package:wawu_mobile/providers/product_provider.dart';
import 'package:wawu_mobile/models/variant.dart';

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

    _filteredProducts =
        allProducts.where((product) {
          final searchLower = query.toLowerCase();
          return product.name.toLowerCase().contains(searchLower) ||
              product.description.toLowerCase().contains(searchLower) ||
              product.manufacturerBrand.toLowerCase().contains(searchLower) ||
              product.category.toLowerCase().contains(searchLower) ||
              product.tags.any(
                (tag) => tag.toLowerCase().contains(searchLower),
              );
        }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wawu E-commerce'),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: wawuColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            margin: EdgeInsets.only(right: 10),
            height: 36,
            width: 36,
            child: IconButton(
              icon: Icon(Icons.search, size: 17, color: wawuColors.primary),
              onPressed: () {
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                  if (!_isSearchOpen) {
                    _searchController.clear();
                    _isSearching = false;
                    _filteredProducts = [];
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
            SizedBox(height: 20),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading &&
                      productProvider.products.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (productProvider.hasError &&
                      productProvider.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${productProvider.errorMessage}'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                () => productProvider.fetchProducts(
                                  refresh: true,
                                ),
                            child: Text('Retry'),
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
                      child: Text(
                        _isSearching
                            ? 'No products found for your search'
                            : 'No products available',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _getItemCount(productsToShow, productProvider),
                    itemBuilder: (context, index) {
                      if (index < productsToShow.length) {
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
      child: CircularProgressIndicator(),
    );
  }

  // void _navigateToProduct(Product product) {
  //   final productProvider = Provider.of<ProductProvider>(
  //     context,
  //     listen: false,
  //   );
  //   productProvider.selectProduct(product.id);

  //   // Navigate to SinglePackage screen
  //   Navigator.pushNamed(context, '/single-package');
  // }

  Widget _buildInPageSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
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
