import 'dart:convert';
import '../models/variant.dart'; // Assuming 'Product' is in this file or a similar 'product.dart'
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';
import 'package:logger/logger.dart'; // Import Logger

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
  final Logger _logger = Logger(); // Add Logger instance

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
      _pusherService = pusherService ?? PusherService() {
    _listenToPusherInitialization(); // Call this in the constructor
  }

  // New method to listen for PusherService initialization
  void _listenToPusherInitialization() {
    _pusherService.onInitialized.listen((isInitialized) async {
      if (isInitialized && !_isGeneralChannelSubscribed) {
        _logger.d(
          "ProductProvider: PusherService is initialized. Attempting to subscribe to general product channel.",
        );
        await _subscribeToGeneralProductsChannel();
      }
    });
  }

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

    setLoading(); // Use BaseProvider's setLoading

    try {
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

      // This call is now redundant here if _listenToPusherInitialization handles it
      // but keeping it won't hurt, as _isGeneralChannelSubscribed prevents re-subscription.
      // await _subscribeToGeneralProductsChannel();

      setSuccess(); // Use BaseProvider's setSuccess
      return _products;
    } catch (e) {
      setError(e.toString()); // Use BaseProvider's setError with e.toString()
      return [];
    }
  }

  /// Fetches featured products (available and published products)
  Future<List<Product>> fetchFeaturedProducts() async {
    setLoading(); // Use BaseProvider's setLoading
    try {
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

      setSuccess(); // Use BaseProvider's setSuccess
      return _featuredProducts;
    } catch (e) {
      setError(e.toString()); // Use BaseProvider's setError with e.toString()
      return [];
    }
  }

  /// Fetches details of a specific product and subscribes to its channel
  Future<Product?> fetchProductDetails(String productId) async {
    setLoading(); // Use BaseProvider's setLoading
    try {
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

      setSuccess(); // Use BaseProvider's setSuccess
      return product;
    } catch (e) {
      setError(e.toString()); // Use BaseProvider's setError with e.toString()
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

    setSuccess(); // Use setSuccess to notify listeners
  }

  /// Removes a product from lists and cart
  void _removeProduct(String productId) {
    _products.removeWhere((product) => product.id == productId);
    _featuredProducts.removeWhere((product) => product.id == productId);
    _cartItems.remove(productId);
    if (_selectedProduct?.id == productId) {
      _selectedProduct = null;
    }
    setSuccess(); // Use setSuccess to notify listeners
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
        setSuccess(); // Use setSuccess to notify listeners
      } else {
        fetchProductDetails(productId);
      }
    } catch (e) {
      // If product not found locally, fetch from API
      fetchProductDetails(productId);
      // No setError here as fetchProductDetails will handle its own error state.
    }
  }

  /// Clears the selected product and unsubscribes from its channel
  void clearSelectedProduct() {
    if (_selectedProduct != null) {
      _unsubscribeFromSpecificProductChannels(_selectedProduct!.id);
    }
    _selectedProduct = null;
    setSuccess(); // Use setSuccess to notify listeners
  }

  /// Subscribes to the general products channel for creates
  Future<void> _subscribeToGeneralProductsChannel() async {
    const channelName = 'products';
    try {
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _isGeneralChannelSubscribed = true;
        _pusherService.bindToEvent(channelName, 'product.created', (event) {
          _logger.i(
            'ProductProvider: Received product.created event on general channel.',
          );
          _handleProductCreated(event.data);
        });
        _logger.d(
          'ProductProvider: Successfully subscribed to "$channelName" and bound "product.created" event.',
        );
        setSuccess(); // Indicate success for subscription
      } else {
        _logger.e(
          'ProductProvider: Failed to subscribe to general products channel: $channelName',
        );
        setError(
          'Failed to subscribe to general products channel.',
        ); // Report error
      }
    } catch (e) {
      _logger.e(
        'ProductProvider: Error subscribing to general products channel: $e',
      );
      setError(
        'Error subscribing to general products channel: ${e.toString()}',
      ); // Report error
    }
  }

  /// Subscribes to specific product channels for updates, deletes, and reviews
  Future<void> _subscribeToSpecificProductChannels(String productId) async {
    // Avoid duplicate subscriptions
    if (_subscribedProductChannels.contains(productId)) {
      _logger.d(
        'ProductProvider: Already subscribed to specific channels for product: $productId. Skipping.',
      );
      return;
    }

    final updatedChannelName = 'product.updated.$productId';
    final deletedChannelName = 'product.deleted.$productId';
    final reviewChannelName = 'product.review.created.$productId';

    try {
      // Subscribe to updated channel
      final updatedSuccess = await _pusherService.subscribeToChannel(
        updatedChannelName,
      );
      if (updatedSuccess) {
        _pusherService.bindToEvent(updatedChannelName, 'product.updated', (
          event,
        ) {
          _logger.i(
            'ProductProvider: Received product.updated event for product $productId.',
          );
          _handleProductUpdated(event.data);
        });
      } else {
        setError(
          'Failed to subscribe to product updated channel: $updatedChannelName',
        ); // Report error
      }

      // Subscribe to deleted channel
      final deletedSuccess = await _pusherService.subscribeToChannel(
        deletedChannelName,
      );
      if (deletedSuccess) {
        _pusherService.bindToEvent(deletedChannelName, 'product.deleted', (
          event,
        ) {
          _logger.i(
            'ProductProvider: Received product.deleted event for product $productId.',
          );
          _handleProductDeleted(event.data);
        });
      } else {
        setError(
          'Failed to subscribe to product deleted channel: $deletedChannelName',
        ); // Report error
      }

      // Subscribe to review channel
      final reviewSuccess = await _pusherService.subscribeToChannel(
        reviewChannelName,
      );
      if (reviewSuccess) {
        _pusherService.bindToEvent(reviewChannelName, 'product.review.created', (
          event,
        ) {
          _logger.i(
            'ProductProvider: Received product.review.created event for product $productId.',
          );
          _handleProductReviewCreated(event.data);
        });
      } else {
        setError(
          'Failed to subscribe to product review channel: $reviewChannelName',
        ); // Report error
      }

      _subscribedProductChannels.add(productId);
      _logger.d(
        'ProductProvider: Subscribed to specific product channels for product: $productId.',
      );
      setSuccess(); // Indicate success for subscription
    } catch (e) {
      _logger.e(
        'ProductProvider: Failed to subscribe to specific product channels for $productId: $e',
      );
      setError(
        'Failed to subscribe to specific product channels: ${e.toString()}',
      ); // Report error
    }
  }

  /// Unsubscribes from specific product channels
  Future<void> _unsubscribeFromSpecificProductChannels(String productId) async {
    if (!_subscribedProductChannels.contains(productId)) {
      _logger.d(
        'ProductProvider: Not subscribed to specific channels for product: $productId. Skipping unsubscribe.',
      );
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
      _logger.d(
        'ProductProvider: Unsubscribed from specific product channels for product: $productId.',
      );
      setSuccess(); // Indicate success for unsubscription
    } catch (e) {
      _logger.e(
        'ProductProvider: Failed to unsubscribe from specific product channels for $productId: $e',
      );
      setError(
        'Failed to unsubscribe from specific product channels: ${e.toString()}',
      ); // Report error
    }
  }

  // Enhanced Pusher event handlers with better error handling
  void _handleProductCreated(dynamic data) {
    try {
      Map<String, dynamic> productData;

      // Handle the nested structure from your log: {product: {...}}
      if (data is Map<String, dynamic>) {
        if (data.containsKey('product')) {
          productData = data['product'] as Map<String, dynamic>;
        } else {
          productData = data;
        }
      } else if (data is String) {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        productData =
            parsed.containsKey('product') ? parsed['product'] : parsed;
      } else {
        _logger.w(
          'ProductProvider: Unexpected data type for product.created event: ${data.runtimeType}',
        );
        setError(
          'Unexpected data type for product creation event.',
        ); // Report error
        return;
      }

      final newProduct = Product.fromJson(productData);

      // Only add if product is available and not already in list
      if (newProduct.isAvailable &&
          !_products.any((p) => p.id == newProduct.id)) {
        _products.insert(0, newProduct);

        if (newProduct.isFeatured) {
          _featuredProducts.insert(0, newProduct);
        }
        _logger.i('ProductProvider: Product created: ${newProduct.name}');
        setSuccess(); // Use setSuccess to notify listeners
      } else {
        _logger.d(
          'ProductProvider: Product created event received for existing or unavailable product: ${newProduct.name}',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'ProductProvider: Failed to handle product.created event: $e\n$stackTrace',
      );
      setError(
        'Failed to handle product creation event: ${e.toString()}',
      ); // Report error
    }
  }

  void _handleProductUpdated(dynamic data) {
    try {
      Map<String, dynamic> productData;
      if (data is String) {
        productData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        productData = data;
      } else {
        _logger.w(
          'ProductProvider: Unexpected data type for product.updated event: ${data.runtimeType}',
        );
        setError(
          'Unexpected data type for product update event.',
        ); // Report error
        return;
      }

      final updatedProduct = Product.fromJson(productData);
      final String productId = updatedProduct.id;

      _updateProductInLists(productId, updatedProduct);

      // Update selected product if it's the same one
      if (_selectedProduct?.id == productId) {
        _selectedProduct = updatedProduct;
      }

      // Handle cart item availability changes
      if (_cartItems.containsKey(productId)) {
        if (!updatedProduct.isAvailable) {
          _cartItems.remove(productId);
          _logger.i(
            'ProductProvider: Removed product ${updatedProduct.name} from cart due to unavailability.',
          );
        }
      }
      _logger.i('ProductProvider: Product updated: ${updatedProduct.name}');
      setSuccess(); // Use setSuccess to notify listeners
    } catch (e, stackTrace) {
      _logger.e(
        'ProductProvider: Failed to handle product.updated event: $e\n$stackTrace',
      );
      setError(
        'Failed to handle product update event: ${e.toString()}',
      ); // Report error
    }
  }

  void _handleProductDeleted(dynamic data) {
    try {
      Map<String, dynamic> deletedData;
      if (data is String) {
        deletedData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        deletedData = data;
      } else {
        _logger.w(
          'ProductProvider: Unexpected data type for product.deleted event: ${data.runtimeType}',
        );
        setError(
          'Unexpected data type for product deletion event.',
        ); // Report error
        return;
      }

      final String? deletedProductId = deletedData['product_uuid'] as String?;

      if (deletedProductId != null) {
        _removeProduct(deletedProductId);
        _unsubscribeFromSpecificProductChannels(deletedProductId);
        _logger.i('ProductProvider: Product deleted: $deletedProductId');
        setSuccess(); // Use setSuccess to notify listeners
      } else {
        _logger.w(
          'ProductProvider: No product_uuid found in product.deleted event data.',
        );
        setError(
          'Product ID not found in deletion event data.',
        ); // Report error
      }
    } catch (e, stackTrace) {
      _logger.e(
        'ProductProvider: Failed to handle product.deleted event: $e\n$stackTrace',
      );
      setError(
        'Failed to handle product deletion event: ${e.toString()}',
      ); // Report error
    }
  }

  void _handleProductReviewCreated(dynamic data) {
    try {
      Map<String, dynamic> reviewData;
      if (data is String) {
        reviewData = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map<String, dynamic>) {
        reviewData = data;
      } else {
        _logger.w(
          'ProductProvider: Unexpected data type for product.review.created event: ${data.runtimeType}',
        );
        setError(
          'Unexpected data type for product review creation event.',
        ); // Report error
        return;
      }

      final String? reviewedProductId = reviewData['product_uuid'] as String?;

      if (reviewedProductId == null) {
        _logger.w(
          'ProductProvider: No product_uuid found in product.review.created event data.',
        );
        setError('Product ID not found in review event data.'); // Report error
        return;
      }

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
        }
        _logger.i(
          'ProductProvider: Product review created, updated product data included.',
        );
        setSuccess(); // Use setSuccess to notify listeners
      } else {
        // If product data is not included, refetch the product if it's currently selected
        if (_selectedProduct?.id == reviewedProductId) {
          _logger.i(
            'ProductProvider: Product review created, refetching selected product details.',
          );
          fetchProductDetails(reviewedProductId);
        } else {
          _logger.d(
            'ProductProvider: Product review created for non-selected product. No product data included, skipping refetch.',
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e(
        'ProductProvider: Failed to handle product.review.created event: $e\n$stackTrace',
      );
      setError(
        'Failed to handle product review creation event: ${e.toString()}',
      ); // Report error
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
    resetState(); // Use resetState to clear error and set to idle
    setSuccess(); // Use setSuccess to notify listeners
    _logger.d('ProductProvider: Cleared product data.');
  }

  /// Clears all data including cart and unsubscribes from all channels
  void clearAll() {
    clearProductData();
    _cartItems.clear();

    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
      _isGeneralChannelSubscribed = false;
      _logger.d('ProductProvider: Unsubscribed from general products channel.');
    }

    setSuccess(); // Use setSuccess to notify listeners
    _logger.d('ProductProvider: Cleared all product and cart data.');
  }

  void clearError() {
    resetState(); // Calls resetState from BaseProvider
  }

  @override
  void dispose() {
    _logger.d('ProductProvider: Disposing...');
    // Unsubscribe from general channel
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
      _isGeneralChannelSubscribed = false;
    }

    // Unsubscribe from all specific product channels
    final productIds = List<String>.from(_subscribedProductChannels);
    for (final productId in productIds) {
      _unsubscribeFromSpecificProductChannels(productId);
    }

    super.dispose();
  }
}
