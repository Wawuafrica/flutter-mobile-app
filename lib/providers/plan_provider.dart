import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import '../services/iap_service.dart' hide PurchaseStatus;
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';

class PlanProvider extends BaseProvider {
  final ApiService _apiService;
  final IAPService _iapService = IAPService();

  List<Plan> _plans = [];
  Plan? _selectedPlan;
  PaymentLink? _paymentLink; // Keep for backward compatibility
  Subscription? _subscription;
  
  // IAP specific properties
  List<ProductDetails> _iapProducts = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  PurchaseDetails? _currentPurchase;
  bool _isProcessingPurchase = false;

  // Getters
  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  PaymentLink? get paymentLink => _paymentLink;
  Subscription? get subscription => _subscription;
  List<ProductDetails> get iapProducts => _iapProducts;
  bool get isProcessingPurchase => _isProcessingPurchase;

  PlanProvider({required ApiService apiService})
      : _apiService = apiService,
        super();

  /// Initialize IAP service
  Future<bool> initializeIAP() async {
    try {
      setLoading();
      
      // Initialize IAP service
      final bool iapInitialized = await _iapService.initialize();
      if (!iapInitialized) {
        setError('In-app purchases not available on this device');
        return false;
      }

      // Load products
      final bool productsLoaded = await _iapService.loadProducts();
      if (!productsLoaded) {
        setError('Failed to load subscription plans');
        return false;
      }

      _iapProducts = _iapService.products;

      // Listen to purchase updates
      _purchaseSubscription = _iapService.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (error) {
          setError('Purchase error: $error');
        },
      );

      setSuccess();
      return true;
    } catch (e) {
      setError('Failed to initialize payments: $e');
      return false;
    }
  }

  /// Fetch all plans (keep existing functionality)
  Future<void> fetchAllPlans() async {
    setLoading();
    try {
      final response = await _apiService.get('/plans');
      if (response != null && response['data'] is List) {
        _plans = (response['data'] as List)
            .map((planJson) => Plan.fromJson(planJson as Map<String, dynamic>))
            .toList();
        setSuccess();
      } else {
        _plans = [];
        setError(response['message'] ?? 'Failed to fetch plans: Invalid response structure');
      }
    } catch (e) {
      _plans = [];
      setError(e.toString());
    }
  }

  /// Purchase subscription using IAP
  Future<void> purchaseSubscription({
    required String planUuid,
    required String userId,
  }) async {
    try {
      setLoading();
      _isProcessingPurchase = true;

      // Get the product ID based on platform
      final String productId = _iapService.productId;
      
      // Initiate purchase
      final bool purchaseStarted = await _iapService.purchaseProduct(productId);
      
      if (!purchaseStarted) {
        setError('Failed to start purchase process');
        _isProcessingPurchase = false;
        return;
      }

      // The purchase update will be handled by _handlePurchaseUpdate
      // We don't set success here as we wait for the purchase completion
      
    } catch (e) {
      _isProcessingPurchase = false;
      setError('Purchase failed: $e');
    }
  }

  /// Handle purchase updates from IAP
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      switch (purchaseDetails.status) {
        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handlePurchaseCanceled();
          break;
        case PurchaseStatus.restored:
          await _handleRestoredPurchase(purchaseDetails);
          break;
        case PurchaseStatus.pending:
          _handlePendingPurchase();
          break;
      }
    } catch (e) {
      setError('Error processing purchase: $e');
      _isProcessingPurchase = false;
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      _currentPurchase = purchaseDetails;
      
      // Get purchase receipt for server verification
      final String? receipt = _iapService.getPurchaseReceipt(purchaseDetails);
      
      if (receipt == null) {
        setError('Failed to get purchase receipt');
        _isProcessingPurchase = false;
        return;
      }

      // Verify purchase with your backend
      // await _verifyPurchaseWithServer(
      //   receipt: receipt,
      //   productId: purchaseDetails.productID,
      //   purchaseId: purchaseDetails.purchaseID ?? '',
      //   platform: Platform.isIOS ? 'ios' : 'android',
      // );

    } catch (e) {
      setError('Failed to process successful purchase: $e');
      _isProcessingPurchase = false;
    }
  }

  /// Verify purchase with server
  Future<void> _verifyPurchaseWithServer({
    required String receipt,
    required String productId,
    required String purchaseId,
    required String platform,
  }) async {
    try {
      // Call your backend to verify the purchase
      final response = await _apiService.post('/subscribe/verify-iap', data: {
        'receipt': receipt,
        'product_id': productId,
        'purchase_id': purchaseId,
        'platform': platform,
        'plan_uuid': _selectedPlan?.uuid,
        // Add any other required fields
      });

      if (response != null && response['statusCode'] == 200) {
        // Parse subscription data
        if (response['data'] != null) {
          final dataMap = response['data'] as Map<String, dynamic>;
          _subscription = Subscription.fromJson(dataMap);
          
          // Mark success
          setSuccess();
          _isProcessingPurchase = false;
          
          // Save onboarding step
          await OnboardingStateService.saveStep('disclaimer');
        } else {
          setError(response['message'] ?? 'Failed to create subscription');
          _isProcessingPurchase = false;
        }
      } else {
        setError(response['message'] ?? 'Purchase verification failed');
        _isProcessingPurchase = false;
      }
    } catch (e) {
      setError('Server verification failed: $e');
      _isProcessingPurchase = false;
    }
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    final error = purchaseDetails.error;
    String errorMessage = 'Purchase failed';
    
    if (error != null) {
      errorMessage = error.message;
    }
    
    setError(errorMessage);
    _isProcessingPurchase = false;
  }

  /// Handle purchase canceled
  void _handlePurchaseCanceled() {
    setError('Purchase was canceled');
    _isProcessingPurchase = false;
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    // Handle restored purchases (mainly for iOS)
    await _handleSuccessfulPurchase(purchaseDetails);
  }

  /// Handle pending purchase
  void _handlePendingPurchase() {
    // Purchase is pending (e.g., waiting for parental approval)
    setSuccess(); // Keep loading state
  }

  /// Restore purchases (iOS)
  Future<void> restorePurchases() async {
    try {
      setLoading();
      await _iapService.restorePurchases();
      // Results will come through the purchase stream
    } catch (e) {
      setError('Failed to restore purchases: $e');
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      return await _iapService.hasActiveSubscription();
    } catch (e) {
      return false;
    }
  }

  // Remove Paystack methods - IAP only implementation
  
  /// Generate payment link (REMOVED - IAP only)
  Future<void> generatePaymentLink({
    required String planUuid,
    required String userId,
  }) async {
    // This method is no longer needed for IAP-only implementation
    setError('Please use in-app purchase for subscriptions');
  }

  /// Handle payment callback (REMOVED - IAP only)
  Future<void> handlePaymentCallback(String callbackUrl) async {
    // This method is no longer needed for IAP-only implementation
    setError('Please use in-app purchase for subscriptions');
  }

  /// Fetch user subscription details
  Future<void> fetchUserSubscriptionDetails(String userId, int role) async {
    setLoading();
    try {
      final response = await _apiService.get('/user/subscription/details/$userId');

      if (response != null &&
          response['data'] != null &&
          response['data']['subscription'] != null) {
        _subscription = Subscription.fromJson(
          response['data']['subscription'] as Map<String, dynamic>,
        );
        setSuccess();
      } else {
        _subscription = null;
        setError(response['message'] ?? 'Failed to fetch subscription details: Invalid response structure or no subscription data');
      }
    } catch (e) {
      _subscription = null;
      setError(e.toString());
    }
  }

  /// Select plan
  void selectPlan(Plan plan) {
    _selectedPlan = plan;
    setSuccess();
  }

  /// Clear payment link
  void clearPaymentLink() {
    _paymentLink = null;
    setSuccess();
  }

  /// Clear subscription
  void clearSubscription() {
    _subscription = null;
    setSuccess();
  }

  /// Clear error
  void clearError() {
    resetState();
  }

  /// Reset all data
  void reset() {
    _plans = [];
    _selectedPlan = null;
    _paymentLink = null;
    _subscription = null;
    _iapProducts = [];
    _currentPurchase = null;
    _isProcessingPurchase = false;
    resetState();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _iapService.dispose();
    super.dispose();
  }
}