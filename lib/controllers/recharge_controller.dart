import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos_v2/constants/api_urls.dart';

import '../constants/app_constants.dart';
import '../core/services/api_services.dart';
import '../models/app_config_model.dart';
import '../models/intiate_payment_model.dart';
import '../screens/recharge/ottu_checkout_screen.dart';
import '../utils/snakbar_helper.dart';

class WalletRechargeController extends GetxController {
  TextEditingController amountController = TextEditingController();
  final api = Get.find<ApiService>();
  RxBool isLoading = false.obs;
  RxBool isConfigLoading = false.obs;
  RxDouble minRecharge = 0.0.obs;

  static const List<String> allQuickAmounts = ["50", "100", "300", "500"];

  List<String> get filteredQuickAmounts {
    final min = minRecharge.value;
    return allQuickAmounts.where((amount) {
      final value = double.tryParse(amount) ?? 0;
      return min <= 0 || value >= min;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    minRecharge.value = AppConstants.minRecharge;
    loadConfigs();
  }

  /// Fresh fetch from configs API whenever recharge screen needs min amount.
  Future<void> loadConfigs() async {
    try {
      isConfigLoading.value = true;
      final headers = await AppConstants.getAuthHeaders();
      final data = await api.get(ApiUrls.configsUrl, headers: headers);
      print("✅ Config API Response (recharge): $data");

      final configModel = AppConfig.fromJson(data);
      if (configModel.success == true) {
        AppConstants.saveConfig(configModel);
        minRecharge.value = AppConstants.minRecharge;
        print("✅ Recharge min amount: ${minRecharge.value}");
      }
    } catch (e) {
      print("❌ Config API Error (recharge): $e");
      minRecharge.value = AppConstants.minRecharge;
    } finally {
      isConfigLoading.value = false;
    }
  }

  Future<void> startRecharge() async {
    if (amountController.text.isEmpty) {
      SnackbarHelper.showError('enter_amount'.tr);
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      SnackbarHelper.showError('invalid_amount'.tr);
      return;
    }

    final min = minRecharge.value > 0
        ? minRecharge.value
        : AppConstants.minRecharge;
    if (min > 0 && amount < min) {
      SnackbarHelper.showError(
        'min_recharge_error'.trParams({
          'amount': min.toStringAsFixed(
            min.truncateToDouble() == min ? 0 : 2,
          ),
        }),
      );
      return;
    }

    isLoading.value = true;

    try {
      final lang = Get.locale?.languageCode ?? "en";

      final headers = await AppConstants.getAuthHeaders();
      final user = AppConstants.currentUser.value!.userData;

      final body = {
        "amount": amount,
        "email": user?.email ?? "",
        "first_name": user?.name ?? "User",
        "phone": user?.phone ?? "",
        "pg_codes": ["mada-visa-master", "apple-pay"],
        "lang": lang,
      };

      // ✅ Call Your Backend API (Same as FCM Token Example)
      final data = await api.post(
        ApiUrls.paymentInitiateUrl,
        headers: headers,
        body: body,
      );

      print("✅ Payment Initiate Response: $data");

      // ✅ Parse Model Response
      final paymentModel = InitiatePaymentModel.fromJson(data);

      if (paymentModel.success == true) {
        final sessionId = paymentModel.message?.sessionId;
        final orderNo = paymentModel.message?.orderNo;

        if (AppConstants.paymentApiKey.isEmpty) {
          SnackbarHelper.showError('try_again'.tr);
          return;
        }

        print("✅ Session Generated: $sessionId");

        // ✅ Open Ottu Checkout Screen
        Get.to(
          () => OttuCheckoutScreen(
            sessionId: sessionId!,
            amount: paymentModel.message!.amount!,
            orderNo: orderNo ?? '',
            checkoutPageUrl: paymentModel.message?.checkoutPageUrl,
            checkoutUrl: paymentModel.message?.checkoutUrl,
            customerEmail: user?.email,
            customerName: user?.name,
            customerPhone: user?.phone,
          ),
        );
      } else {
        SnackbarHelper.showError('try_again'.tr);
      }
    } on ApiException catch (e) {
      print("❌ ApiException: $e");
      SnackbarHelper.showApiError(e);
    } catch (e) {
      print("❌ Exception: $e");
      SnackbarHelper.showApiError(e);
    } finally {
      isLoading.value = false;
    }
  }
}
