import 'package:flutter/material.dart';

/// Legacy sample screen. Wallet recharge uses [OttuCheckoutScreen] with WebView.
class RechargeNow extends StatelessWidget {
  const RechargeNow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Use wallet recharge to start payment.'),
    );
  }
}
