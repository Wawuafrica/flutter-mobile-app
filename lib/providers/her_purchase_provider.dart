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

  // Your new one-time product ID
  static const String herProductId = 'com.wawuafrica.her_one_time';

  // Base URL for the Node.js/Express backend
  static const String _tsBackendBaseUrl =
      'https://wawu-ts-backend.onrender.com/api';

  HerPurchaseProvider({required ApiService apiService})
    : _apiService = apiService,
      super();

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

  /// Initiates the IAP flow for the content.
  /// Returns `true` if the purchase is successful, `false` otherwise.
  Future<bool> purchaseContent(String contentId) async {
    final completer = Completer<bool>();
    setLoading();

    // Ensure IAP is ready
    if (!_iapService.isInitialized) {
      await _iapService.initialize();
      await _iapService.loadProducts(
        additionalProductIds: {IAPService.herOneTimeProductId},
      ); // Load all products
    }

    _purchaseSubscription = _iapService.purchaseStream.listen(
      (purchaseDetails) async {
        if (purchaseDetails.productID != herProductId) return;

        switch (purchaseDetails.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _sendPurchaseToBackend(purchaseDetails, contentId);
            setSuccess();
            if (!completer.isCompleted) completer.complete(true);
            break;
          case PurchaseStatus.error:
            setError('Purchase failed. Please try again.');
            if (!completer.isCompleted) completer.complete(false);
            break;
          case PurchaseStatus.canceled:
            setError('Purchase was canceled.');
            if (!completer.isCompleted) completer.complete(false);
            break;
          case PurchaseStatus.pending:
            // Waiting for user action
            break;
        }
      },
      onError: (error) {
        setError('An error occurred during purchase.');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    // Start the purchase
    final purchaseStarted = await _iapService.purchaseProduct(herProductId);
    if (!purchaseStarted) {
      setError('Could not start purchase process.');
      if (!completer.isCompleted) completer.complete(false);
    }

    // Clean up listener after completion
    completer.future.whenComplete(() => _purchaseSubscription?.cancel());

    return completer.future;
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
