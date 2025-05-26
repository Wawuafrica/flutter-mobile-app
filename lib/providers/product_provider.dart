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
/// - Real-time product updates via Pusher based on new event structure
class ProductProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  Product? _selectedProduct;
  Map<String, int> _cartItems = {}; // Map of product ID to quantity
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  bool _isGeneralChannelSubscribed = false;
  String? _currentSpecificProductChannel;

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

    try {
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

      // Subscribe to general products channel if not already subscribed
      if (!_isGeneralChannelSubscribed) {
        await _subscribeToGeneralProductsChannel();
      }

      return _products;
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  /// Fetches featured products
  Future<List<Product>> fetchFeaturedProducts() async {
    try {
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
    } catch (e) {
      print('Failed to fetch featured products: $e');
      return [];
    }
  }

  /// Fetches details of a specific product and subscribes to its channel
  Future<Product?> fetchProductDetails(String productId) async {
    try {
       // Unsubscribe from previous specific product channels if any
      if (_currentSpecificProductChannel != null) {
        await _pusherService.unsubscribeFromChannel(_currentSpecificProductChannel!);
        _currentSpecificProductChannel = null;
      }

      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/products/$productId',
      );

      if (response.isEmpty) {
         print('Failed to fetch product details: Empty response');
         return null;
      }

      final product = Product.fromJson(response);

      _updateProductInLists(productId, product);
      _selectedProduct = product;

       // Subscribe to the specific product channels
      await _subscribeToSpecificProductChannels(productId);

      notifyListeners();
      return product;
    } catch (e) {
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
    // This might happen if a draft product is published.
     if (!foundInProducts && updatedProduct.isAvailable) {
       _products.insert(0, updatedProduct);
     }

    bool foundInFeatured = false;
    for (int i = 0; i < _featuredProducts.length; i++) {
      if (_featuredProducts[i].id == productId) {
        if (updatedProduct.isFeatured) {
          _featuredProducts[i] = updatedProduct;
        } else {
          _featuredProducts.removeAt(i);
        }
        foundInFeatured = true;
        break;
      }
    }

     // Add to featured if it's now featured but wasn't before
    if (!foundInFeatured && updatedProduct.isFeatured) {
      _featuredProducts.insert(0, updatedProduct); // Use insert(0) for newest first
    }

    // Sort lists after update/addition (optional, depending on desired order)
    // _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // _featuredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
      // Unsubscribe from previous specific product channels if any
      if (_currentSpecificProductChannel != null) {
        _pusherService.unsubscribeFromChannel(_currentSpecificProductChannel!);
        _currentSpecificProductChannel = null;
      }

      _selectedProduct = _products.firstWhere(
        (product) => product.id == productId,
        orElse:
            () => _featuredProducts.firstWhere(
              (product) => product.id == productId,
              // orElse: () => null, // Return null if not found locally
            ),
      );

       if (_selectedProduct != null) {
         // Subscribe to the specific product channels
        _subscribeToSpecificProductChannels(productId);
         notifyListeners();
       } else {
          print('Product not found locally: $productId. Consider fetching from API.');
          // Optionally fetch from API if not found locally
          // fetchProductDetails(productId); // This would trigger subscription upon fetching
       }

    } catch (e) {
      print('Failed to select product or subscribe to channel: $e');
       // If firstWhere throws, _selectedProduct remains null and channel is not subscribed
    }
  }

  /// Clears the selected product and unsubscribes from its channel
  void clearSelectedProduct() {
    if (_currentSpecificProductChannel != null) {
      _pusherService.unsubscribeFromChannel(_currentSpecificProductChannel!);
      _currentSpecificProductChannel = null;
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

    // Check if product is available and in stock
    if (!product.isAvailable || !product.isInStock()) {
      print('Product is not available or out of stock');
      return;
    }

    // Check if adding this quantity would exceed stock
    final currentQuantity = _cartItems[productId] ?? 0;
    final newQuantity = currentQuantity + quantity;

    if (newQuantity > product.stockQuantity) {
      print('Cannot add more than available stock');
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
      print('Cannot add more than available stock');
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
      print('Cannot submit an empty order');
      return null;
    }

    try {
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
    } catch (e) {
      print('Failed to submit order: $e');
      return null;
    }
  }

   /// Subscribes to the general products channel for creates
  Future<void> _subscribeToGeneralProductsChannel() async {
    const channelName = 'products';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel == null) {
        print('Failed to subscribe to general products channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      // Bind to product created event
      _pusherService.bindToEvent(channelName, 'product.created', _handleProductCreated);

    } catch (e) {
      print('Failed to subscribe to general products channel: $e');
    }
  }

   /// Subscribes to specific product channels for updates, deletes, and reviews
   Future<void> _subscribeToSpecificProductChannels(String productId) async {
    final updatedChannelName = 'product.updated.\$productId';
    final deletedChannelName = 'product.deleted.\$productId';
    final reviewChannelName = 'product.review.created.\$productId';

    try {
      // Store one of the channel names to manage unsubscription
       _currentSpecificProductChannel = updatedChannelName;

       // Subscribe to updated channel
      final updatedChannel = await _pusherService.subscribeToChannel(updatedChannelName);
       if (updatedChannel != null) {
           _pusherService.bindToEvent(updatedChannelName, 'product.updated', _handleProductUpdated);
       }

       // Subscribe to deleted channel
       final deletedChannel = await _pusherService.subscribeToChannel(deletedChannelName);
       if (deletedChannel != null) {
           _pusherService.bindToEvent(deletedChannelName, 'product.deleted', _handleProductDeleted);
       }

       // Subscribe to review channel
        final reviewChannel = await _pusherService.subscribeToChannel(reviewChannelName);
        if (reviewChannel != null) {
           _pusherService.bindToEvent(reviewChannelName, 'product.review.created', _handleProductReviewCreated);
        }

    } catch (e) {
      print('Failed to subscribe to specific product channels for \$productId: \$e');
       _currentSpecificProductChannel = null; // Clear channel on failure
    }
   }

   // Handlers for Pusher events

  void _handleProductCreated(dynamic data) {
    try {
      if (data is! String) {
        print('Invalid product.created event data');
        return;
      }
      final productData = jsonDecode(data) as Map<String, dynamic>;
      final newProduct = Product.fromJson(productData);

      // Add to available products if it's available
      if (newProduct.isAvailable) {
        _products.insert(0, newProduct);
        // Add to featured if it's also featured
        if (newProduct.isFeatured) {
           _featuredProducts.insert(0, newProduct);
        }
        // No need to sort here, assuming new products come in order or will be sorted on fetch
        notifyListeners();
      }
    } catch (e) {
      print('Failed to handle product.created event: $e');
    }
  }

  void _handleProductUpdated(dynamic data) {
    try {
       if (data is! String) {
          print('Invalid product.updated event data');
          return;
       }
      final productData = jsonDecode(data) as Map<String, dynamic>;
      final updatedProduct = Product.fromJson(productData);
      final String productId = updatedProduct.id;

      _updateProductInLists(productId, updatedProduct);

      // Update selected product if it's the one being updated
      if (_selectedProduct != null && _selectedProduct!.id == productId) {
         _selectedProduct = updatedProduct;
      }

      // Check if product in cart is affected
      if (_cartItems.containsKey(productId)) {
        if (!updatedProduct.isAvailable || !updatedProduct.isInStock()) {
          _cartItems.remove(productId);
          print(
            'Product "${updatedProduct.name}" has been removed from your cart because it is no longer available.',
          );
        } else if (_cartItems[productId]! > updatedProduct.stockQuantity) {
          // Adjust quantity if current quantity exceeds new stock
          _cartItems[productId] = updatedProduct.stockQuantity;
          print(
            'The quantity of "${updatedProduct.name}" in your cart has been adjusted due to stock changes.',
          );
        }
      }

      notifyListeners();

    } catch (e) {
      print('Failed to handle product.updated event: $e');
    }
  }

  void _handleProductDeleted(dynamic data) {
    try {
       if (data is! String) {
          print('Invalid product.deleted event data');
          return;
       }
      final deletedProductData = jsonDecode(data) as Map<String, dynamic>;
      final String? deletedProductId = deletedProductData['product_uuid'];

      if (deletedProductId != null) {
        _removeProduct(deletedProductId);
      } else {
         print('product.deleted event data missing product_uuid');
      }
    } catch (e) {
      print('Failed to handle product.deleted event: $e');
    }
  }

   void _handleProductReviewCreated(dynamic data) {
     try {
       if (data is! String) {
         print('Invalid product.review.created event data');
         return;
       }
       final reviewData = jsonDecode(data) as Map<String, dynamic>;
       final String? reviewedProductId = reviewData['product_uuid'];

       if (reviewedProductId != null && _selectedProduct?.id == reviewedProductId) {
          // Assuming the event payload contains updated review info or the full product
          // If it contains the full updated product:
           if (reviewData.containsKey('product') && reviewData['product'] is Map<String, dynamic>) {
             final updatedProduct = Product.fromJson(reviewData['product']);
             _updateProductInLists(reviewedProductId, updatedProduct);
              if (_selectedProduct?.id == reviewedProductId) {
                 _selectedProduct = updatedProduct;
                 notifyListeners();
              }
           } else {
             print('product.review.created event data missing product object. Cannot update selected product reviews.');
              // If the event only contains review data, you would need to decide how to update the selected product's reviews/rating.
              // This likely requires a method in the Product model to add a review or update the average rating.
              // For now, we'll just print a message if the full product is not provided.
           }
       } else if (reviewedProductId == null) {
          print('product.review.created event data missing product_uuid');
       }
     } catch (e) {
       print('Failed to handle product.review.created event: $e');
     }
   }

  /// Clears all product data except cart and unsubscribes from specific channel
  void clearProductData() {
    _products = [];
    _featuredProducts = [];
    clearSelectedProduct(); // Also unsubscribes from specific channels
    _hasMoreProducts = true;
    _currentPage = 1;
    resetState();
  }

  /// Clears all data including cart and unsubscribes from all channels
  void clearAll() {
    clearProductData(); // This will also clear selected product and unsubscribe from specific channels
    _cartItems.clear();
     if (_isGeneralChannelSubscribed) {
       _pusherService.unsubscribeFromChannel('products');
       _isGeneralChannelSubscribed = false;
     }
     // Specific channel is unsubscribed in clearSelectedProduct
  }

  @override
  void dispose() {
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('products');
    }
     if (_currentSpecificProductChannel != null) {
        // Extract productId from the channel name and unsubscribe from all associated channels
        final productId = _currentSpecificProductChannel!.split('.')[1]; // Assuming format is product.updated.{productId}
        final updatedChannelName = 'product.updated.\$productId';
        final deletedChannelName = 'product.deleted.\$productId';
        final reviewChannelName = 'product.review.created.\$productId';

        _pusherService.unsubscribeFromChannel(updatedChannelName);
        _pusherService.unsubscribeFromChannel(deletedChannelName);
        _pusherService.unsubscribeFromChannel(reviewChannelName);

       _currentSpecificProductChannel = null; // Clear after unsubscribing
     }
    super.dispose();
  }
}
