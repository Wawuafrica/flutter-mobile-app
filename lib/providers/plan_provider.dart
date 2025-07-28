import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wawu_mobile/models/subscription_iap.dart';
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
  SubscriptionIap? _subscriptionIap;
  
  // IAP specific properties
  List<ProductDetails> _iapProducts = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  PurchaseDetails? _currentPurchase;
  bool _isProcessingPurchase = false;
  bool _purchaseCompleted = false;
  Timer? _purchaseTimeoutTimer;

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
          debugPrint('Purchase stream error: $error');
          _resetPurchaseState();
          setError('Purchase error: $error');
        },
      );

      setSuccess();
      return true;
    } catch (e) {
      debugPrint('IAP initialization error: $e');
      setError('Failed to initialize payments: $e');
      return false;
    }
  }

  /// Reset purchase state
  void _resetPurchaseState() {
    _isProcessingPurchase = false;
    _purchaseCompleted = false;
    _currentPurchase = null;
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
    notifyListeners();
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
      // Prevent multiple concurrent purchases
      if (_isProcessingPurchase || _purchaseCompleted) {
        debugPrint('Purchase already in progress or completed');
        return;
      }

      debugPrint('Starting purchase process for plan: $planUuid');
      
      setLoading();
      _isProcessingPurchase = true;
      _purchaseCompleted = false;
      notifyListeners();

      // Set timeout for purchase
      _purchaseTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_isProcessingPurchase && !_purchaseCompleted) {
          debugPrint('Purchase timeout reached');
          _resetPurchaseState();
          setError('Purchase timeout. Please try again.');
        }
      });

      // Get the product ID based on platform
      final String productId = _iapService.productId;
      debugPrint('Using product ID: $productId');
      
      // Initiate purchase
      final bool purchaseStarted = await _iapService.purchaseProduct(productId);
      
      if (!purchaseStarted) {
        debugPrint('Failed to start purchase');
        _resetPurchaseState();
        setError('Failed to start purchase process');
        return;
      }

      debugPrint('Purchase initiated successfully, waiting for result...');
      // The purchase update will be handled by _handlePurchaseUpdate
      
    } catch (e) {
      debugPrint('Purchase error: $e');
      _resetPurchaseState();
      setError('Purchase failed: $e');
    }
  }

  /// Handle purchase updates from IAP
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Purchase update received: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
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
      debugPrint('Error processing purchase update: $e');
      _resetPurchaseState();
      setError('Error processing purchase: $e');
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Handling successful purchase...');
      _currentPurchase = purchaseDetails;
      
      // Get purchase receipt for server verification
      final String? receipt = _iapService.getPurchaseReceipt(purchaseDetails);
      
      if (receipt == null) {
        debugPrint('Failed to get purchase receipt');
        _resetPurchaseState();
        setError('Failed to get purchase receipt');
        return;
      }

      debugPrint('Purchase receipt obtained, length: ${receipt.length}');

      // For now, simulate successful subscription creation since backend isn't ready
      // TODO: Uncomment when backend is ready
      // await _verifyPurchaseWithServer(
      //   receipt: receipt,
      //   productId: purchaseDetails.productID,
      //   purchaseId: purchaseDetails.purchaseID ?? '',
      //   platform: Platform.isIOS ? 'ios' : 'android',
      // );

      // Temporary: Create a mock subscription for testing
      _subscriptionIap = SubscriptionIap(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        planId: _selectedPlan?.uuid ?? 'unknown',
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchaseDetails.productID,
      );

      debugPrint('Mock subscription created successfully');
      
      _purchaseCompleted = true;
      _isProcessingPurchase = false;
      _purchaseTimeoutTimer?.cancel();
      
      setSuccess();
      
      // Save onboarding step
      await OnboardingStateService.saveStep('disclaimer');
      debugPrint('Onboarding step saved to disclaimer');

    } catch (e) {
      debugPrint('Failed to process successful purchase: $e');
      _resetPurchaseState();
      setError('Failed to process successful purchase: $e');
    }
  }

  /// Verify purchase with server (commented out until backend is ready)
  Future<void> _verifyPurchaseWithServer({
    required String receipt,
    required String productId,
    required String purchaseId,
    required String platform,
  }) async {
    try {
      debugPrint('Verifying purchase with server...');
      
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
          
          debugPrint('Server verification successful');
          
          // Mark success
          _purchaseCompleted = true;
          _isProcessingPurchase = false;
          _purchaseTimeoutTimer?.cancel();
          setSuccess();
          
          // Save onboarding step
          await OnboardingStateService.saveStep('disclaimer');
        } else {
          debugPrint('Server verification failed - no data');
          _resetPurchaseState();
          setError(response['message'] ?? 'Failed to create subscription');
        }
      } else {
        debugPrint('Server verification failed - bad response');
        _resetPurchaseState();
        setError(response['message'] ?? 'Purchase verification failed');
      }
    } catch (e) {
      debugPrint('Server verification exception: $e');
      _resetPurchaseState();
      setError('Server verification failed: $e');
    }
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    final error = purchaseDetails.error;
    String errorMessage = 'Purchase failed';
    
    if (error != null) {
      errorMessage = error.message;
      debugPrint('Purchase error: ${error.code} - ${error.message}');
    }
    
    _resetPurchaseState();
    setError(errorMessage);
  }

  /// Handle purchase canceled
  void _handlePurchaseCanceled() {
    debugPrint('Purchase was canceled by user');
    _resetPurchaseState();
    setError('Purchase was canceled');
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('Handling restored purchase...');
    // Handle restored purchases (mainly for iOS)
    await _handleSuccessfulPurchase(purchaseDetails);
  }

  /// Handle pending purchase
  void _handlePendingPurchase() {
    debugPrint('Purchase is pending (e.g., waiting for parental approval)');
    // Purchase is pending (e.g., waiting for parental approval)
    // Keep the current loading state but don't mark as complete
  }

  /// Restore purchases (iOS)
  Future<void> restorePurchases() async {
    try {
      debugPrint('Restoring purchases...');
      setLoading();
      await _iapService.restorePurchases();
      // Results will come through the purchase stream
    } catch (e) {
      debugPrint('Failed to restore purchases: $e');
      setError('Failed to restore purchases: $e');
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    try {
      return await _iapService.hasActiveSubscription();
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
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
    _resetPurchaseState();
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
    _resetPurchaseState();
    resetState();
  }

  @override
  void dispose() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseSubscription?.cancel();
    _iapService.dispose();
    super.dispose();
  }
}