// lib/providers/her_purchase_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/iap_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';

class HerPurchaseProvider extends BaseProvider {
  final ApiService _apiService;
  final IAPService _iapService = IAPService();
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;

  // A class-level completer to manage the active purchase flow initiated by the UI.
  Completer<bool>? _purchaseCompleter;

  // Your new one-time product ID
  static const String herProductId = 'com.wawuafrica.her_one_time';

  // Base URL for the Node.js/Express backend
  static const String _tsBackendBaseUrl =
      'https://ts.wawuafrica.com/api';

  HerPurchaseProvider({required ApiService apiService})
    : _apiService = apiService,
      super() {
    // Start listening for purchases as soon as the provider is initialized.
    // This is crucial for catching transactions from previous sessions.
    _listenToPurchases();
  }

  /// A persistent, centralized listener for all HER-related purchases.
  void _listenToPurchases() {
    _purchaseSubscription = _iapService.purchaseStream.listen(
      (purchaseDetails) async {
        // Only handle purchases for this specific product
        if (purchaseDetails.productID != herProductId) return;

        // Retrieve the contentId from the purchase details.
        // It's passed via `applicationUserName` during the purchase request.
        final String? contentId = purchaseDetails.verificationData.localVerificationData;

        // If contentId is missing, we cannot process it with the backend.
        // This might happen for very old, stuck transactions.
        if (contentId == null || contentId.isEmpty) {
          debugPrint('Purchase event received without a contentId. Cannot process.');
          // Still, we should resolve any pending UI flow to avoid hangs.
          if (purchaseDetails.status == PurchaseStatus.error && _purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
             setError('Purchase failed and content ID was missing.');
             _purchaseCompleter!.complete(false);
          }
          return;
        }

        switch (purchaseDetails.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            // Handles both new purchases and leftover/restored transactions.
            await _sendPurchaseToBackend(purchaseDetails, contentId);
            setSuccess();
            // If a purchase flow is currently active, complete it with success.
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(true);
            }
            break;
          case PurchaseStatus.error:
            setError('Purchase failed. Please try again.');
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(false);
            }
            break;
          case PurchaseStatus.canceled:
            setError('Purchase was canceled.');
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(false);
            }
            break;
          case PurchaseStatus.pending:
            // The purchase is pending user action (e.g., parental approval).
            // Do not complete the future yet; the UI should wait.
            break;
        }
      },
      onError: (error) {
        setError('An error occurred in the purchase stream.');
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(false);
        }
      },
    );
  }

  /// Checks the backend to see if the user has already paid for this content.
  Future<bool> hasPurchasedContent(String contentId) async {
    setLoading();
    try {
      final response = await _apiService.get(
        '$_tsBackendBaseUrl/her-purchase/status/$contentId',
      );
      if (response != null && response['hasPurchased'] == true) {
        setSuccess();
        return true;
      }
      setSuccess();
      return false;
    } catch (e) {
      setError('Could not verify purchase status. Please try again.');
      return false;
    }
  }

  /// Initiates the IAP flow for the content. (REWRITTEN FOR ROBUSTNESS)
  /// Returns `true` if the purchase is successful, `false` otherwise.
  Future<bool> purchaseContent(String contentId) async {
    // If a purchase is already in progress, return its future instead of starting a new one.
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        return _purchaseCompleter!.future;
    }
    
    _purchaseCompleter = Completer<bool>();
    setLoading();

    try {
        // Ensure IAP is ready before initiating a purchase
        if (!_iapService.isInitialized) {
            await _iapService.initialize();
            await _iapService.loadProducts(
                additionalProductIds: {herProductId},
            );
        }

        // The IAP service will now initiate the purchase.
        // The result will be caught by our persistent `_listenToPurchases` method.
        // We pass the contentId here so it can be retrieved from the PurchaseDetails later.
        final purchaseStarted = await _iapService.purchaseProduct(
            herProductId,
            applicationUsername: contentId
        );
        
        if (!purchaseStarted) {
            setError('Could not start purchase process.');
            if (!_purchaseCompleter!.isCompleted) {
                _purchaseCompleter!.complete(false);
            }
        }

        // Add a timeout as a safeguard against the app store never responding.
        return await _purchaseCompleter!.future.timeout(
            const Duration(minutes: 5), 
            onTimeout: () {
                if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
                   setError('Purchase timed out. Please check your connection and try again.');
                }
                return false; // Return false on timeout
            }
        );
    } catch (e) {
        setError('An error occurred while starting the purchase: $e');
        if (!_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(false);
        }
        return false;
    }
  }

  /// Sends the successful purchase data to your backend.
  Future<void> _sendPurchaseToBackend(
    PurchaseDetails details,
    String contentId,
  ) async {
    final String? receipt = _iapService.getPurchaseReceipt(details);
    if (receipt == null) return;

    try {
      await _apiService.post(
        '$_tsBackendBaseUrl/her-purchase/notification',
        data: {
          'content_id': contentId,
          'purchase_id': details.purchaseID,
          'product_id': details.productID,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'transaction_date': details.transactionDate,
          'receipt_data': receipt,
        },
      );
    } catch (e) {
      // Log error but don't block user, they have a valid receipt.
      debugPrint('Failed to send purchase to backend: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}