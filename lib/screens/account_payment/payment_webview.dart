import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' as html;

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.redirectUrl,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController? controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // For web platform, we'll handle differently
      _handleWebPlatform();
    } else {
      // For mobile platforms, use WebView
      _initializeMobileWebView();
    }
  }

  void _handleWebPlatform() {
    // For web, we can either:
    // 1. Open in a new tab/window
    // 2. Use an iframe (limited due to CORS)
    // 3. Show instructions to user

    // Option 1: Open in new window and listen for messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPaymentWindow();
    });
  }

  void _openPaymentWindow() {
    // Open payment URL in a new window
    html.window.open(
      widget.paymentUrl,
      'payment_window',
      'width=600,height=700,scrollbars=yes,resizable=yes',
    );

    // Listen for messages from the payment window
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.origin == Uri.parse(widget.paymentUrl).origin) {
        _handleWebPaymentCallback(messageEvent.data);
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  void _handleWebPaymentCallback(dynamic data) {
    // Handle payment callback from popup window
    if (data is Map) {
      final status = data['status'];
      final reference = data['reference'];

      if (status == 'success') {
        _onPaymentSuccess(reference ?? '');
      } else {
        _onPaymentFailed(data['message'] ?? 'Payment failed');
      }
    }
  }

  void _initializeMobileWebView() {
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

                if (_isPaymentCallback(url)) {
                  _handlePaymentCallback(url);
                }
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                });
                print('Page finished loading: $url');

                if (_isPaymentCallback(url)) {
                  _handlePaymentCallback(url);
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation to: ${request.url}');

                if (_isPaymentCallback(request.url)) {
                  _handlePaymentCallback(request.url);
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isPaymentCallback(String url) {
    return url.contains(widget.redirectUrl) ||
        url.contains('payment-callback') ||
        url.contains('paystack') &&
            (url.contains('status=') ||
                url.contains('trxref=') ||
                url.contains('reference=') ||
                url.contains('tx_ref=')) ||
        url.contains('flutterwave') && url.contains('status=') ||
        (url.contains('status=successful') ||
            url.contains('status=success') ||
            url.contains('status=cancelled') ||
            url.contains('status=failed'));
  }

  void _handlePaymentCallback(String url) {
    print('Payment callback URL detected: $url');

    Uri uri = Uri.parse(url);
    Map<String, String> params = uri.queryParameters;

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

    if (status == 'success' || status == 'successful') {
      _onPaymentSuccess(reference ?? '');
    } else if (status == 'cancelled' || status == 'canceled') {
      _onPaymentFailed('Payment was cancelled by user');
    } else if (status == 'failed' || status == 'error') {
      _onPaymentFailed('Payment failed');
    } else if (reference != null && reference.isNotEmpty) {
      _onPaymentSuccess(reference);
    } else {
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

    Navigator.of(context).pop({
      'status': 'success',
      'reference': reference,
      'message': 'Payment successful',
    });
  }

  void _onPaymentFailed(String reason) {
    print('Payment failed: $reason');

    Navigator.of(context).pop({'status': 'failed', 'message': reason});
  }

  void _onBackPressed() {
    Navigator.of(
      context,
    ).pop({'status': 'cancelled', 'message': 'Payment was cancelled by user'});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _onBackPressed();
        }
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
        body: kIsWeb ? _buildWebView() : _buildMobileView(),
      ),
    );
  }

  Widget _buildWebView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Payment Window Opened',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete your payment in the popup window.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              html.window.open(
                widget.paymentUrl,
                'payment_window',
                'width=600,height=700,scrollbars=yes,resizable=yes',
              );
            },
            child: const Text('Reopen Payment Window'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _onBackPressed,
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return Stack(
      children: [
        if (controller != null) WebViewWidget(controller: controller!),
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
    );
  }
}
