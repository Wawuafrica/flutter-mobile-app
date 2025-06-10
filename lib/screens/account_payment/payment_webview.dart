import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl; // Your expected redirect URL

  const PaymentWebView({
    Key? key,
    required this.paymentUrl,
    required this.redirectUrl,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('Page started loading: $url');
                setState(() {
                  isLoading = true;
                });

                // Check for Paystack callback URLs
                if (_isPaymentCallback(url)) {
                  _handlePaymentCallback(url);
                }
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                });
                print('Page finished loading: $url');

                // Double check for callback URLs on page finish
                if (_isPaymentCallback(url)) {
                  _handlePaymentCallback(url);
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation to: ${request.url}');

                // Intercept callback URLs
                if (_isPaymentCallback(request.url)) {
                  _handlePaymentCallback(request.url);
                  return NavigationDecision.prevent; // Stop navigation
                }

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
    print('Payment callback URL detected: $url');

    // Parse the URL and extract payment info
    Uri uri = Uri.parse(url);
    Map<String, String> params = uri.queryParameters;

    // Extract various possible parameter names from different payment providers
    String? status = params['status'];
    String? reference =
        params['reference'] ??
        params['trxref'] ??
        params['tx_ref'] ??
        params['transaction_id'];

    print('Payment callback received:');
    print('Status: $status');
    print('Reference: $reference');
    print('All params: $params');

    // Handle different payment statuses
    if (status == 'success' || status == 'successful') {
      _onPaymentSuccess(reference ?? '');
    } else if (status == 'cancelled' || status == 'canceled') {
      _onPaymentFailed('Payment was cancelled by user');
    } else if (status == 'failed' || status == 'error') {
      _onPaymentFailed('Payment failed');
    } else if (reference != null && reference.isNotEmpty) {
      // If we have a reference but unclear status, assume success
      // You might want to verify this with your backend
      _onPaymentSuccess(reference);
    } else {
      // Check URL path for success indicators
      if (url.toLowerCase().contains('success')) {
        _onPaymentSuccess(reference ?? 'unknown');
      } else if (url.toLowerCase().contains('cancel') ||
          url.toLowerCase().contains('fail')) {
        _onPaymentFailed('Payment was not completed');
      }
    }
  }

  void _onPaymentSuccess(String reference) {
    print('Payment successful with reference: $reference');

    // Close webview and return success
    Navigator.of(context).pop({
      'status': 'success',
      'reference': reference,
      'message': 'Payment successful',
    });
  }

  void _onPaymentFailed(String reason) {
    print('Payment failed: $reason');

    // Close webview and return failure
    Navigator.of(context).pop({'status': 'failed', 'message': reason});
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
          title: const Text('Complete Payment'),
          backgroundColor: Colors.green,
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
                color: Colors.white.withOpacity(0.8),
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
