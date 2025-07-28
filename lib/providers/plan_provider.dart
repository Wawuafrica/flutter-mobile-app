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
  Subscription? _subscription; // Keep for server-based subscriptions if needed
  SubscriptionIap? _subscriptionIap; // Primary subscription object
  
  // IAP specific properties
  List<ProductDetails> _iapProducts = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  PurchaseDetails? _currentPurchase;
  bool _isProcessingPurchase = false;
  bool _purchaseCompleted = false;
  Timer? _purchaseTimeoutTimer;
  bool _hasCheckedExistingSubscription = false;

  // Getters - Updated to use _subscriptionIap
  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  PaymentLink? get paymentLink => _paymentLink;
  SubscriptionIap? get subscriptionIap => _subscriptionIap;
  Subscription? get subscription => _subscription; // Keep for backward compatibility
  List<ProductDetails> get iapProducts => _iapProducts;
  bool get isProcessingPurchase => _isProcessingPurchase;
  bool get hasActiveSubscription => _subscriptionIap != null && _subscriptionIap!.isActive;

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

      // Check for existing subscriptions
      await _checkForExistingSubscription();

      setSuccess();
      return true;
    } catch (e) {
      debugPrint('IAP initialization error: $e');
      setError('Failed to initialize payments: $e');
      return false;
    }
  }

  /// Check for existing subscriptions on initialization
  Future<void> _checkForExistingSubscription() async {
    try {
      if (_hasCheckedExistingSubscription) return;
      
      debugPrint('Checking for existing subscriptions...');
      
      // Check if user has active subscription
      final bool hasActive = await _iapService.hasActiveSubscription();
      
      if (hasActive) {
        debugPrint('Found existing active subscription');
        
        // Get the active purchase details
        final PurchaseDetails? activePurchase = _iapService.getActivePurchase();
        
        if (activePurchase != null) {
          // Create SubscriptionIap from existing purchase
          _subscriptionIap = SubscriptionIap(
            id: 'restored_${activePurchase.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
            planId: _selectedPlan?.uuid ?? 'restored_plan',
            status: 'active',
            startDate: activePurchase.transactionDate != null 
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(activePurchase.transactionDate!))
                : DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 365)), // Default to 1 year
            platform: Platform.isIOS ? 'ios' : 'android',
            productId: activePurchase.productID,
          );
          
          debugPrint('Restored existing subscription: ${_subscriptionIap!.id}');
          notifyListeners();
        }
      }
      
      _hasCheckedExistingSubscription = true;
    } catch (e) {
      debugPrint('Error checking existing subscription: $e');
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

      // Check if user already has active subscription
      if (hasActiveSubscription) {
        debugPrint('User already has active subscription');
        setError('You already have an active subscription. Please check your subscription status.');
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

      // For now, create SubscriptionIap since backend isn't ready
      // TODO: Uncomment when backend is ready for server verification
      // await _verifyPurchaseWithServer(
      //   receipt: receipt,
      //   productId: purchaseDetails.productID,
      //   purchaseId: purchaseDetails.purchaseID ?? '',
      //   platform: Platform.isIOS ? 'ios' : 'android',
      // );

      // Create SubscriptionIap from purchase
      _subscriptionIap = SubscriptionIap(
        id: 'iap_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
        planId: _selectedPlan?.uuid ?? 'unknown',
        status: 'active',
        startDate: purchaseDetails.transactionDate != null 
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(purchaseDetails.transactionDate!))
            : DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)), // Default to 1 year, should come from plan
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchaseDetails.productID,
      );

      debugPrint('SubscriptionIap created successfully: ${_subscriptionIap!.id}');
      
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

  /// Verify purchase with server (for future use when backend is ready)
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
      });

      if (response != null && response['statusCode'] == 200) {
        // Parse SubscriptionIap data from server
        if (response['data'] != null) {
          final dataMap = response['data'] as Map<String, dynamic>;
          _subscriptionIap = SubscriptionIap.fromJson(dataMap);
          
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
    
    // Create SubscriptionIap from restored purchase
    _subscriptionIap = SubscriptionIap(
      id: 'restored_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
      planId: _selectedPlan?.uuid ?? 'restored_plan',
      status: 'active',
      startDate: purchaseDetails.transactionDate != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(purchaseDetails.transactionDate!))
          : DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      platform: Platform.isIOS ? 'ios' : 'android',
      productId: purchaseDetails.productID,
    );
    
    debugPrint('Restored subscription: ${_subscriptionIap!.id}');
    setSuccess();
  }

  /// Handle pending purchase
  void _handlePendingPurchase() {
    debugPrint('Purchase is pending (e.g., waiting for parental approval)');
    // Purchase is pending - keep loading state
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

  /// Check if user has active subscription (enhanced)
  Future<bool> checkActiveSubscription() async {
    try {
      debugPrint('Checking for active subscription...');
      
      // First check local SubscriptionIap
      if (_subscriptionIap != null && _subscriptionIap!.isActive) {
        debugPrint('Found active local SubscriptionIap');
        return true;
      }
      
      // Check with IAP service
      final bool hasIAPActive = await _iapService.hasActiveSubscription();
      
      if (hasIAPActive) {
        // Get the active purchase and create SubscriptionIap
        final PurchaseDetails? activePurchase = _iapService.getActivePurchase();
        
        if (activePurchase != null) {
          _subscriptionIap = SubscriptionIap(
            id: 'restored_${activePurchase.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
            planId: _selectedPlan?.uuid ?? 'restored_plan',
            status: 'active',
            startDate: activePurchase.transactionDate != null 
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(activePurchase.transactionDate!))
                : DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 365)),
            platform: Platform.isIOS ? 'ios' : 'android',
            productId: activePurchase.productID,
          );
          
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  /// Get subscription status for UI display
  String getSubscriptionStatus() {
    if (_subscriptionIap == null) {
      return 'No active subscription';
    }
    
    if (_subscriptionIap!.isActive) {
      return 'Active until ${_subscriptionIap!.endDate.day}/${_subscriptionIap!.endDate.month}/${_subscriptionIap!.endDate.year}';
    } else {
      return 'Subscription expired';
    }
  }

  // Remove Paystack methods - IAP only implementation
  
  /// Generate payment link (REMOVED - IAP only)
  Future<void> generatePaymentLink({
    required String planUuid,
    required String userId,
  }) async {
    setError('Please use in-app purchase for subscriptions');
  }

  /// Handle payment callback (REMOVED - IAP only)
  Future<void> handlePaymentCallback(String callbackUrl) async {
    setError('Please use in-app purchase for subscriptions');
  }

  /// Fetch user subscription details (updated to work with SubscriptionIap)
  Future<void> fetchUserSubscriptionDetails(String userId, int role) async {
    setLoading();
    try {
      // Check local SubscriptionIap first
      if (_subscriptionIap != null) {
        setSuccess();
        return;
      }
      
      // Try to restore from IAP
      await checkActiveSubscription();
      
      // If still no subscription, check server (when backend is ready)
      // final response = await _apiService.get('/user/subscription/details/$userId');
      // if (response != null && response['data'] != null) {
      //   // Handle server response
      // }
      
      setSuccess();
    } catch (e) {
      debugPrint('Error fetching subscription details: $e');
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

  /// Clear subscription (updated for SubscriptionIap)
  void clearSubscription() {
    _subscriptionIap = null;
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
    _subscriptionIap = null;
    _subscription = null;
    _iapProducts = [];
    _currentPurchase = null;
    _hasCheckedExistingSubscription = false;
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