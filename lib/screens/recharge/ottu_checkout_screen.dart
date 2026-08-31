import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pos_v2/constants/api_urls.dart';
import 'package:pos_v2/constants/app_constants.dart';
import 'package:pos_v2/core/services/api_services.dart';
import 'package:pos_v2/models/get_order_detail_model.dart' hide Icons;
import 'package:pos_v2/screens/payment_result_screen.dart';
import 'package:pos_v2/utils/ottu_checkout_url.dart';
import 'package:pos_v2/utils/ottu_webview_autofill.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum _WebCheckoutCloseReason { dismissed, successUrl, failureUrl }

class OttuCheckoutScreen extends StatefulWidget {
  final String sessionId;
  final double amount;
  final String orderNo;
  final String? checkoutPageUrl;
  final String? checkoutUrl;
  final String? customerEmail;
  final String? customerName;
  final String? customerPhone;

  const OttuCheckoutScreen({
    super.key,
    required this.sessionId,
    required this.amount,
    required this.orderNo,
    this.checkoutPageUrl,
    this.checkoutUrl,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
  });

  @override
  State<OttuCheckoutScreen> createState() => _OttuCheckoutScreenState();
}

class _OttuCheckoutScreenState extends State<OttuCheckoutScreen> {
  bool _isVerifying = false;
  bool _pollingCancelled = false;
  bool _webViewOpened = false;
  static const _pollInterval = Duration(seconds: 2);
  static const _maxPollAttempts = 45;

  String? get _checkoutUrl => resolveOttuCheckoutUrl(
        sessionId: widget.sessionId,
        checkoutPageUrl: widget.checkoutPageUrl,
        checkoutUrl: widget.checkoutUrl,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFullScreenWebView());
  }

  Future<void> _openFullScreenWebView() async {
    if (_webViewOpened || !mounted) return;
    _webViewOpened = true;

    final checkoutUrl = _checkoutUrl;
    if (checkoutUrl == null) return;

    final closeReason = await Navigator.of(context).push<_WebCheckoutCloseReason>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _OttuFullScreenWebCheckoutPage(
          checkoutUrl: checkoutUrl,
          customerEmail: widget.customerEmail,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
        ),
      ),
    );

    if (!mounted) return;

    if (closeReason == _WebCheckoutCloseReason.failureUrl) {
      _goToPaymentResult(isSuccess: false);
      return;
    }

    if (closeReason == _WebCheckoutCloseReason.successUrl) {
      await _verifyPaymentAfterWebViewClose();
      return;
    }

    // User closed WebView without a success redirect — no long confirming state.
    await _handleDismissedWithoutPayment();
  }

  Future<String?> _fetchOrderStatus() async {
    try {
      final headers = await AppConstants.getAuthHeaders();
      final data = await Get.find<ApiService>().post(
        ApiUrls.getOrderDetails,
        headers: headers,
        body: {'order_no': widget.orderNo},
      );
      final orderDetails = getOrderDetails.fromJson(data);
      return orderDetails.message?.status?.toLowerCase();
    } catch (e) {
      debugPrint('get-order-details error: $e');
      return null;
    }
  }

  Future<void> _handleDismissedWithoutPayment() async {
    final status = await _fetchOrderStatus();
    if (!mounted) return;

    if (_isSuccessStatus(status)) {
      _goToPaymentResult(isSuccess: true);
      return;
    }

    Get.back();
  }

  Future<void> _verifyPaymentAfterWebViewClose() async {
    if (!mounted || _isVerifying) return;
    setState(() => _isVerifying = true);
    _pollingCancelled = false;

    var attempt = 0;

    while (!_pollingCancelled && mounted && attempt < _maxPollAttempts) {
      if (attempt > 0) {
        await Future.delayed(_pollInterval);
      }
      if (!mounted || _pollingCancelled) return;

      final status = await _fetchOrderStatus();
      if (!mounted || _pollingCancelled) return;

      if (_isSuccessStatus(status)) {
        _goToPaymentResult(isSuccess: true);
        return;
      }

      if (_isFailureStatus(status)) {
        _goToPaymentResult(isSuccess: false);
        return;
      }

      attempt++;
    }

    if (!mounted) return;
    _goToPaymentResult(isSuccess: false);
  }

  bool _isSuccessStatus(String? status) {
    return status == 'completed' || status == 'success' || status == 'paid';
  }

  bool _isFailureStatus(String? status) {
    return status == 'failed' ||
        status == 'failure' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'expired';
  }

  void _goToPaymentResult({required bool isSuccess}) {
    if (!mounted) return;
    Get.off(
      () => PaymentResultScreen(
        isSuccess: isSuccess,
        amount: widget.amount,
        shopName: 'Wallet Recharge',
      ),
    );
  }

  @override
  void dispose() {
    _pollingCancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConstants.paymentApiKey.isEmpty) {
      return _buildMessageScreen(
        'Payment configuration is not ready. Please go back and try again.',
      );
    }

    if (_checkoutUrl == null) {
      return _buildMessageScreen(
        'Unable to open the payment page. Please try again later.',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isVerifying ? _buildConfirmingOverlay() : const SizedBox.shrink(),
    );
  }

  Widget _buildMessageScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmingOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Lottie.asset(
                'assets/lottie/update.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirming payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we verify your payment…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OttuFullScreenWebCheckoutPage extends StatefulWidget {
  final String checkoutUrl;
  final String? customerEmail;
  final String? customerName;
  final String? customerPhone;

  const _OttuFullScreenWebCheckoutPage({
    required this.checkoutUrl,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
  });

  @override
  State<_OttuFullScreenWebCheckoutPage> createState() =>
      _OttuFullScreenWebCheckoutPageState();
}

class _OttuFullScreenWebCheckoutPageState
    extends State<_OttuFullScreenWebCheckoutPage> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _isLoading = false);
            await _autofillCustomerFields();
            _handleUrl(url);
          },
          onUrlChange: (change) => _handleUrl(change.url),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  Future<void> _autofillCustomerFields() async {
    final script = buildOttuWebViewAutofillScript(
      email: widget.customerEmail,
      name: widget.customerName,
      phone: widget.customerPhone,
    );
    if (script.isEmpty) return;

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      await _controller.runJavaScript(script);
      // Ottu checkout may render fields after first paint.
      await Future.delayed(const Duration(milliseconds: 800));
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('Ottu webview autofill error: $e');
    }
  }

  void _close(_WebCheckoutCloseReason reason) {
    if (!mounted) return;
    Navigator.of(context).pop(reason);
  }

  void _handleUrl(String? url) {
    if (url == null || url.isEmpty) return;
    final lower = url.toLowerCase();
    if (_looksLikePaymentSuccess(lower)) {
      _close(_WebCheckoutCloseReason.successUrl);
    } else if (_looksLikePaymentFailure(lower)) {
      _close(_WebCheckoutCloseReason.failureUrl);
    }
  }

  bool _looksLikePaymentSuccess(String url) {
    return url.contains('success') ||
        url.contains('completed') ||
        url.contains('payment-success');
  }

  bool _looksLikePaymentFailure(String url) {
    return url.contains('cancel') ||
        url.contains('failure') ||
        url.contains('failed') ||
        url.contains('payment-fail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _close(_WebCheckoutCloseReason.dismissed),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
