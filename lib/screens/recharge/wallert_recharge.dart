import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_constants.dart';
import '../../widgets/app_screen_wrapper.dart';
import '../../controllers/recharge_controller.dart';
import '../../widgets/wallet_card.dart';

class WalletRechargeScreen extends StatelessWidget {
  WalletRechargeScreen({super.key}) {
    // Always refresh configs when opening this screen
    // (Get.put may return an existing controller whose onInit already ran)
    controller.loadConfigs();
  }

  final controller = Get.put(WalletRechargeController());

  @override
  Widget build(BuildContext context) {
    return AppScreenWrapper(
      title: "recharge_wallet".tr,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ✅ User Info Card
            WalletCard(
              balance: AppConstants.safeParseBalance(
                AppConstants.currentBalance.toString(),
              ),
              showRecharge: false,
              onRecharge: () {
                Get.to(WalletRechargeScreen());
              },
            ),

            const SizedBox(height: 30),

            // ✅ Section Title
            _buildSectionTitle("wallet_recharge".tr),

            const SizedBox(height: 6),

            Text(
              "enter_amount_note".tr,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            // ✅ Amount Input Field
            TextFormField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                "enter_amount".tr,
                Icons.account_balance_wallet,
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Quick Amount Buttons (filtered by min_recharge from configs)
            Obx(() {
              if (controller.isConfigLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final amounts = controller.filteredQuickAmounts;
              if (amounts.isEmpty) return const SizedBox.shrink();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: amounts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemBuilder: (context, index) {
                  return _quickAmountButton(amounts[index]);
                },
              );
            }),

            const SizedBox(height: 40),

            // ✅ Next Button
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                return controller.isLoading.isTrue
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          controller.startRecharge();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "next".tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
              }),
            ),

            const SizedBox(height: 20),

            // ✅ Footer Note
            Center(
              child: Text(
                "secure_payments_note".tr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountButton(String amount) {
    return GestureDetector(
      onTap: () {
        controller.amountController.text = amount;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "$amount SAR",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(221, 80, 80, 80),
      ),
    );
  }

  // ✅ Input Decoration
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
