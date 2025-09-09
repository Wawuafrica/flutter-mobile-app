import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Assuming these are your actual model/service paths
import 'package:wawu_mobile/models/subscription_iap.dart';
import '../models/plan.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import '../services/iap_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';
import 'package:wawu_mobile/services/onboarding_state_service.dart';

class PlanProvider extends BaseProvider {
  final ApiService _apiService;
  final IAPService _iapService = IAPService();

  List<Plan> _plans = [];
  Plan? _selectedPlan;
  PaymentLink? _paymentLink;
  Subscription? _subscription;
  SubscriptionIap? _subscriptionIap;

  // IAP specific properties
  List<ProductDetails> _iapProducts = [];
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;
  PurchaseDetails? _currentPurchase;
  bool _isProcessingPurchase = false;
  bool _purchaseCompleted = false;
  Timer? _purchaseTimeoutTimer;
  bool _hasCheckedExistingSubscription = false;
  bool _isIapInitialized = false;

  // Local storage keys
  static const String _subscriptionKey = 'cached_subscription_iap';
  static const String _lastCheckKey = 'last_subscription_check';
  static const String _userIdKey = 'cached_user_id';

    // Base URL for the Node.js/Express backend
  static const String _tsBackendBaseUrl =
      'https://wawu-ts-backend-eight.vercel.app/api';


  // Cache duration (24 hours)
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // Backend integration settings
  bool _enableBackendVerification = true;
  bool _sendPurchaseToBackend = true;

  // Getters
  List<Plan> get plans => _plans;
  Plan? get selectedPlan => _selectedPlan;
  PaymentLink? get paymentLink => _paymentLink;
  SubscriptionIap? get subscriptionIap => _subscriptionIap;
  Subscription? get subscription => _subscription;
  List<ProductDetails> get iapProducts => _iapProducts;
  bool get isIapInitialized => _isIapInitialized;
  bool get isProcessingPurchase => _isProcessingPurchase;
  bool get hasActiveSubscription {
    // First check cached subscription
    if (_subscriptionIap != null && _subscriptionIap!.isActive) {
      debugPrint('[PlanProvider] Active subscription found in cache');
      return true;
    }

    // Then check IAP service
    final iapActive = _iapService.hasActiveSubscription();
    debugPrint('[PlanProvider] IAP active subscription: $iapActive');
    return iapActive;
  }

  PlanProvider({required ApiService apiService})
      : _apiService = apiService,
        super();

  /// Load cached subscription from local storage
  Future<bool> loadCachedSubscription([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have cached data
      final cachedSubscriptionJson = prefs.getString(_subscriptionKey);
      final lastCheckTimestamp = prefs.getInt(_lastCheckKey);
      final cachedUserId = prefs.getString(_userIdKey);

      if (cachedSubscriptionJson == null || lastCheckTimestamp == null) {
        debugPrint('[PlanProvider] No cached subscription data found');
        return false;
      }

      // Check if cache is still valid
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
      final now = DateTime.now();
      final cacheAge = now.difference(lastCheck);

      if (cacheAge > _cacheValidDuration) {
        debugPrint(
          '[PlanProvider] Cached subscription data expired (${cacheAge.inHours} hours old)',
        );
        await _clearCachedSubscription();
        return false;
      }

      // Check if the cached data is for the same user
      if (userId != null && cachedUserId != userId) {
        debugPrint(
          '[PlanProvider] Cached subscription for different user, clearing cache',
        );
        await _clearCachedSubscription();
        return false;
      }

      // Parse cached subscription
      final subscriptionMap =
          jsonDecode(cachedSubscriptionJson) as Map<String, dynamic>;
      _subscriptionIap = SubscriptionIap.fromJson(subscriptionMap);

      // Verify the subscription is still active
      if (_subscriptionIap!.isActive) {
        debugPrint(
          '[PlanProvider] Valid cached subscription loaded: ${_subscriptionIap!.id}',
        );
        debugPrint(
          '[PlanProvider] Subscription expires: ${_subscriptionIap!.endDate}',
        );
        return true;
      } else {
        debugPrint(
          '[PlanProvider] Cached subscription expired, clearing cache',
        );
        await _clearCachedSubscription();
        return false;
      }
    } catch (e) {
      debugPrint('[PlanProvider] Error loading cached subscription: $e');
      await _clearCachedSubscription();
      return false;
    }
  }

  /// Save subscription to local storage
  Future<void> _cacheSubscription(String? userId) async {
    try {
      if (_subscriptionIap == null) return;

      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = jsonEncode(_subscriptionIap!.toJson());

      await prefs.setString(_subscriptionKey, subscriptionJson);
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
      if (userId != null) {
        await prefs.setString(_userIdKey, userId);
      }

      debugPrint('[PlanProvider] Subscription cached successfully');
    } catch (e) {
      debugPrint('[PlanProvider] Error caching subscription: $e');
    }
  }

  /// Clear cached subscription
  Future<void> _clearCachedSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionKey);
      await prefs.remove(_lastCheckKey);
      await prefs.remove(_userIdKey);
      debugPrint('[PlanProvider] Cached subscription cleared');
    } catch (e) {
      debugPrint('[PlanProvider] Error clearing cached subscription: $e');
    }
  }

  /// Initialize IAP service
  Future<bool> initializeIAP() async {
    if (_isIapInitialized) return true;

    try {
      debugPrint('[PlanProvider] Initializing IAP Service...');

      final bool iapInitialized = await _iapService.initialize();
      if (!iapInitialized) {
        setError('In-app purchases not available on this device');
        return false;
      }

      final bool productsLoaded = await _iapService.loadProducts();
      if (!productsLoaded) {
        setError('Failed to load subscription plans');
        return false;
      }

      _iapProducts = _iapService.products;

      _purchaseSubscription = _iapService.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (error) {
          debugPrint('[PlanProvider] Purchase stream error: $error');
          _resetPurchaseState();
          setError('Purchase error: $error');
        },
      );

      await _checkForExistingSubscription();

      _isIapInitialized = true;
      debugPrint('[PlanProvider] IAP Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[PlanProvider] IAP initialization error: $e');
      setError('Failed to initialize payments: $e');
      _isIapInitialized = false;
      return false;
    }
  }

  /// Check for existing subscriptions on initialization
  Future<void> _checkForExistingSubscription() async {
    try {
      if (_hasCheckedExistingSubscription) return;

      debugPrint('[PlanProvider] Checking for existing subscriptions...');

      final List<PurchaseDetails> activeIAPPurchases =
          _iapService.activePurchases;

      if (activeIAPPurchases.isNotEmpty) {
        debugPrint(
          '[PlanProvider] Found existing active subscription(s) in IAPService',
        );

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
          await _createSubscriptionFromPurchase(
            activePurchase,
            isRestored: true,
          );
          debugPrint(
            '[PlanProvider] Restored existing subscription: ${_subscriptionIap!.id}',
          );
          
          // Sync existing subscription with the backend
          if (_sendPurchaseToBackend) {
            await _sendPurchaseDataToBackend(activePurchase);
          }
          
          // Cache the restored subscription
          await _cacheSubscription(null);
          notifyListeners();
        }
      }

      _hasCheckedExistingSubscription = true;
    } catch (e) {
      debugPrint('[PlanProvider] Error checking existing subscription: $e');
    }
  }

  /// Create SubscriptionIap from PurchaseDetails
  /// This method's only responsibility is now to create the local object.
  Future<void> _createSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails, {
    bool isRestored = false,
  }) async {
    try {
      Duration subscriptionDuration = const Duration(days: 365);

      if (_selectedPlan != null) {
        subscriptionDuration = _getPlanDuration(_selectedPlan!);
      }

      _subscriptionIap = SubscriptionIap(
        id: isRestored
            ? 'restored_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}'
            : 'iap_${purchaseDetails.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString()}',
        planId:
            _selectedPlan?.uuid ?? (isRestored ? 'restored_plan' : 'unknown'),
        status: 'active',
        startDate: purchaseDetails.transactionDate != null
            ? DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(purchaseDetails.transactionDate!) ??
                    DateTime.now().millisecondsSinceEpoch,
              )
            : DateTime.now(),
        endDate: purchaseDetails.transactionDate != null
            ? DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(purchaseDetails.transactionDate!) ??
                    DateTime.now().millisecondsSinceEpoch,
              ).add(subscriptionDuration)
            : DateTime.now().add(subscriptionDuration),
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchaseDetails.productID,
      );

      debugPrint(
        '[PlanProvider] Created SubscriptionIap: ${_subscriptionIap!.id}',
      );
      
      // -- REMOVED BACKEND CALL FROM HERE --

    } catch (e) {
      debugPrint(
        '[PlanProvider] Error creating subscription from purchase: $e',
      );
      throw e;
    }
  }

  /// Get plan duration from Plan object
  Duration _getPlanDuration(Plan plan) {
    return const Duration(days: 365);
  }

  /// Send purchase data to backend (optional)
  Future<void> _sendPurchaseDataToBackend(
    PurchaseDetails purchaseDetails,
  ) async {
    // This safety check prevents sending data if the flag is false
    if (!_sendPurchaseToBackend) return;

    try {
      debugPrint('[PlanProvider] Sending purchase data to backend...');

      final String? receipt = _iapService.getPurchaseReceipt(purchaseDetails);
      if (receipt == null) {
        debugPrint('[PlanProvider] No receipt available for backend');
        return;
      }

      final response = await _apiService.post(
        '$_tsBackendBaseUrl/subscribe/purchase-notification',
        data: {
          'purchase_id': purchaseDetails.purchaseID,
          'product_id': purchaseDetails.productID,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'transaction_date': purchaseDetails.transactionDate,
          'receipt_data': receipt,
          'plan_uuid': _selectedPlan?.uuid,
          'subscription_data': _subscriptionIap?.toJson(),
        },
      );

      if (response != null && (response['statusCode'] == 200 || response['statusCode'] == 201) ) {
        debugPrint('[PlanProvider] Purchase data sent to backend successfully');

        if (response['data'] != null &&
            response['data']['subscription'] != null) {
          final updatedSubscription = SubscriptionIap.fromJson(
            response['data']['subscription'] as Map<String, dynamic>,
          );
          _subscriptionIap = updatedSubscription;
          debugPrint(
            '[PlanProvider] Updated subscription from backend response',
          );
        }
      } else {
        debugPrint(
          '[PlanProvider] Failed to send purchase data to backend: ${response?['message']}',
        );
      }
    } catch (e) {
      debugPrint('[PlanProvider] Error sending purchase to backend: $e');
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
            .map(
              (planJson) => Plan.fromJson(planJson as Map<String, dynamic>),
            )
            .toList();
        setSuccess();
      } else {
        _plans = [];
        setError(
          response['message'] ??
              'Failed to fetch plans: Invalid response structure',
        );
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
      if (_isProcessingPurchase || _purchaseCompleted) {
        debugPrint('[PlanProvider] Purchase already in progress or completed');
        return;
      }

      if (_iapService.hasActiveSubscription()) {
        debugPrint('[PlanProvider] User already has active subscription');
        setError(
          'You already have an active subscription. Please check your subscription status.',
        );
        return;
      }

      debugPrint(
        '[PlanProvider] Starting purchase process for plan: $planUuid',
      );

      setLoading();
      _isProcessingPurchase = true;
      _purchaseCompleted = false;
      notifyListeners();

      _purchaseTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_isProcessingPurchase && !_purchaseCompleted) {
          debugPrint('[PlanProvider] Purchase timeout reached');
          _resetPurchaseState();
          setError('Purchase timeout. Please try again.');
        }
      });

      final String productId = _iapService.productId;
      debugPrint('[PlanProvider] Using product ID: $productId');

      final bool purchaseStarted = await _iapService.purchaseProduct(productId);

      if (!purchaseStarted) {
        debugPrint('[PlanProvider] Failed to start purchase');
        _resetPurchaseState();
        setError('Failed to start purchase process');
        return;
      }

      debugPrint(
        '[PlanProvider] Purchase initiated successfully, waiting for result...',
      );
    } catch (e) {
      debugPrint('[PlanProvider] Purchase error: $e');
      _resetPurchaseState();
      setError('Purchase failed: $e');
    }
  }

  /// Handle purchase updates from IAP
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint(
        '[PlanProvider] Purchase update received: ${purchaseDetails.status} for ${purchaseDetails.productID}',
      );

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
      debugPrint('[PlanProvider] Error processing purchase update: $e');
      _resetPurchaseState();
      setError('Error processing purchase: $e');
    }
  }

  /// Handle successful purchase -- FIXED
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      debugPrint('[PlanProvider] Handling successful purchase...');
      _currentPurchase = purchaseDetails;

      // First, create the local subscription object.
      await _createSubscriptionFromPurchase(purchaseDetails);

      debugPrint(
        '[PlanProvider] SubscriptionIap created successfully: ${_subscriptionIap!.id}',
      );

      // Second, if backend sync is enabled, send the data.
      await _sendPurchaseDataToBackend(purchaseDetails);
      
      // Third, cache the new subscription locally.
      await _cacheSubscription(null);

      _purchaseCompleted = true;
      _isProcessingPurchase = false;
      _purchaseTimeoutTimer?.cancel();

      setSuccess();

      await OnboardingStateService.saveStep('disclaimer');
      debugPrint('[PlanProvider] Onboarding step saved to disclaimer');
    } catch (e) {
      debugPrint('[PlanProvider] Failed to process successful purchase: $e');
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
      debugPrint(
        '[PlanProvider] Purchase error: ${error.code} - ${error.message}',
      );
    }

    _resetPurchaseState();
    setError(errorMessage);
  }

  /// Handle purchase canceled
  void _handlePurchaseCanceled() {
    debugPrint('[PlanProvider] Purchase was canceled by user');
    _resetPurchaseState();
    setError('Purchase was canceled');
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('[PlanProvider] Handling restored purchase...');

    await _createSubscriptionFromPurchase(purchaseDetails, isRestored: true);
    
    // Sync the restored purchase with the backend
    await _sendPurchaseDataToBackend(purchaseDetails);

    // Cache the restored subscription
    await _cacheSubscription(null);

    debugPrint('[PlanProvider] Restored subscription: ${_subscriptionIap!.id}');
    setSuccess();
  }

  /// Handle pending purchase
  void _handlePendingPurchase() {
    debugPrint(
      '[PlanProvider] Purchase is pending (e.g., waiting for parental approval)',
    );
  }

  /// Restore purchases (iOS)
  Future<void> restorePurchases() async {
    try {
      debugPrint('[PlanProvider] Restoring purchases...');
      setLoading();
      await _iapService.restorePurchases();
    } catch (e) {
      debugPrint('[PlanProvider] Failed to restore purchases: $e');
      setError('Failed to restore purchases: $e');
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

  /// Fetch user subscription details - NOW WITH FULL BACKEND LOGIC
  Future<void> fetchUserSubscriptionDetails(String userId, int role) async {
    try {
      debugPrint(
        '[PlanProvider] Starting subscription check for user: $userId',
      );

      // Step 1: Load cached subscription first (fastest)
      final bool hasCachedSubscription = await loadCachedSubscription(userId);
      if (hasCachedSubscription) {
        debugPrint(
          '[PlanProvider] Valid cached subscription found, skipping further checks',
        );
        setSuccess();
        return;
      }
      
      // Step 2: Check our backend if enabled. This makes your server the source of truth.
      if (_enableBackendVerification) {
        debugPrint('[PlanProvider] Backend verification is enabled, checking server...');
        try {
          final response = await _apiService.get('$_tsBackendBaseUrl/subscribe/status');
          if (response != null && response['hasActiveSubscription'] == true && response['subscription'] != null) {
            debugPrint('[PlanProvider] Active subscription found on backend.');
            // Create a SubscriptionIap object from the backend response
            _subscriptionIap = SubscriptionIap.fromJson(response['subscription'] as Map<String, dynamic>);
            await _cacheSubscription(userId);
            setSuccess();
            return; // Found subscription on backend, we are done.
          } else {
            debugPrint('[PlanProvider] No active subscription found on backend.');
          }
        } catch (e) {
          debugPrint('[PlanProvider] Error checking backend for subscription: $e. Will proceed with IAP check as a fallback.');
        }
      }

      // Step 3: Initialize IAP if not already done (fallback or primary check)
      if (!_isIapInitialized) {
        setLoading();
        final bool iapInitialized = await initializeIAP();
        if (!iapInitialized) {
          // Allow user to continue even if IAP fails
          debugPrint(
            '[PlanProvider] IAP initialization failed, but continuing',
          );
          setSuccess();
          return;
        }
      }

      // Step 4: Check IAP service directly
      final bool hasActive = await checkActiveSubscription();
      if (hasActive) {
        debugPrint('[PlanProvider] Active subscription found via IAP check');
        await _cacheSubscription(userId);
        setSuccess();
        return;
      }

      // If we reach here, no active subscription was found anywhere
      debugPrint(
        '[PlanProvider] No active subscription found after all checks',
      );
      setSuccess(); // Don't set error - just no subscription
    } catch (e) {
      debugPrint('[PlanProvider] Error in fetchUserSubscriptionDetails: $e');
      // Don't set error - allow user to continue
      setSuccess();
    }
  }

  /// Simplified checkActiveSubscription method
  Future<bool> checkActiveSubscription() async {
    try {
      debugPrint('[PlanProvider] Checking for active subscription...');

      // First check local subscription
      if (_subscriptionIap != null && _subscriptionIap!.isActive) {
        debugPrint('[PlanProvider] Found active local SubscriptionIap');
        return true;
      }

      // Then check IAP service
      final bool hasIAPActive = _iapService.hasActiveSubscription();
      debugPrint(
        '[PlanProvider] IAP service reports active subscription: $hasIAPActive',
      );

      if (hasIAPActive) {
        final PurchaseDetails? activePurchase = _iapService.getActivePurchase();

        if (activePurchase != null) {
          debugPrint(
            '[PlanProvider] Creating subscription from active purchase',
          );
          await _createSubscriptionFromPurchase(
            activePurchase,
            isRestored: true,
          );
          // When an active purchase is found on the device, we should sync it with the backend
          await _sendPurchaseDataToBackend(activePurchase);
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('[PlanProvider] Error checking subscription status: $e');
      return false;
    }
  }

  /// Enable/disable backend verification (for when backend is ready)
  void setBackendVerificationEnabled(bool enabled) {
    _enableBackendVerification = enabled;
    debugPrint(
      '[PlanProvider] Backend verification ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Enable/disable sending purchase data to backend
  void setSendPurchaseToBackend(bool enabled) {
    _sendPurchaseToBackend = enabled;
    debugPrint(
      '[PlanProvider] Send purchase to backend ${enabled ? 'enabled' : 'disabled'}',
    );
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
    _clearCachedSubscription();
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
    _isIapInitialized = false;
    _resetPurchaseState();
    _clearCachedSubscription();
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

