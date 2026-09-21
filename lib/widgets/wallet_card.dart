import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/screens/recharge/wallert_recharge.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class WalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback onRecharge;
  final bool? showRecharge;

  /// Optional extra widgets to show (like Transfer/Reverse buttons)
  final Widget? extraContent;

  const WalletCard({
    super.key,
    required this.balance,
    required this.onRecharge,
    this.showRecharge,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.lightOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'current_wallet_balance'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBalanceText(
                    balance: balance,
                    color: Colors.white,
                    currency: 'SAR',
                    duration: const Duration(seconds: 2),
                  ),
                ],
              ),
              const Spacer(),
              if (showRecharge != false) _buildRechargeButton(),
            ],
          ),

          // Add optional extra widgets here
          if (extraContent != null) ...[
            const SizedBox(height: 12),
            extraContent!,
          ],
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    return Obx(() {
      final isChild =
          AppConstants.currentUser.value?.userData?.parentId != null;
      if (isChild) return const SizedBox.shrink();

      return ElevatedButton(
        onPressed: () {
          Get.to(WalletRechargeScreen());
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xffa27b2e),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          '+ ${'recharge_wallet'.tr}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }
}

// class WalletCard extends StatelessWidget {
//   final double balance;
//   final VoidCallback onRecharge;
//   final bool? showRecharge;

//   const WalletCard({
//     super.key,
//     required this.balance,
//     required this.onRecharge,
//     this.showRecharge,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [AppColors.primaryOrange, AppColors.lightOrange],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'current_wallet_balance'.tr,
//                 style: const TextStyle(color: Colors.white, fontSize: 16),
//               ),
//               const SizedBox(height: 10),
//               AnimatedBalanceText(
//                 balance: balance,
//                 color: Colors.white,
//                 currency: 'SAR',
//                 duration: const Duration(seconds: 2),
//               ),
//               // RichText(
//               //   text: TextSpan(
//               //     children: [
//               //       WidgetSpan(
//               //           alignment: PlaceholderAlignment.top,
//               //           child: Transform.translate(
//               //             offset: const Offset(0, -8),
//               //             child: const Text(
//               //               'SAR ',
//               //               style: TextStyle(
//               //                 color: Colors.white,
//               //                 fontSize: 10,
//               //                 fontWeight: FontWeight.bold,
//               //               ),
//               //             ),
//               //           ),
//               //         ),
//               //       TextSpan(
//               //         text: '${balance.toStringAsFixed(2)}',
//               //         style: const TextStyle(
//               //           color: Colors.white,
//               //           fontSize: 30,
//               //           fontWeight: FontWeight.bold,
//               //         ),
//               //       )
//               //     ]
//               //   ),
//               // ),
//             ],
//           ),
//           const Spacer(),
//           if (showRecharge != false)
//           ElevatedButton(
//               onPressed: onRecharge,
//               style: ElevatedButton.styleFrom(
//                 elevation: 0,
//                 backgroundColor: const Color(0xffa27b2e),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 minimumSize: const Size(0, 40), // smaller height
//                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 '+ ${'recharge_wallet'.tr}',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.white,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),

//             // ElevatedButton(
//             //   onPressed: onRecharge,
//             //   style: ElevatedButton.styleFrom(
//             //     elevation: 0,
//             //     backgroundColor: const Color(0xffa27b2e),
//             //     shape: RoundedRectangleBorder(
//             //       borderRadius: BorderRadius.circular(30),
//             //     ),
//             //   ),
//             //   child: Text(
//             //     '+ ${'recharge_wallet'.tr}',
//             //     style: const TextStyle(fontSize: 14, color: Colors.white),
//             //   ),
//             // ),
//         ],
//       ),
//     );
//   }
// }

class AnimatedBalanceText extends StatelessWidget {
  final double balance;
  final String currency;
  final Duration duration;
  final Color color;

  const AnimatedBalanceText({
    super.key,
    required this.balance,
    this.currency = 'SAR',
    this.duration = const Duration(milliseconds: 1200),
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: balance),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final formatted = value.toStringAsFixed(2);
        final parts = formatted.split('.');
        final integerPart = parts[0];
        final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

        return RichText(
          text: TextSpan(
            children: [
              // Currency (top-aligned)
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text(
                    currency,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),

              // Animated Integer Part
              TextSpan(
                text: _formatNumber(integerPart),
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Animated Decimal Part
              TextSpan(
                text: decimalPart,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(String number) {
    return number.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
