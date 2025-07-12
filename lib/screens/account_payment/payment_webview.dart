import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:wawu_mobile/providers/user_provider.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl; // Your expected redirect URL

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.redirectUrl,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasHandledCallback = false; // Prevent multiple callbacks
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();

    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                _logger.i('Page started loading: $url');
                setState(() {
                  isLoading = true;
                });

                // Check for Paystack callback URLs
                if (_isPaymentCallback(url) && !hasHandledCallback) {
                  _handlePaymentCallback(url);
                }
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                });
                _logger.i('Page finished loading: $url');

                // Double check for callback URLs on page finish
                if (_isPaymentCallback(url) && !hasHandledCallback) {
                  _handlePaymentCallback(url);
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                final String url = request.url;
                _logger.i('Navigating to: $url');

                // Check if the URL is a payment callback
                if (_isPaymentCallback(url)) {
                  if (!hasHandledCallback) {
                    _handlePaymentCallback(url);
                  }
                  // Still allow navigation to the callback URL
                  return NavigationDecision.navigate;
                }

                // Allow all other navigation to proceed normally
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isPaymentCallback(String url) {
    // Check for various Paystack callback patterns
    return url.contains(widget.redirectUrl) ||
        url.contains('payment-callback') ||
        url.contains('paystack') &&
            (url.contains('status=') ||
                url.contains('trxref=') ||
                url.contains('reference=') ||
                url.contains('tx_ref=')) ||
        url.contains('flutterwave') && url.contains('status=') ||
        // Check for success/failure indicators in URL
        (url.contains('status=successful') ||
            url.contains('status=success') ||
            url.contains('status=cancelled') ||
            url.contains('status=failed'));
  }

  void _handlePaymentCallback(String url) {
    // Prevent multiple handling of the same callback
    if (hasHandledCallback) return;
    hasHandledCallback = true;

    _logger.i('Payment callback URL detected: $url');

    // Parse the URL and extract payment info
    Uri uri = Uri.parse(url);
    Map<String, String> params = uri.queryParameters;

    // Extract various possible parameter names from different payment providers
    String? status = params['status'];
    String? reference = params['reference'] ?? params['transaction_id'];
    String? trxref = params['trxref'] ?? params['tx_ref'];

    _logger.i('Payment callback received:');
    _logger.i('Status: $status');
    _logger.i('Reference: $reference');
    _logger.d('All params: $params');

    // Add a small delay to ensure the webview has fully loaded the callback page
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Handle different payment statuses
      if (status == 'success' || status == 'successful') {
        _onPaymentSuccess(url, reference ?? '', trxref ?? '');
      } else if (status == 'cancelled' || status == 'canceled') {
        _onPaymentFailed('Payment was cancelled by user', url);
      } else if (status == 'failed' || status == 'error') {
        _onPaymentFailed('Payment failed', url);
      } else if (reference != null &&
          reference.isNotEmpty &&
          trxref != null &&
          trxref.isNotEmpty) {
        // If we have a reference but unclear status, assume success
        // You might want to verify this with your backend
        _onPaymentSuccess(url, reference, trxref);
      } else {
        // Check URL path for success indicators
        if (url.toLowerCase().contains('success')) {
          _onPaymentSuccess(url, reference ?? 'unknown', trxref ?? 'unknown');
        } else if (url.toLowerCase().contains('cancel') ||
            url.toLowerCase().contains('fail')) {
          _onPaymentFailed('Payment was not completed', url);
        }
      }
    });
  }

  void _onPaymentSuccess(String redirectUrl, String reference, String trxref) {
    if (!mounted) return;

    _logger.i('Payment successful with reference: $reference');

    // Log the user ID
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      if (user != null) {
        _logger.i('Payment by User ID: ${user.uuid}');
      } else {
        _logger.w('User is null, cannot log user ID.');
      }
    } catch (e) {
      _logger.e('Failed to get user from provider: $e');
    }

    // Pop the screen and return a success result with the full redirect URL
    Navigator.of(context).pop({
      'status': 'success',
      'redirectUrl': redirectUrl, // Pass the full URL back
      'message': 'Payment successful',
    });
  }

  void _onPaymentFailed(String message, String redirectUrl) {
    if (!mounted) return;

    _logger.e('Payment failed: $message');

    // Pop the screen and return a failure result with the URL
    Navigator.of(context).pop({
      'status': 'failed',
      'redirectUrl': redirectUrl, // Also pass URL on failure
      'message': message,
    });
  }

  void _onBackPressed() {
    // Handle back button press - treat as cancelled
    Navigator.of(
      context,
    ).pop({'status': 'cancelled', 'message': 'Payment was cancelled by user'});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Complete Payment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: wawuColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onBackPressed,
          ),
          actions: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: controller),
            if (isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading payment page...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
