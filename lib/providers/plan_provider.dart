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

  // Backend integration settings
  bool _enableBackendVerification = false; // Set to true when backend is ready
  bool _sendPurchaseToBackend = true; // Send purchase data to backend (optional)

  // Getters
  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  PaymentLink? get paymentLink => _paymentLink;
  SubscriptionIap? get subscriptionIap => _subscriptionIap;
  Subscription? get subscription => _subscription;
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

      // Get all active purchases directly from IAPService
      final List<PurchaseDetails> activeIAPPurchases = _iapService.activePurchases;

      if (activeIAPPurchases.isNotEmpty) {
        debugPrint('Found existing active subscription(s) in IAPService');

        // Find active purchase for our product ID
        PurchaseDetails? activePurchase;
        for (final purchase in activeIAPPurchases) {
          if (purchase.productID == _iapService.productId &&
              (purchase.status == PurchaseStatus.purchased ||
               purchase.status == PurchaseStatus.restored)) {
            activePurchase = purchase;
            break;
          }
        }

        if (activePurchase != null) {
          // Create SubscriptionIap from existing purchase
          await _createSubscriptionFromPurchase(activePurchase, isRestored: true);
          debugPrint('Restored existing subscription: ${_subscriptionIap!.id}');
          notifyListeners();
        }
      }

      _hasCheckedExistingSubscription = true;
    } catch (e) {
      debugPrint('Error checking existing subscription: $e');
    }
  }

  /// Create SubscriptionIap from PurchaseDetails
  Future<void> _createSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails, {
    bool isRestored = false,
  }) async {
    try {
      // Get plan duration (default to 1 year if not available)
      Duration subscriptionDuration = const Duration(days: 365);
      
      // Try to get duration from selected plan
      if (_selectedPlan != null) {
        // Assuming your Plan model has duration info
        // You might need to adjust this based on your Plan model structure
        subscriptionDuration = _getPlanDuration(_selectedPlan!);
      }

      // Create SubscriptionIap with client-side data
      _subscriptionIap = SubscriptionIap(
        id: isRestored 
            ? 'restored_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}'
            : 'iap_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
        planId: _selectedPlan?.uuid ?? (isRestored ? 'restored_plan' : 'unknown'),
        status: 'active',
        startDate: purchaseDetails.transactionDate != null
            ? DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(purchaseDetails.transactionDate!) ?? DateTime.now().millisecondsSinceEpoch
              )
            : DateTime.now(),
        endDate: purchaseDetails.transactionDate != null
            ? DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(purchaseDetails.transactionDate!) ?? DateTime.now().millisecondsSinceEpoch
              ).add(subscriptionDuration)
            : DateTime.now().add(subscriptionDuration),
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchaseDetails.productID,
      );

      debugPrint('Created SubscriptionIap: ${_subscriptionIap!.id}');
      
      // Optionally send to backend if enabled
      if (_sendPurchaseToBackend && !isRestored) {
        await _sendPurchaseDataToBackend(purchaseDetails);
      }

    } catch (e) {
      debugPrint('Error creating subscription from purchase: $e');
      throw e;
    }
  }

  /// Get plan duration from Plan object
  Duration _getPlanDuration(Plan plan) {
    // Adjust this based on your Plan model structure
    // This is just an example - you'll need to modify based on your actual Plan model
    
    // Example: if your plan has a duration field
    // if (plan.duration != null) {
    //   return Duration(days: plan.duration!);
    // }
    
    // Example: if your plan has a billing cycle
    // switch (plan.billingCycle?.toLowerCase()) {
    //   case 'monthly':
    //     return const Duration(days: 30);
    //   case 'yearly':
    //     return const Duration(days: 365);
    //   default:
    //     return const Duration(days: 365);
    // }
    
    // Default to yearly
    return const Duration(days: 365);
  }

  /// Send purchase data to backend (optional)
  Future<void> _sendPurchaseDataToBackend(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Sending purchase data to backend...');
      
      final String? receipt = _iapService.getPurchaseReceipt(purchaseDetails);
      if (receipt == null) {
        debugPrint('No receipt available for backend');
        return;
      }

      final response = await _apiService.post('/subscribe/purchase-notification', data: {
        'purchase_id': purchaseDetails.purchaseID,
        'product_id': purchaseDetails.productID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': purchaseDetails.transactionDate,
        'receipt_data': receipt,
        'plan_uuid': _selectedPlan?.uuid,
        'subscription_data': _subscriptionIap?.toJson(),
      });

      if (response != null && response['statusCode'] == 200) {
        debugPrint('Purchase data sent to backend successfully');
        
        // If backend returns updated subscription data, use it
        if (response['data'] != null && response['data']['subscription'] != null) {
          final updatedSubscription = SubscriptionIap.fromJson(
            response['data']['subscription'] as Map<String, dynamic>
          );
          _subscriptionIap = updatedSubscription;
          debugPrint('Updated subscription from backend response');
        }
      } else {
        debugPrint('Failed to send purchase data to backend: ${response?['message']}');
        // Don't throw error - client-side subscription is still valid
      }
    } catch (e) {
      debugPrint('Error sending purchase to backend: $e');
      // Don't throw error - client-side subscription is still valid
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

  /// Fetch all plans
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
      if (_iapService.hasActiveSubscription()) {
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

      // Create SubscriptionIap from purchase (client-side)
      await _createSubscriptionFromPurchase(purchaseDetails);

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
    await _createSubscriptionFromPurchase(purchaseDetails, isRestored: true);

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

  /// Check if user has active subscription
  Future<bool> checkActiveSubscription() async {
    try {
      debugPrint('Checking for active subscription...');

      // First check local SubscriptionIap
      if (_subscriptionIap != null && _subscriptionIap!.isActive) {
        debugPrint('Found active local SubscriptionIap');
        return true;
      }

      // Check with IAP service for active purchases
      final bool hasIAPActive = _iapService.hasActiveSubscription();

      if (hasIAPActive) {
        // Get the active purchase from IAPService
        final PurchaseDetails? activePurchase = _iapService.getActivePurchase();

        if (activePurchase != null) {
          await _createSubscriptionFromPurchase(activePurchase, isRestored: true);
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

  /// Fetch user subscription details
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

      // If backend verification is enabled and still no subscription, check server
      if (_enableBackendVerification && _subscriptionIap == null) {
        try {
          final response = await _apiService.get('/user/subscription/details/$userId');
          if (response != null && response['data'] != null) {
            final subscriptionData = response['data']['subscription'];
            if (subscriptionData != null) {
              _subscriptionIap = SubscriptionIap.fromJson(subscriptionData);
              debugPrint('Retrieved subscription from backend');
            }
          }
        } catch (e) {
          debugPrint('Failed to fetch from backend: $e');
          // Don't throw error - client-side check already completed
        }
      }

      setSuccess();
    } catch (e) {
      debugPrint('Error fetching subscription details: $e');
      setError(e.toString());
    }
  }

  /// Enable/disable backend verification (for when backend is ready)
  void setBackendVerificationEnabled(bool enabled) {
    _enableBackendVerification = enabled;
    debugPrint('Backend verification ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable sending purchase data to backend
  void setSendPurchaseToBackend(bool enabled) {
    _sendPurchaseToBackend = enabled;
    debugPrint('Send purchase to backend ${enabled ? 'enabled' : 'disabled'}');
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