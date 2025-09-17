// lib/providers/her_purchase_provider.dart

import 'dart:async';
import 'dart:convert'; // <-- ADDED for JSON encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- ADDED for local storage
import 'package:wawu_mobile/services/api_service.dart';
import 'package:wawu_mobile/services/iap_service.dart';
import 'package:wawu_mobile/providers/base_provider.dart';

class HerPurchaseProvider extends BaseProvider {
  final ApiService _apiService;
  final IAPService _iapService = IAPService();
  StreamSubscription<PurchaseDetails>? _purchaseSubscription;

  Completer<bool>? _purchaseCompleter;
  String? _pendingContentId;

  static const String herProductId = 'com.wawuafrica.her_one_time';
  static const String _tsBackendBaseUrl = 'https://ts.wawuafrica.com/api';
  
  // Key for storing failed sync attempts in local storage
  static const String _retryCacheKey = 'pending_her_purchases_sync'; // <-- ADDED

  HerPurchaseProvider({required ApiService apiService})
    : _apiService = apiService,
      super() {
    _listenToPurchases();
    // Attempt to sync any previously failed purchases on startup
    _retryFailedSyncs(); // <-- ADDED
  }

  /// NEW METHOD: Tries to send any cached failed purchases to the backend.
  Future<void> _retryFailedSyncs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingJsons = prefs.getStringList(_retryCacheKey) ?? [];
      if (pendingJsons.isEmpty) return;

      debugPrint('[HerPurchaseProvider] Found ${pendingJsons.length} pending purchases to retry.');

      // Create a list of items that successfully sync, to be removed from the cache.
      final List<String> successfullySyncedJsons = [];

      for (final jsonString in pendingJsons) {
        try {
          final purchaseData = jsonDecode(jsonString) as Map<String, dynamic>;
          
          await _apiService.post(
            '$_tsBackendBaseUrl/her-purchase/notification',
            data: purchaseData,
          );
          
          // If the post is successful, mark this one for removal from the cache
          successfullySyncedJsons.add(jsonString);
          debugPrint('[HerPurchaseProvider] Successfully synced pending purchase: ${purchaseData['purchase_id']}');
        } catch (e) {
          // If this specific one fails, we'll just try again next time.
          debugPrint('[HerPurchaseProvider] Failed to retry sync for a pending purchase: $e');
        }
      }

      // If any purchases were successfully synced, update the cache.
      if (successfullySyncedJsons.isNotEmpty) {
        final updatedPendingJsons = pendingJsons.where((p) => !successfullySyncedJsons.contains(p)).toList();
        await prefs.setStringList(_retryCacheKey, updatedPendingJsons);
        debugPrint('[HerPurchaseProvider] Updated pending sync cache. ${updatedPendingJsons.length} items remaining.');
      }
    } catch (e) {
        debugPrint('[HerPurchaseProvider] Error during retry process: $e');
    }
  }
  
  /// NEW METHOD: Saves purchase details to local storage for a future retry.
  Future<void> _savePurchaseForRetry(Map<String, dynamic> purchaseData) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> pendingJsons = prefs.getStringList(_retryCacheKey) ?? [];
        
        // Add the new failed purchase data and save it.
        pendingJsons.add(jsonEncode(purchaseData));
        await prefs.setStringList(_retryCacheKey, pendingJsons);
        debugPrint('[HerPurchaseProvider] Saved purchase to local cache for later retry.');
      } catch (e) {
        debugPrint('[HerPurchaseProvider] CRITICAL: Could not save purchase for retry: $e');
      }
  }

  void _listenToPurchases() {
    _purchaseSubscription = _iapService.purchaseStream.listen(
      (purchaseDetails) async {
        if (purchaseDetails.productID != herProductId) return;

        final String? contentId = _pendingContentId;

        if (contentId == null || contentId.isEmpty) {
          debugPrint('Purchase event received without a pending contentId. Cannot process.');
          if (purchaseDetails.status == PurchaseStatus.error && _purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
             setError('Purchase failed and content ID was missing.');
             _purchaseCompleter!.complete(false);
          }
          _pendingContentId = null;
          return;
        }

        switch (purchaseDetails.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            // This now returns true/false and saves for retry on failure
            await _handleSuccessfulPurchase(purchaseDetails, contentId); // <-- CHANGED
            
            _pendingContentId = null;
            setSuccess();
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(true);
            }
            break;
          case PurchaseStatus.error:
            // ... (rest of the code is the same)
            setError('Purchase failed. Please try again.');
            _pendingContentId = null;
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(false);
            }
            break;
          case PurchaseStatus.canceled:
            setError('Purchase was canceled.');
            _pendingContentId = null;
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(false);
            }
            break;
          case PurchaseStatus.pending:
            break;
        }
      },
      onError: (error) {
        setError('An error occurred in the purchase stream.');
        _pendingContentId = null;
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(false);
        }
      },
    );
  }

  /// MODIFIED METHOD: Now handles the backend sync and saves for retry on failure.
  Future<void> _handleSuccessfulPurchase(PurchaseDetails details, String contentId) async {
      final String? receipt = _iapService.getPurchaseReceipt(details);
      if (receipt == null) return;

      final purchaseData = {
        'content_id': contentId,
        'purchase_id': details.purchaseID,
        'product_id': details.productID,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'transaction_date': details.transactionDate,
        'receipt_data': receipt,
      };

      try {
        await _apiService.post(
          '$_tsBackendBaseUrl/her-purchase/notification',
          data: purchaseData,
        );
        debugPrint('[HerPurchaseProvider] Successfully sent purchase to backend.');
      } catch (e) {
        // If sending fails, log the error and save the purchase data for a later retry.
        debugPrint('[HerPurchaseProvider] Failed to send purchase to backend, saving for retry. Error: $e');
        await _savePurchaseForRetry(purchaseData);
      }
  }

  // ... The hasPurchasedContent and purchaseContent methods remain unchanged ...
  
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

  Future<bool> purchaseContent(String contentId) async {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        return _purchaseCompleter!.future;
    }
    
    _purchaseCompleter = Completer<bool>();
    _pendingContentId = contentId;
    setLoading();

    try {
        if (!_iapService.isInitialized) {
            await _iapService.initialize();
            await _iapService.loadProducts(
                additionalProductIds: {herProductId},
            );
        }
        
        final purchaseStarted = await _iapService.purchaseProduct(
            herProductId,
            applicationUsername: contentId
        );
        
        if (!purchaseStarted) {
            setError('Could not start purchase process.');
            _pendingContentId = null;
            if (!_purchaseCompleter!.isCompleted) {
                _purchaseCompleter!.complete(false);
            }
        }

        return await _purchaseCompleter!.future.timeout(
            const Duration(minutes: 5), 
            onTimeout: () {
                if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
                   setError('Purchase timed out. Please check your connection and try again.');
                   _pendingContentId = null;
                }
                return false;
            }
        );
    } catch (e) {
        setError('An error occurred while starting the purchase: $e');
        _pendingContentId = null;
        if (!_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(false);
        }
        return false;
    }
  }
  
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}