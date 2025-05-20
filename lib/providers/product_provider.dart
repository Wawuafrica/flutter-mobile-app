import 'dart:convert';
import '../models/product.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// ProductProvider manages the state of e-commerce products.
///
/// This provider handles:
/// - Fetching products with filtering and pagination
/// - Fetching featured products
/// - Fetching product details
/// - Managing cart items (add, remove, update quantity)
/// - Real-time product updates via Pusher
class ProductProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  Product? _selectedProduct;
  Map<String, int> _cartItems = {}; // Map of product ID to quantity
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  bool _isSubscribed = false;

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  Product? get selectedProduct => _selectedProduct;
  Map<String, int> get cartItems => _cartItems;
  bool get hasMoreProducts => _hasMoreProducts;
  int get currentPage => _currentPage;

  // Cart getters
  int get cartItemCount =>
      _cartItems.values.fold(0, (sum, quantity) => sum + quantity);
  List<Product> get cartProducts =>
      _products.where((p) => _cartItems.containsKey(p.id)).toList();

  double get cartTotal => cartProducts.fold(
    0.0,
    (sum, product) =>
        sum + (product.getDiscountedPrice() * (_cartItems[product.id] ?? 0)),
  );

  ProductProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Fetches products with optional filtering and pagination
  Future<List<Product>> fetchProducts({
    List<String>? categories,
    List<String>? tags,
    String? sellerId,
    double? minPrice,
    double? maxPrice,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts && !refresh) {
      return _products;
    }

    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {
          'page': _currentPage.toString(),
          'limit': '20', // Fixed page size of 20 products
          'is_available': 'true',
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          if (sellerId != null) 'seller_id': sellerId,
          if (minPrice != null) 'min_price': minPrice.toString(),
          if (maxPrice != null) 'max_price': maxPrice.toString(),
        },
      );

      final List<dynamic> productsJson = response['products'] as List<dynamic>;
      final List<Product> fetchedProducts =
          productsJson
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();

      final bool hasMorePages = response['has_more'] as bool? ?? false;

      if (refresh) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }

      _hasMoreProducts = hasMorePages;
      _currentPage++;

      // Subscribe to product channel if not already subscribed
      if (!_isSubscribed) {
        await _subscribeToProductChannel();
      }

      return _products;
    }, errorMessage: 'Failed to fetch products');

    return result ?? [];
  }

  /// Fetches featured products
  Future<List<Product>> fetchFeaturedProducts() async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/products/featured',
      );

      final List<dynamic> productsJson = response['products'] as List<dynamic>;
      final List<Product> featured =
          productsJson
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();

      _featuredProducts = featured;

      return featured;
    }, errorMessage: 'Failed to fetch featured products');

    return result ?? [];
  }

  /// Fetches details of a specific product
  Future<Product?> fetchProductDetails(String productId) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/products/$productId',
      );

      final product = Product.fromJson(response);

      // Update in products list if already loaded
      for (int i = 0; i < _products.length; i++) {
        if (_products[i].id == productId) {
          _products[i] = product;
          break;
        }
      }

      // Update in featured products if present
      for (int i = 0; i < _featuredProducts.length; i++) {
        if (_featuredProducts[i].id == productId) {
          _featuredProducts[i] = product;
          break;
        }
      }

      _selectedProduct = product;

      return product;
    }, errorMessage: 'Failed to fetch product details');
  }

  /// Sets the selected product
  void selectProduct(String productId) {
    _selectedProduct = _products.firstWhere(
      (product) => product.id == productId,
      orElse:
          () => _featuredProducts.firstWhere(
            (product) => product.id == productId,
            orElse: () => throw Exception('Product not found: $productId'),
          ),
    );

    notifyListeners();
  }

  /// Clears the selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  /// Adds a product to cart
  void addToCart(String productId, {int quantity = 1}) {
    if (quantity <= 0) return;

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse:
          () => _featuredProducts.firstWhere(
            (p) => p.id == productId,
            orElse: () => throw Exception('Product not found: $productId'),
          ),
    );

    // Check if product is available and in stock
    if (!product.isAvailable || !product.isInStock()) {
      setError('Product is not available or out of stock');
      return;
    }

    // Check if adding this quantity would exceed stock
    final currentQuantity = _cartItems[productId] ?? 0;
    final newQuantity = currentQuantity + quantity;

    if (newQuantity > product.stockQuantity) {
      setError('Cannot add more than available stock');
      return;
    }

    // Add to cart
    _cartItems[productId] = newQuantity;
    notifyListeners();
  }

  /// Updates the quantity of a product in cart
  void updateCartItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse:
          () => _featuredProducts.firstWhere(
            (p) => p.id == productId,
            orElse: () => throw Exception('Product not found: $productId'),
          ),
    );

    // Check if this quantity would exceed stock
    if (quantity > product.stockQuantity) {
      setError('Cannot add more than available stock');
      return;
    }

    // Update quantity
    _cartItems[productId] = quantity;
    notifyListeners();
  }

  /// Removes a product from cart
  void removeFromCart(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  /// Clears the cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Submits an order with the current cart items
  Future<Map<String, dynamic>?> submitOrder({
    required String userId,
    required String shippingAddress,
    required String paymentMethod,
    Map<String, dynamic>? additionalDetails,
  }) async {
    if (_cartItems.isEmpty) {
      setError('Cannot submit an empty order');
      return null;
    }

    return await handleAsync(() async {
      // Prepare order items
      final List<Map<String, dynamic>> items = [];

      for (final entry in _cartItems.entries) {
        final productId = entry.key;
        final quantity = entry.value;

        final product = _products.firstWhere(
          (p) => p.id == productId,
          orElse:
              () => _featuredProducts.firstWhere(
                (p) => p.id == productId,
                orElse: () => throw Exception('Product not found: $productId'),
              ),
        );

        items.add({
          'product_id': productId,
          'quantity': quantity,
          'price': product.getDiscountedPrice(),
          'name': product.name,
        });
      }

      // TODO: Replace with actual endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'user_id': userId,
          'items': items,
          'shipping_address': shippingAddress,
          'payment_method': paymentMethod,
          'total_amount': cartTotal,
          if (additionalDetails != null)
            'additional_details': additionalDetails,
        },
      );

      // Clear cart after successful order
      clearCart();

      return response;
    }, errorMessage: 'Failed to submit order');
  }

  /// Subscribes to product channel for real-time updates
  Future<void> _subscribeToProductChannel() async {
    // Channel name: 'products'
    const channelName = 'products';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to product updated event
      _pusherService.bindToEvent(channelName, 'product-updated', (data) async {
        if (data is String) {
          final productData = jsonDecode(data) as Map<String, dynamic>;
          final updatedProduct = Product.fromJson(productData);

          // Update in products list
          for (int i = 0; i < _products.length; i++) {
            if (_products[i].id == updatedProduct.id) {
              _products[i] = updatedProduct;
              break;
            }
          }

          // Update in featured products
          for (int i = 0; i < _featuredProducts.length; i++) {
            if (_featuredProducts[i].id == updatedProduct.id) {
              _featuredProducts[i] = updatedProduct;
              break;
            }
          }

          // Update selected product if it's the one being updated
          if (_selectedProduct != null &&
              _selectedProduct!.id == updatedProduct.id) {
            _selectedProduct = updatedProduct;
          }

          // Check if product in cart is no longer available or in stock
          if (_cartItems.containsKey(updatedProduct.id)) {
            if (!updatedProduct.isAvailable || !updatedProduct.isInStock()) {
              _cartItems.remove(updatedProduct.id);
              setError(
                'Product "${updatedProduct.name}" has been removed from your cart because it\'s no longer available.',
              );
            } else if (_cartItems[updatedProduct.id]! >
                updatedProduct.stockQuantity) {
              // Adjust quantity if current quantity exceeds new stock
              _cartItems[updatedProduct.id] = updatedProduct.stockQuantity;
              setError(
                'The quantity of "${updatedProduct.name}" in your cart has been adjusted due to stock changes.',
              );
            }
          }

          notifyListeners();
        }
      });

      // Bind to product stock updated event (for stock-only updates)
      _pusherService.bindToEvent(channelName, 'product-stock-updated', (
        data,
      ) async {
        if (data is String) {
          final stockData = jsonDecode(data) as Map<String, dynamic>;
          final String productId = stockData['product_id'] as String;
          final int newStock = stockData['stock_quantity'] as int;

          // Update product stock in products list
          for (int i = 0; i < _products.length; i++) {
            if (_products[i].id == productId) {
              _products[i] = _products[i].copyWith(stockQuantity: newStock);
              break;
            }
          }

          // Update in featured products
          for (int i = 0; i < _featuredProducts.length; i++) {
            if (_featuredProducts[i].id == productId) {
              _featuredProducts[i] = _featuredProducts[i].copyWith(
                stockQuantity: newStock,
              );
              break;
            }
          }

          // Update selected product if it's the one being updated
          if (_selectedProduct != null && _selectedProduct!.id == productId) {
            _selectedProduct = _selectedProduct!.copyWith(
              stockQuantity: newStock,
            );
          }

          // Check if product in cart needs adjustment due to stock changes
          if (_cartItems.containsKey(productId)) {
            if (newStock <= 0) {
              _cartItems.remove(productId);
              setError(
                'Product has been removed from your cart because it\'s out of stock.',
              );
            } else if (_cartItems[productId]! > newStock) {
              // Adjust quantity if current quantity exceeds new stock
              _cartItems[productId] = newStock;
              setError(
                'The quantity in your cart has been adjusted due to stock changes.',
              );
            }
          }

          notifyListeners();
        }
      });
    }
  }

  /// Clears all product data except cart
  void clearProductData() {
    _products = [];
    _featuredProducts = [];
    _selectedProduct = null;
    _hasMoreProducts = true;
    _currentPage = 1;
    resetState();
  }

  /// Clears all data including cart
  void clearAll() {
    clearProductData();
    _cartItems.clear();
    _isSubscribed = false;
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
    }
    super.dispose();
  }
}
