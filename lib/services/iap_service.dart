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
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the IAP service
  Future<bool> initialize() async {
    try {
      _logger.i('Initializing IAP Service...');
      
      // Check if IAP is available
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        _logger.e('IAP not available on this device');
        return false;
      }

      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          _logger.e('IAP purchase stream error: $error');
        },
      );

      _isInitialized = true;
      _logger.i('IAP Service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize IAP Service: $e');
      return false;
    }
  }

  /// Load available products
  Future<bool> loadProducts() async {
    try {
      _logger.i('Loading products...');
      
      if (!_isInitialized) {
        _logger.w('IAP Service not initialized');
        return false;
      }

      // Query product details
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({productId});
      
      if (response.error != null) {
        _logger.e('Error loading products: ${response.error}');
        return false;
      }

      if (response.productDetails.isEmpty) {
        _logger.w('No products found for ID: $productId');
        return false;
      }

      _products = response.productDetails;
      _logger.i('Loaded ${_products.length} products');
      
      for (var product in _products) {
        _logger.i('Product: ${product.id}, Price: ${product.price}, Title: ${product.title}');
      }
      
      return true;
    } catch (e) {
      _logger.e('Failed to load products: $e');
      return false;
    }
  }

  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      _logger.w('Product not found: $productId');
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      _logger.i('Initiating purchase for product: $productId');
      
      if (!_isInitialized) {
        _logger.e('IAP Service not initialized');
        return false;
      }

      final ProductDetails? product = getProduct(productId);
      if (product == null) {
        _logger.e('Product not found: $productId');
        return false;
      }

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      // Start the purchase
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        _logger.e('Failed to initiate purchase');
        return false;
      }

      _logger.i('Purchase initiated successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to purchase product: $e');
      return false;
    }
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _logger.i('Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
      // Emit purchase update to stream
      _purchaseController.add(purchaseDetails);
      
      // Complete the purchase if needed
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
        _logger.i('Purchase completed: ${purchaseDetails.productID}');
      }
    }
  }

  /// Restore purchases (iOS mainly)
  Future<void> restorePurchases() async {
    try {
      _logger.i('Restoring purchases...');
      
      if (!_isInitialized) {
        _logger.e('IAP Service not initialized');
        return;
      }

      await _inAppPurchase.restorePurchases();
      _logger.i('Purchase restoration initiated');
    } catch (e) {
      _logger.e('Failed to restore purchases: $e');
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      _logger.i('Checking for active subscription...');
      
      if (!_isInitialized) {
        await initialize();
      }

      // Get past purchases
      await _inAppPurchase.restorePurchases();
      
      // Note: In a real app, you should verify the subscription status
      // with your backend server using the purchase receipt
      
      return false; // Placeholder - implement based on your backend verification
    } catch (e) {
      _logger.e('Failed to check subscription status: $e');
      return false;
    }
  }

  /// Get purchase receipt for server verification
  String? getPurchaseReceipt(PurchaseDetails purchaseDetails) {
    if (Platform.isIOS) {
      // iOS receipt
      return purchaseDetails.verificationData.serverVerificationData;
    } else {
      // Android purchase token
      return purchaseDetails.verificationData.serverVerificationData;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
    _logger.i('IAP Service disposed');
  }
}

/// Purchase status enum for better handling
enum PurchaseStatus {
  idle,
  loading,
  success,
  failed,
  cancelled,
  restored,
}

/// Purchase result model
class PurchaseResult {
  final PurchaseStatus status;
  final String? message;
  final PurchaseDetails? purchaseDetails;
  final String? error;

  PurchaseResult({
    required this.status,
    this.message,
    this.purchaseDetails,
    this.error,
  });

  bool get isSuccess => status == PurchaseStatus.success;
  bool get isFailed => status == PurchaseStatus.failed;
  bool get isCancelled => status == PurchaseStatus.cancelled;
}