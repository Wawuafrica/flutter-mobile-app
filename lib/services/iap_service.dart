import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Logger _logger = Logger();

  // Stream controllers for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<PurchaseDetails> _purchaseController = StreamController<PurchaseDetails>.broadcast();

  // Product IDs - Update these with your actual product IDs
  static const String _iOSProductId = 'com.wawuafrica.standard_yearly';
  static const String _androidProductId = 'standard_yearly'; // Update with your Google Play product ID

  // Getters for product IDs
  String get productId => Platform.isIOS ? _iOSProductId : _androidProductId;

  // Stream for listening to purchase updates
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  // Available products
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  // Active purchases/subscriptions -- RESTORED THIS LIST
  List<PurchaseDetails> _activePurchases = [];
  List<PurchaseDetails> get activePurchases => _activePurchases;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the IAP service
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing IAP Service...');
      debugPrint('[IAP] Starting initialization');

      // Check if IAP is available
      final bool isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('[IAP] IAP available: $isAvailable');

      if (!isAvailable) {
        _logger.e('IAP not available on this device');
        debugPrint('[IAP] IAP not available on this device');
        return false;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          _logger.e('IAP purchase stream error: $error');
          debugPrint('[IAP] Purchase stream error: $error');
        },
      );

      // Check for existing purchases/subscriptions right after setting up the listener -- RESTORED THIS CALL
      await _checkExistingPurchases();

      _isInitialized = true;
      _logger.i('IAP Service initialized successfully');
      debugPrint('[IAP] Service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize IAP Service: $e');
      debugPrint('[IAP] Failed to initialize: $e');
      return false;
    }
  }

  /// Check for existing purchases (important for subscription tracking) -- RESTORED THIS METHOD
  /// This will trigger _handlePurchaseUpdates for any existing purchases.
  Future<void> _checkExistingPurchases() async {
    try {
      debugPrint('[IAP] Checking for existing purchases...');
      // Restore purchases to get current subscription status
      await _inAppPurchase.restorePurchases();
      // The restored purchases will come through the purchase stream
      // and be handled by _handlePurchaseUpdates, which updates _activePurchases.
    } catch (e) {
      debugPrint('[IAP] Error checking existing purchases: $e');
    }
  }

  /// Load available products
  Future<bool> loadProducts() async {
    try {
      _logger.i('Loading products...');
      debugPrint('[IAP] Loading products for ID: $productId');

      if (!_isInitialized) {
        _logger.w('IAP Service not initialized');
        debugPrint('[IAP] Service not initialized');
        return false;
      }

      // Query product details
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});

      debugPrint('[IAP] Product query response - Error: ${response.error}');
      debugPrint('[IAP] Product query response - Products found: ${response.productDetails.length}');
      debugPrint('[IAP] Product query response - Not found IDs: ${response.notFoundIDs}');

      if (response.error != null) {
        _logger.e('Error loading products: ${response.error}');
        debugPrint('[IAP] Error loading products: ${response.error}');
        return false;
      }

      if (response.productDetails.isEmpty) {
        _logger.w('No products found for ID: $productId');
        debugPrint('[IAP] No products found for ID: $productId');
        debugPrint('[IAP] Not found IDs: ${response.notFoundIDs}');
        return false;
      }

      _products = response.productDetails;
      _logger.i('Loaded ${_products.length} products');
      debugPrint('[IAP] Loaded ${_products.length} products');

      for (var product in _products) {
        _logger.i('Product: ${product.id}, Price: ${product.price}, Title: ${product.title}');
        debugPrint('[IAP] Product: ${product.id}, Price: ${product.price}, Title: ${product.title}');
      }

      return true;
    } catch (e) {
      _logger.e('Failed to load products: $e');
      debugPrint('[IAP] Failed to load products: $e');
      return false;
    }
  }

  /// Get product details by ID - FIXED THE TYPE ISSUE
  ProductDetails? getProduct(String productId) {
    try {
      // Use where().first instead of firstWhere to avoid the orElse type issue
      final matchingProducts = _products.where((product) => product.id == productId);
      
      if (matchingProducts.isNotEmpty) {
        return matchingProducts.first;
      } else {
        _logger.w('Product not found: $productId');
        debugPrint('[IAP] Product not found: $productId');
        return null;
      }
    } catch (e) {
      _logger.w('Error getting product: $productId - $e');
      debugPrint('[IAP] Error getting product: $productId - $e');
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      _logger.i('Initiating purchase for product: $productId');
      debugPrint('[IAP] Initiating purchase for product: $productId');

      if (!_isInitialized) {
        _logger.e('IAP Service not initialized');
        debugPrint('[IAP] Service not initialized');
        return false;
      }

      // Check if user already has an active subscription for this product -- ADDED BACK THIS CHECK
      if (hasActiveSubscription()) {
        _logger.w('User already has active subscription for: $productId. Simulating restored purchase.');
        debugPrint('[IAP] User already has active subscription for: $productId. Simulating restored purchase.');

        // Find the existing purchase and emit it as a "restored" purchase
        final existingPurchases = _activePurchases.where((purchase) => purchase.productID == productId);
        
        if (existingPurchases.isNotEmpty) {
          final existingPurchase = existingPurchases.first;
          _purchaseController.add(existingPurchase);
          return true;
        } else if (_activePurchases.isNotEmpty) {
          // Fallback to any active purchase
          final existingPurchase = _activePurchases.first;
          _purchaseController.add(existingPurchase);
          return true;
        } else {
          _logger.e('No active purchases found despite hasActiveSubscription being true');
          debugPrint('[IAP] No active purchases found despite hasActiveSubscription being true');
          return false;
        }
      }

      final ProductDetails? product = getProduct(productId);
      if (product == null) {
        _logger.e('Product not found: $productId');
        debugPrint('[IAP] Product not found: $productId');
        return false;
      }

      debugPrint('[IAP] Product found: ${product.title} - ${product.price}');

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

      debugPrint('[IAP] Created purchase param, starting purchase...');

      // Start the purchase
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      debugPrint('[IAP] Purchase initiation result: $success');

      if (!success) {
        _logger.e('Failed to initiate purchase');
        debugPrint('[IAP] Failed to initiate purchase');
        return false;
      }

      _logger.i('Purchase initiated successfully');
      debugPrint('[IAP] Purchase initiated successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to purchase product: $e');
      debugPrint('[IAP] Failed to purchase product: $e');
      return false;
    }
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('[IAP] Received ${purchaseDetailsList.length} purchase updates');

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _logger.i('Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      debugPrint('[IAP] Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      debugPrint('[IAP] Purchase ID: ${purchaseDetails.purchaseID}');
      debugPrint('[IAP] Transaction date: ${purchaseDetails.transactionDate}');
      debugPrint('[IAP] Pending complete: ${purchaseDetails.pendingCompletePurchase}');

      if (purchaseDetails.error != null) {
        debugPrint('[IAP] Purchase error: ${purchaseDetails.error!.code} - ${purchaseDetails.error!.message}');
      }

      // Update our active purchases list -- RESTORED THIS CALL
      _updateActivePurchases(purchaseDetails);

      // Emit purchase update to stream
      _purchaseController.add(purchaseDetails);

      // Complete the purchase if needed
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('[IAP] Completing purchase...');
        _inAppPurchase.completePurchase(purchaseDetails);
        _logger.i('Purchase completed: ${purchaseDetails.productID}');
        debugPrint('[IAP] Purchase completed: ${purchaseDetails.productID}');
      }
    }
  }

  /// Update the list of active purchases based on the latest purchase detail. -- RESTORED THIS METHOD
  /// This is crucial for keeping track of active subscriptions.
  void _updateActivePurchases(PurchaseDetails purchaseDetails) {
    // Remove if already exists to add the most recent status
    _activePurchases.removeWhere((p) => p.productID == purchaseDetails.productID);

    // Only add if it's an active (purchased/restored) subscription.
    // In-app-purchase package marks restored purchases as PurchaseStatus.purchased
    // or PurchaseStatus.restored depending on platform nuances.
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      _activePurchases.add(purchaseDetails);
      debugPrint('[IAP] Added/Updated active purchase: ${purchaseDetails.productID}');
    } else {
      debugPrint('[IAP] Not adding to active purchases (status: ${purchaseDetails.status})');
    }
    // You might want to remove expired/canceled subscriptions here too
    // based on logic for your specific subscription type if the platform doesn't handle it.
  }

  /// Restore purchases (iOS mainly)
  Future<void> restorePurchases() async {
    try {
      _logger.i('Restoring purchases...');
      debugPrint('[IAP] Restoring purchases...');

      if (!_isInitialized) {
        _logger.e('IAP Service not initialized');
        debugPrint('[IAP] Service not initialized for restore');
        return;
      }

      await _inAppPurchase.restorePurchases();
      // Restored purchases will flow through _handlePurchaseUpdates
      _logger.i('Purchase restoration initiated');
      debugPrint('[IAP] Purchase restoration initiated');
    } catch (e) {
      _logger.e('Failed to restore purchases: $e');
      debugPrint('[IAP] Failed to restore purchases: $e');
    }
  }

  /// Check if user has active subscription for the specific product ID. -- FIXED THIS METHOD
  /// This method now relies on the `_activePurchases` list.
  bool hasActiveSubscription() {
    // Check if any active purchase matches our product ID
    final bool isActive = _activePurchases.any((purchase) =>
        purchase.productID == productId &&
        (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored));
    debugPrint('[IAP] Current active subscription status for $productId: $isActive');
    return isActive;
  }

  /// Get the active purchase details for the current product ID. -- RESTORED AND FIXED THIS METHOD
  PurchaseDetails? getActivePurchase() {
    try {
      final matchingPurchases = _activePurchases.where((purchase) => 
        purchase.productID == productId &&
        (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored));
      
      if (matchingPurchases.isNotEmpty) {
        return matchingPurchases.first;
      } else {
        debugPrint('[IAP] No active purchase found for $productId');
        return null;
      }
    } catch (e) {
      debugPrint('[IAP] Error getting active purchase for $productId: $e');
      return null;
    }
  }

  /// Get purchase receipt for server verification
  String? getPurchaseReceipt(PurchaseDetails purchaseDetails) {
    final receipt = purchaseDetails.verificationData.serverVerificationData;
    debugPrint('[IAP] Getting purchase receipt, length: ${receipt.length}');

    if (Platform.isIOS) {
      debugPrint('[IAP] iOS receipt obtained');
      // iOS receipt
      return receipt;
    } else {
      debugPrint('[IAP] Android purchase token obtained');
      // Android purchase token
      return receipt;
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('[IAP] Disposing IAP Service...');
    _subscription?.cancel();
    _purchaseController.close();
    _logger.i('IAP Service disposed');
    debugPrint('[IAP] IAP Service disposed');
  }
}