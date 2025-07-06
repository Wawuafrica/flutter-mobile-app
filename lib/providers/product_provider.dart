import 'dart:convert';
import '../models/variant.dart';
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
/// - Real-time product updates via Pusher based on new event structure
class ProductProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  Product? _selectedProduct;
  final Map<String, int> _cartItems = {}; // Map of product ID to quantity
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  bool _isGeneralChannelSubscribed = false;
  final Set<String> _subscribedProductChannels =
      {}; // Track subscribed product channels

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
    int? status, // 1 for available, 2 for disabled
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts && !refresh) {
      return _products;
    }

    try {
      setLoading();

      final queryParams = <String, String>{
        'paginate': 'true',
        'pageNumber': _currentPage.toString(),
      };

      // Add optional filters
      if (status != null) {
        queryParams['status'] = status.toString();
      }

      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }

      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      if (minPrice != null && maxPrice != null) {
        queryParams['price'] =
            maxPrice.toString(); // Using maxPrice as the price filter
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/e-commerce/products',
        queryParameters: queryParams,
      );

      if (response['statusCode'] != 200) {
        throw Exception(response['message'] ?? 'Failed to fetch products');
      }

      final List<dynamic> productsJson = response['data'] as List<dynamic>;
      final List<Product> fetchedProducts =
          productsJson
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();

      // Check if there are more pages (you might need to adjust this logic based on your API response)
      final bool hasMorePages =
          fetchedProducts.length >= 20; // Assuming 20 is the page size

      if (refresh) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }

      _hasMoreProducts = hasMorePages;
      _currentPage++;

      // Update featured products (assuming published and available products are featured)
      _featuredProducts = _products.where((p) => p.isFeatured).toList();

      // Subscribe to general products channel if not already subscribed
      if (!_isGeneralChannelSubscribed) {
        await _subscribeToGeneralProductsChannel();
      }

      setSuccess();
      return _products;
    } catch (e) {
      setError('Failed to fetch products: $e');
      print('Failed to fetch products: $e');
      return [];
    }
  }

  /// Fetches featured products (available and published products)
  Future<List<Product>> fetchFeaturedProducts() async {
    try {
      setLoading();

      final response = await _apiService.get<Map<String, dynamic>>(
        '/e-commerce/products',
        queryParameters: {
          'paginate': 'true',
          'pageNumber': '1',
          'status': '1', // Only available products
        },
      );

      if (response['statusCode'] != 200) {
        throw Exception(
          response['message'] ?? 'Failed to fetch featured products',
        );
      }

      final List<dynamic> productsJson = response['data'] as List<dynamic>;
      final List<Product> allProducts =
          productsJson
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();

      // Filter for featured products (published and available)
      _featuredProducts = allProducts.where((p) => p.isFeatured).toList();

      setSuccess();
      return _featuredProducts;
    } catch (e) {
      setError('Failed to fetch featured products: $e');
      print('Failed to fetch featured products: $e');
      return [];
    }
  }

  /// Fetches details of a specific product and subscribes to its channel
  Future<Product?> fetchProductDetails(String productId) async {
    try {
      setLoading();

      final response = await _apiService.get<Map<String, dynamic>>(
        '/e-commerce/products/$productId',
      );

      if (response['statusCode'] != 200) {
        throw Exception(
          response['message'] ?? 'Failed to fetch product details',
        );
      }

      final product = Product.fromJson(
        response['data'] as Map<String, dynamic>,
      );

      _updateProductInLists(productId, product);
      _selectedProduct = product;

      // Subscribe to the specific product channels
      await _subscribeToSpecificProductChannels(productId);

      setSuccess();
      return product;
    } catch (e) {
      setError('Failed to fetch product details: $e');
      print('Failed to fetch product details: $e');
      return null;
    }
  }

  /// Updates a product in products and featuredProducts lists
  void _updateProductInLists(String productId, Product updatedProduct) {
    bool foundInProducts = false;
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].id == productId) {
        _products[i] = updatedProduct;
        foundInProducts = true;
        break;
      }
    }

    // If the updated product is not in the current list, but is available, add it.
    if (!foundInProducts && updatedProduct.isAvailable) {
      _products.insert(0, updatedProduct);
    }

    // Remove from products if it's no longer available
    if (foundInProducts && !updatedProduct.isAvailable) {
      _products.removeWhere((p) => p.id == productId);
    }

    bool foundInFeatured = false;
    for (int i = 0; i < _featuredProducts.length; i++) {
      if (_featuredProducts[i].id == productId) {
        if (updatedProduct.isFeatured && updatedProduct.isAvailable) {
          _featuredProducts[i] = updatedProduct;
        } else {
          _featuredProducts.removeAt(i);
        }
        foundInFeatured = true;
        break;
      }
    }

    // Add to featured if it's now featured but wasn't before
    if (!foundInFeatured &&
        updatedProduct.isFeatured &&
        updatedProduct.isAvailable) {
      _featuredProducts.insert(0, updatedProduct);
    }

    notifyListeners();
  }

  /// Removes a product from lists and cart
  void _removeProduct(String productId) {
    _products.removeWhere((product) => product.id == productId);
    _featuredProducts.removeWhere((product) => product.id == productId);
    _cartItems.remove(productId);
    if (_selectedProduct?.id == productId) {
      _selectedProduct = null;
    }
    notifyListeners();
  }

  /// Sets the selected product and subscribes to its channel
  void selectProduct(String productId) {
    try {
      _selectedProduct = _products.firstWhere(
        (product) => product.id == productId,
        orElse:
            () => _featuredProducts.firstWhere(
              (product) => product.id == productId,
            ),
      );

      if (_selectedProduct != null) {
        // Subscribe to the specific product channels
        _subscribeToSpecificProductChannels(productId);
        notifyListeners();
      } else {
        print('Product not found locally: $productId. Fetching from API.');
        fetchProductDetails(productId);
      }
    } catch (e) {
      print('Failed to select product: $e');
      // If product not found locally, fetch from API
      fetchProductDetails(productId);
    }
  }

  /// Clears the selected product and unsubscribes from its channel
  void clearSelectedProduct() {
    if (_selectedProduct != null) {
      _unsubscribeFromSpecificProductChannels(_selectedProduct!.id);
    }
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

    // Check if product is available
    if (!product.isAvailable) {
      setError('Product is not available');
      return;
    }

    // Add to cart
    final currentQuantity = _cartItems[productId] ?? 0;
    _cartItems[productId] = currentQuantity + quantity;
    notifyListeners();
  }

  /// Updates the quantity of a product in cart
  void updateCartItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

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

    try {
      setLoading();

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

      final response = await _apiService.post<Map<String, dynamic>>(
        '/e-commerce/orders',
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
      setSuccess();
      return response;
    } catch (e) {
      setError('Failed to submit order: $e');
      print('Failed to submit order: $e');
      return null;
    }
  }

  /// Subscribes to the general products channel for creates
  Future<void> _subscribeToGeneralProductsChannel() async {
    const channelName = 'products';
    try {
      await _pusherService.subscribeToChannel(channelName);

      _isGeneralChannelSubscribed = true;
      _pusherService.bindToEvent(
        channelName,
        'product.created',
        _handleProductCreated,
      );

      print('✅ Subscribed to general products channel');
    } catch (e) {
      print('❌ Failed to subscribe to general products channel: $e');
    }
  }

  /// Subscribes to specific product channels for updates, deletes, and reviews
  Future<void> _subscribeToSpecificProductChannels(String productId) async {
    // Avoid duplicate subscriptions
    if (_subscribedProductChannels.contains(productId)) {
      return;
    }

    final updatedChannelName = 'product.updated.$productId';
    final deletedChannelName = 'product.deleted.$productId';
    final reviewChannelName = 'product.review.created.$productId';

    try {
      // Subscribe to updated channel
      await _pusherService.subscribeToChannel(updatedChannelName);
      _pusherService.bindToEvent(
        updatedChannelName,
        'product.updated',
        _handleProductUpdated,
      );

      // Subscribe to deleted channel
      await _pusherService.subscribeToChannel(deletedChannelName);
      _pusherService.bindToEvent(
        deletedChannelName,
        'product.deleted',
        _handleProductDeleted,
      );

      // Subscribe to review channel
      await _pusherService.subscribeToChannel(reviewChannelName);
      _pusherService.bindToEvent(
        reviewChannelName,
        'product.review.created',
        _handleProductReviewCreated,
      );

      _subscribedProductChannels.add(productId);
      print('✅ Subscribed to specific product channels for $productId');
    } catch (e) {
      print(
        '❌ Failed to subscribe to specific product channels for $productId: $e',
      );
    }
  }

  /// Unsubscribes from specific product channels
  Future<void> _unsubscribeFromSpecificProductChannels(String productId) async {
    if (!_subscribedProductChannels.contains(productId)) {
      return;
    }

    final updatedChannelName = 'product.updated.$productId';
    final deletedChannelName = 'product.deleted.$productId';
    final reviewChannelName = 'product.review.created.$productId';

    try {
      await _pusherService.unsubscribeFromChannel(updatedChannelName);
      await _pusherService.unsubscribeFromChannel(deletedChannelName);
      await _pusherService.unsubscribeFromChannel(reviewChannelName);

      _subscribedProductChannels.remove(productId);
      print('✅ Unsubscribed from specific product channels for $productId');
    } catch (e) {
      print(
        '❌ Failed to unsubscribe from specific product channels for $productId: $e',
      );
    }
  }

  // Enhanced Pusher event handlers with better error handling and logging
  void _handleProductCreated(dynamic data) {
    try {
      print('📦 Received product.created event');

      Map<String, dynamic> productData;
      if (data is String) {
        productData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        productData = data;
      } else {
        print('❌ Invalid product.created event data type: ${data.runtimeType}');
        return;
      }

      final newProduct = Product.fromJson(productData);
      print(
        '📦 New product created: ${newProduct.name} (ID: ${newProduct.id})',
      );

      // Only add if product is available and not already in list
      if (newProduct.isAvailable &&
          !_products.any((p) => p.id == newProduct.id)) {
        _products.insert(0, newProduct);

        if (newProduct.isFeatured) {
          _featuredProducts.insert(0, newProduct);
        }

        notifyListeners();
        print('✅ Product added to local lists');
      }
    } catch (e) {
      print('❌ Failed to handle product.created event: $e');
    }
  }

  void _handleProductUpdated(dynamic data) {
    try {
      print('📦 Received product.updated event');

      Map<String, dynamic> productData;
      if (data is String) {
        productData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        productData = data;
      } else {
        print('❌ Invalid product.updated event data type: ${data.runtimeType}');
        return;
      }

      final updatedProduct = Product.fromJson(productData);
      final String productId = updatedProduct.id;

      print('📦 Product updated: ${updatedProduct.name} (ID: $productId)');

      _updateProductInLists(productId, updatedProduct);

      // Update selected product if it's the same one
      if (_selectedProduct?.id == productId) {
        _selectedProduct = updatedProduct;
        print('✅ Selected product updated');
      }

      // Handle cart item availability changes
      if (_cartItems.containsKey(productId)) {
        if (!updatedProduct.isAvailable) {
          _cartItems.remove(productId);
          print('🛒 Product removed from cart - no longer available');
          // You might want to show a user notification here
        } else {
          print('🛒 Product in cart updated');
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Failed to handle product.updated event: $e');
    }
  }

  void _handleProductDeleted(dynamic data) {
    try {
      print('📦 Received product.deleted event');

      Map<String, dynamic> deletedData;
      if (data is String) {
        deletedData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        deletedData = data;
      } else {
        print('❌ Invalid product.deleted event data type: ${data.runtimeType}');
        return;
      }

      final String? deletedProductId = deletedData['product_uuid'] as String?;

      if (deletedProductId != null) {
        print('📦 Product deleted: $deletedProductId');

        // Find the product name before removing (for logging)
        final productName =
            _products
                .firstWhere(
                  (p) => p.id == deletedProductId,
                  orElse:
                      () => Product(
                        id: '',
                        name: 'Unknown Product',
                        description: '',
                        category: '',
                        tags: [],
                        shortDescription: '',
                        status: '',
                        type: '',
                        visibility: '',
                        publishAt: '',
                        manufacturerName: '',
                        manufacturerBrand: '',
                        price: 0.0,
                        currency: '',
                        discount: 0.0,
                        images: [],
                        variants: [],
                      ),
                )
                .name;

        _removeProduct(deletedProductId);
        _unsubscribeFromSpecificProductChannels(deletedProductId);

        print('✅ Product "$productName" removed from local lists and cart');
        // You might want to show a user notification here
      } else {
        print('❌ product.deleted event data missing product_uuid');
      }
    } catch (e) {
      print('❌ Failed to handle product.deleted event: $e');
    }
  }

  void _handleProductReviewCreated(dynamic data) {
    try {
      print('📦 Received product.review.created event');

      Map<String, dynamic> reviewData;
      if (data is String) {
        reviewData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        reviewData = data;
      } else {
        print(
          '❌ Invalid product.review.created event data type: ${data.runtimeType}',
        );
        return;
      }

      final String? reviewedProductId = reviewData['product_uuid'] as String?;

      if (reviewedProductId == null) {
        print('❌ product.review.created event data missing product_uuid');
        return;
      }

      print('📦 Review created for product: $reviewedProductId');

      // Check if the product object is included in the event data
      if (reviewData.containsKey('product') &&
          reviewData['product'] is Map<String, dynamic>) {
        final updatedProduct = Product.fromJson(
          reviewData['product'] as Map<String, dynamic>,
        );
        _updateProductInLists(reviewedProductId, updatedProduct);

        // Update selected product if it's the same one
        if (_selectedProduct?.id == reviewedProductId) {
          _selectedProduct = updatedProduct;
          print('✅ Selected product updated with new review data');
        }

        notifyListeners();
      } else {
        // If product data is not included, we might need to refetch the product
        print(
          '⚠️ Product data not included in review event, consider refetching product details',
        );

        // Optionally refetch the product if it's currently selected
        if (_selectedProduct?.id == reviewedProductId) {
          fetchProductDetails(reviewedProductId);
        }
      }
    } catch (e) {
      print('❌ Failed to handle product.review.created event: $e');
    }
  }

  /// Clears all product data except cart
  void clearProductData() {
    // Unsubscribe from all specific product channels
    final productIds = List<String>.from(_subscribedProductChannels);
    for (final productId in productIds) {
      _unsubscribeFromSpecificProductChannels(productId);
    }

    _products = [];
    _featuredProducts = [];
    _selectedProduct = null;
    _hasMoreProducts = true;
    _currentPage = 1;
    resetState();
    notifyListeners();
  }

  /// Clears all data including cart and unsubscribes from all channels
  void clearAll() {
    clearProductData();
    _cartItems.clear();

    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
      _isGeneralChannelSubscribed = false;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    // Unsubscribe from general channel
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
    }

    // Unsubscribe from all specific product channels
    final productIds = List<String>.from(_subscribedProductChannels);
    for (final productId in productIds) {
      _unsubscribeFromSpecificProductChannels(productId);
    }

    super.dispose();
  }
}
